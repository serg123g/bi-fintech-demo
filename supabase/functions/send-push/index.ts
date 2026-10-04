// Edge Function `send-push` — la invoca el trigger `movements_notify_push`
// (pg_net) con cada movimiento nuevo y envía la notificación por FCM HTTP v1.
//
// Seguridad:
// * No es pública: exige el header `x-webhook-secret` (secreto compartido con
//   Vault). Se despliega con --no-verify-jwt porque el llamador es la BD.
// * Usa la service role SOLO aquí (servidor) para leer los tokens del dueño
//   de la cuenta; la service account de Firebase vive en los secrets.

import { createClient } from "npm:@supabase/supabase-js@2";
import { log } from "../_shared/log.ts";
import {
  type AccountInfo,
  buildFcmMessage,
  getAccessToken,
  isStaleTokenError,
  type MovementRecord,
  sendFcm,
  type ServiceAccount,
} from "./fcm.ts";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/** Comparación en tiempo constante para el secreto del webhook. */
function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

Deno.serve(async (req: Request) => {
  const started = performance.now();
  const correlationId = req.headers.get("x-correlation-id") ??
    crypto.randomUUID();

  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const expected = Deno.env.get("PUSH_WEBHOOK_SECRET");
  const provided = req.headers.get("x-webhook-secret") ?? "";
  if (!expected || !safeEqual(provided, expected)) {
    log("warn", "send_push_unauthorized", { correlationId });
    return json({ error: "unauthorized" }, 401);
  }

  let payload: { type?: string; table?: string; record?: MovementRecord };
  try {
    payload = await req.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }
  const movement = payload.record;
  if (
    payload.type !== "INSERT" || payload.table !== "movements" || !movement?.id
  ) {
    return json({ skipped: "not_a_movement_insert" });
  }

  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SECRET_KEY");
  const saRaw = Deno.env.get("FCM_SERVICE_ACCOUNT");
  if (!url || !serviceKey || !saRaw) {
    log("error", "send_push_misconfigured", { correlationId });
    return json({ error: "misconfigured" }, 500);
  }

  try {
    const sa = JSON.parse(saRaw) as ServiceAccount;
    const admin = createClient(url, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: account, error: accountError } = await admin
      .from("accounts")
      .select("user_id, number_masked, currency")
      .eq("id", movement.account_id)
      .maybeSingle();
    if (accountError) throw accountError;
    if (!account) return json({ skipped: "account_not_found" });

    const { data: tokens, error: tokensError } = await admin
      .from("device_tokens")
      .select("token")
      .eq("user_id", (account as AccountInfo).user_id);
    if (tokensError) throw tokensError;
    if (!tokens?.length) {
      log("info", "send_push_no_devices", {
        correlationId,
        movementId: movement.id,
      });
      return json({ sent: 0 });
    }

    const accessToken = await getAccessToken(sa);
    const results = await Promise.all(
      tokens.map(async ({ token }: { token: string }) => {
        const res = await sendFcm(
          sa,
          accessToken,
          buildFcmMessage(token, movement, account as AccountInfo),
        );
        const stale = !res.ok && isStaleTokenError(res.status, res.body);
        if (stale) {
          await admin.from("device_tokens").delete().eq("token", token);
        }
        return { ok: res.ok, status: res.status, stale };
      }),
    );

    const sent = results.filter((r) => r.ok).length;
    log("info", "send_push_done", {
      correlationId,
      movementId: movement.id,
      devices: results.length,
      sent,
      staleRemoved: results.filter((r) => r.stale).length,
      statuses: results.map((r) => r.status),
      ms: Math.round(performance.now() - started),
    });
    return json({ sent, devices: results.length });
  } catch (e) {
    log("error", "send_push_failed", {
      correlationId,
      movementId: movement.id,
      error: e instanceof Error ? e.message : String(e),
    });
    return json({ error: "internal_error" }, 500);
  }
});
