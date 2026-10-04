/**
 * Cliente mínimo de FCM HTTP v1 sin dependencias: OAuth2 con service account
 * (JWT RS256 firmado con WebCrypto) + construcción del mensaje.
 * Las funciones puras se testean en fcm_test.ts.
 */

import { money } from "../_shared/money.ts";

export interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri?: string;
}

export interface MovementRecord {
  id: string;
  account_id: string;
  amount: number | string;
  description: string;
  category?: string;
}

export interface AccountInfo {
  user_id: string;
  number_masked: string;
  currency: string;
}

const SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const DEFAULT_TOKEN_URI = "https://oauth2.googleapis.com/token";

// ---------------------------------------------------------------------------
// Mensaje
// ---------------------------------------------------------------------------

/** Ruta interna de la app para el deep link (go_router). */
export function movementRoute(m: MovementRecord): string {
  return `/accounts/${m.account_id}/movements/${m.id}`;
}

export function buildFcmMessage(
  token: string,
  movement: MovementRecord,
  account: AccountInfo,
) {
  const amount = Number(movement.amount);
  const credit = amount > 0;
  const title = credit
    ? `Recibiste ${money(amount, account.currency)}`
    : `Movimiento de ${money(amount, account.currency)}`;
  const body = `${movement.description} · cuenta ${account.number_masked}`;

  return {
    message: {
      token,
      notification: { title, body },
      // FCM exige que todos los valores de `data` sean strings.
      data: {
        type: "movement",
        movement_id: movement.id,
        account_id: movement.account_id,
        route: movementRoute(movement),
      },
      android: {
        priority: "HIGH",
        notification: { tag: `movement-${movement.id}` },
      },
      apns: { payload: { aps: { sound: "default" } } },
    },
  };
}

/** Token que FCM ya no acepta: se borra de device_tokens. */
export function isStaleTokenError(status: number, body: unknown): boolean {
  if (status === 404) return true;
  const err = (body as { error?: { status?: string; details?: unknown[] } })
    ?.error;
  if (!err) return false;
  if (err.status === "NOT_FOUND") return true;
  const details = Array.isArray(err.details) ? err.details : [];
  return details.some((d) =>
    (d as { errorCode?: string })?.errorCode === "UNREGISTERED"
  ) ||
    (status === 400 && err.status === "INVALID_ARGUMENT" &&
      JSON.stringify(err).includes("registration token"));
}

// ---------------------------------------------------------------------------
// OAuth2 (service account -> access token)
// ---------------------------------------------------------------------------

function base64url(input: ArrayBuffer | Uint8Array | string): string {
  const bytes = typeof input === "string"
    ? new TextEncoder().encode(input)
    : input instanceof Uint8Array
    ? input
    : new Uint8Array(input);
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

export function pemToDer(pem: string): Uint8Array<ArrayBuffer> {
  const b64 = pem
    .replace(/-----BEGIN [^-]+-----/, "")
    .replace(/-----END [^-]+-----/, "")
    .replace(/\\n/g, "")
    .replace(/\s+/g, "");
  const bin = atob(b64);
  return Uint8Array.from(bin, (c) => c.charCodeAt(0));
}

export async function createSignedJwt(
  sa: ServiceAccount,
  nowSeconds: number,
): Promise<string> {
  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: sa.client_email,
    scope: SCOPE,
    aud: sa.token_uri ?? DEFAULT_TOKEN_URI,
    iat: nowSeconds,
    exp: nowSeconds + 3600,
  };
  const unsigned = `${base64url(JSON.stringify(header))}.${
    base64url(JSON.stringify(claims))
  }`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  return `${unsigned}.${base64url(signature)}`;
}

let cached: { token: string; expiresAt: number } | null = null;

/** Access token de Google, cacheado en memoria del isolate hasta su expiración. */
export async function getAccessToken(
  sa: ServiceAccount,
  fetchFn: typeof fetch = fetch,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cached && cached.expiresAt - 60 > now) return cached.token;

  const assertion = await createSignedJwt(sa, now);
  const res = await fetchFn(sa.token_uri ?? DEFAULT_TOKEN_URI, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!res.ok) {
    throw new Error(`oauth_token_failed: ${res.status} ${await res.text()}`);
  }
  const json = await res.json() as { access_token: string; expires_in: number };
  cached = { token: json.access_token, expiresAt: now + json.expires_in };
  return json.access_token;
}

export async function sendFcm(
  sa: ServiceAccount,
  accessToken: string,
  payload: unknown,
  fetchFn: typeof fetch = fetch,
): Promise<{ ok: boolean; status: number; body: unknown }> {
  const res = await fetchFn(
    `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    },
  );
  const body = await res.json().catch(() => null);
  return { ok: res.ok, status: res.status, body };
}
