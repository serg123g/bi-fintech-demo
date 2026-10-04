// Edge Function `home-layout` — BFF de Server-Driven UI para el home.
//
// GET /functions/v1/home-layout  (Authorization: Bearer <access token>)
//
// Lee las señales del cliente con SU token (RLS aplica: nunca ve datos de
// otros), lee los feature flags y devuelve el layout SDUI v1.

import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import { log } from "../_shared/log.ts";
import {
  buildHomeLayout,
  type CustomerSnapshot,
  type FeatureFlag,
} from "./rules.ts";

function json(
  body: unknown,
  status: number,
  extra: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json", ...extra },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const correlationId = req.headers.get("x-correlation-id") ??
    crypto.randomUUID();
  const started = performance.now();
  const trace = { "x-correlation-id": correlationId };

  if (req.method !== "GET") {
    return json({ error: "method_not_allowed" }, 405, trace);
  }

  const authorization = req.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return json({ error: "unauthorized" }, 401, trace);
  }

  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_ANON_KEY") ??
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
  if (!url || !key) {
    log("error", "missing_env", { correlationId });
    return json({ error: "misconfigured" }, 500, trace);
  }

  // Cliente con el JWT del usuario: todas las consultas pasan por RLS.
  const supabase = createClient(url, key, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  try {
    const token = authorization.slice("Bearer ".length);
    const { data: userData, error: userError } = await supabase.auth.getUser(
      token,
    );
    if (userError || !userData.user) {
      return json({ error: "unauthorized" }, 401, trace);
    }

    const [snapshotRes, flagsRes] = await Promise.all([
      supabase.rpc("customer_snapshot").maybeSingle(),
      supabase.from("feature_flags").select("key, enabled, segment"),
    ]);

    if (snapshotRes.error) throw snapshotRes.error;
    if (flagsRes.error) throw flagsRes.error;
    if (!snapshotRes.data) {
      return json({ error: "profile_not_found" }, 404, trace);
    }

    const snapshot = snapshotRes.data as CustomerSnapshot;
    // numeric llega como string desde PostgREST en algunos casos.
    snapshot.total_balance = Number(snapshot.total_balance);
    snapshot.spent_30d = Number(snapshot.spent_30d);

    const layout = buildHomeLayout(
      snapshot,
      (flagsRes.data ?? []) as FeatureFlag[],
      new Date(),
    );

    log("info", "home_layout_ok", {
      correlationId,
      userId: userData.user.id,
      layoutId: layout.layout_id,
      sections: layout.sections.map((s) => s.type),
      ms: Math.round(performance.now() - started),
    });

    return json(layout, 200, {
      ...trace,
      "Cache-Control": `private, max-age=${layout.ttl_seconds}`,
    });
  } catch (e) {
    log("error", "home_layout_failed", {
      correlationId,
      error: e instanceof Error ? e.message : String(e),
      ms: Math.round(performance.now() - started),
    });
    return json({ error: "internal_error", correlationId }, 500, trace);
  }
});
