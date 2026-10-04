import { deepStrictEqual, ok } from "node:assert/strict";
import {
  buildFcmMessage,
  createSignedJwt,
  isStaleTokenError,
  movementRoute,
  pemToDer,
  type ServiceAccount,
} from "./fcm.ts";

const assertEquals = <T>(a: T, b: T) => deepStrictEqual(a, b);

const movement = {
  id: "m-1",
  account_id: "a-1",
  amount: "-12.50",
  description: "Café",
  category: "comida",
};
const account = {
  user_id: "u-1",
  number_masked: "****4821",
  currency: "USD",
};

Deno.test("mensaje de débito: título, cuerpo y deep link", () => {
  const { message } = buildFcmMessage("tok", movement, account);
  assertEquals(message.token, "tok");
  assertEquals(message.notification.title, "Movimiento de -$12.50");
  assertEquals(message.notification.body, "Café · cuenta ****4821");
  assertEquals(message.data.route, "/accounts/a-1/movements/m-1");
  assertEquals(message.data.movement_id, "m-1");
  ok(Object.values(message.data).every((v) => typeof v === "string"));
});

Deno.test("mensaje de crédito", () => {
  const { message } = buildFcmMessage(
    "tok",
    { ...movement, amount: 1250 },
    account,
  );
  assertEquals(message.notification.title, "Recibiste $1,250.00");
});

Deno.test("ruta del movimiento", () => {
  assertEquals(movementRoute(movement), "/accounts/a-1/movements/m-1");
});

Deno.test("detección de tokens inválidos", () => {
  ok(isStaleTokenError(404, null));
  ok(
    isStaleTokenError(404, {
      error: { status: "NOT_FOUND", details: [{ errorCode: "UNREGISTERED" }] },
    }),
  );
  ok(
    isStaleTokenError(400, {
      error: {
        status: "INVALID_ARGUMENT",
        message: "The registration token is not a valid FCM registration token",
      },
    }),
  );
  ok(!isStaleTokenError(500, { error: { status: "INTERNAL" } }));
  ok(!isStaleTokenError(400, { error: { status: "INVALID_ARGUMENT" } }));
});

Deno.test("JWT RS256 de la service account verifica con la llave pública", async () => {
  const pair = await crypto.subtle.generateKey(
    {
      name: "RSASSA-PKCS1-v1_5",
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: "SHA-256",
    },
    true,
    ["sign", "verify"],
  );
  const pkcs8 = new Uint8Array(
    await crypto.subtle.exportKey("pkcs8", pair.privateKey),
  );
  const b64 = btoa(String.fromCharCode(...pkcs8));
  // Formato real del JSON de Google: saltos de línea escapados.
  const pem = `-----BEGIN PRIVATE KEY-----\\n${
    b64.match(/.{1,64}/g)!.join("\\n")
  }\\n-----END PRIVATE KEY-----\\n`;
  assertEquals(pemToDer(pem).length, pkcs8.length);

  const sa: ServiceAccount = {
    project_id: "bi-fintech-demo",
    client_email: "push@bi-fintech-demo.iam.gserviceaccount.com",
    private_key: pem,
  };
  const jwt = await createSignedJwt(sa, 1_800_000_000);
  const [h, c, s] = jwt.split(".");
  const decode = (x: string) =>
    JSON.parse(atob(x.replace(/-/g, "+").replace(/_/g, "/")));
  assertEquals(decode(h), { alg: "RS256", typ: "JWT" });
  const claims = decode(c);
  assertEquals(claims.iss, sa.client_email);
  assertEquals(claims.exp - claims.iat, 3600);
  ok(claims.scope.includes("firebase.messaging"));

  const sig = Uint8Array.from(
    atob(s.replace(/-/g, "+").replace(/_/g, "/")),
    (ch) => ch.charCodeAt(0),
  );
  const valid = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    pair.publicKey,
    sig,
    new TextEncoder().encode(`${h}.${c}`),
  );
  ok(valid, "firma inválida");
});
