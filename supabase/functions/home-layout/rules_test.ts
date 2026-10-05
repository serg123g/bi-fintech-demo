import { deepStrictEqual, ok } from "node:assert/strict";

const assert = (v: unknown, msg?: string) => ok(v, msg);
const assertFalse = (v: unknown, msg?: string) => ok(!v, msg);
const assertEquals = <T>(a: T, b: T) => deepStrictEqual(a, b);
import {
  buildHomeLayout,
  type CustomerSnapshot,
  type FeatureFlag,
  greetingFor,
  isEnabled,
  localHour,
} from "./rules.ts";

const flags: FeatureFlag[] = [
  { key: "marketplace", enabled: true, segment: null },
  { key: "quick_transfer", enabled: true, segment: null },
  { key: "collections", enabled: true, segment: "pyme" },
  { key: "investment_offer", enabled: true, segment: "premium" },
  { key: "emergency_fund", enabled: true, segment: null },
  { key: "ai_assistant", enabled: false, segment: null },
];

const base: CustomerSnapshot = {
  full_name: "Ana Torres",
  segment: "joven",
  total_balance: 60.81,
  currency: "USD",
  accounts_count: 1,
  movements_30d: 7,
  transfers_30d: 1,
  spent_30d: 189.19,
  top_spend_category: "comida",
};

// 15:00 en Quito (UTC-5) = 20:00 UTC
const afternoon = new Date("2026-10-04T20:00:00Z");

const types = (s: CustomerSnapshot, f = flags, now = afternoon) =>
  buildHomeLayout(s, f, now).sections.map((x) => x.id);

Deno.test("saludo según hora local de Ecuador", () => {
  assertEquals(localHour(new Date("2026-10-04T13:00:00Z")), 8);
  assertEquals(greetingFor(8), "Buenos días");
  assertEquals(greetingFor(15), "Buenas tardes");
  assertEquals(greetingFor(22), "Buenas noches");
  assertEquals(greetingFor(3), "Buenas noches");
  const layout = buildHomeLayout(base, flags, afternoon);
  assertEquals(layout.sections[0].props.text, "Buenas tardes, Ana");
});

Deno.test("joven con saldo bajo: banner de fondo de emergencia", () => {
  const ids = types(base);
  assert(ids.includes("emergency_fund"));
  assertFalse(ids.includes("investment_offer"));
  assert(ids.includes("marketplace_banner"));
});

Deno.test("pyme con muchas transferencias: transferir + cobros", () => {
  const layout = buildHomeLayout(
    {
      ...base,
      full_name: "Carlos Méndez",
      segment: "pyme",
      total_balance: 8412.4,
      transfers_30d: 11,
    },
    flags,
    afternoon,
  );
  const qa = layout.sections.find((s) => s.type === "quick_actions")!;
  const labels = (qa.props.items as Array<{ label: string }>).map((i) =>
    i.label
  );
  assertEquals(labels.slice(0, 2), ["Transferir", "Cobros"]);
  assertFalse(layout.sections.some((s) => s.id === "emergency_fund"));
});

Deno.test("premium: oferta de inversión, sin banner de saldo bajo", () => {
  const ids = types({
    ...base,
    full_name: "Lucía Andrade",
    segment: "premium",
    total_balance: 18769.35,
  });
  assert(ids.includes("investment_offer"));
  assertFalse(ids.includes("emergency_fund"));
});

Deno.test("los 3 segmentos producen homes distintos", () => {
  const j = JSON.stringify(types(base));
  const p = JSON.stringify(
    types({ ...base, segment: "pyme", total_balance: 8000, transfers_30d: 11 }),
  );
  const pr = JSON.stringify(
    types({ ...base, segment: "premium", total_balance: 18000 }),
  );
  assert(j !== p && p !== pr && j !== pr);
});

Deno.test("flags: apagar un flag quita la sección (sin release)", () => {
  const off = flags.map((f) =>
    f.key === "emergency_fund" ? { ...f, enabled: false } : f
  );
  assertFalse(types(base, off).includes("emergency_fund"));
});

Deno.test("flag segmentado no aplica a otros segmentos", () => {
  assert(isEnabled(flags, "collections", "pyme"));
  assertFalse(isEnabled(flags, "collections", "joven"));
  assertFalse(isEnabled(flags, "no_existe", "joven"));
});

Deno.test("contrato: version 1, ids únicos y acciones tipadas", () => {
  const layout = buildHomeLayout(base, flags, afternoon);
  assertEquals(layout.version, 1);
  const ids = layout.sections.map((s) => s.id);
  assertEquals(new Set(ids).size, ids.length);
  for (const s of layout.sections) {
    const action = s.props.action as { type: string } | undefined;
    if (action) assert(["route", "url", "microapp"].includes(action.type));
  }
});

Deno.test("flag ai_assistant: acceso rápido al asistente sin release", () => {
  const qa = (f: FeatureFlag[]) =>
    (buildHomeLayout(base, f, afternoon).sections.find((s) =>
      s.type === "quick_actions"
    )!.props.items as Array<{ label: string }>).map((i) => i.label);
  assertFalse(qa(flags).includes("Asistente"));
  const on = flags.map((f) =>
    f.key === "ai_assistant" ? { ...f, enabled: true } : f
  );
  assert(qa(on).includes("Asistente"));
});
