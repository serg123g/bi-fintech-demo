import { money } from "../_shared/money.ts";

/**
 * Reglas de personalización del home (funciones puras, sin I/O).
 * Se testean con `deno test` y son la fuente de verdad del contrato SDUI v1.
 */

export type Segment = "joven" | "pyme" | "premium";

export interface CustomerSnapshot {
  full_name: string;
  segment: Segment;
  total_balance: number;
  currency: string;
  accounts_count: number;
  movements_30d: number;
  transfers_30d: number;
  spent_30d: number;
  top_spend_category: string | null;
}

export interface FeatureFlag {
  key: string;
  enabled: boolean;
  segment: Segment | null;
}

export type SduiAction =
  | { type: "route"; value: string }
  | { type: "url"; value: string }
  | { type: "microapp"; value: string };

export interface SduiSection {
  id: string;
  type: string;
  props: Record<string, unknown>;
}

export interface SduiLayout {
  version: 1;
  layout_id: string;
  generated_at: string;
  ttl_seconds: number;
  sections: SduiSection[];
}

export const LOW_BALANCE_THRESHOLD = 100;
export const FREQUENT_TRANSFERS_THRESHOLD = 5;
export const TIME_ZONE = "America/Guayaquil";

const CATEGORY_LABELS: Record<string, string> = {
  comida: "comida",
  transporte: "transporte",
  servicios: "servicios",
  compras: "compras",
  salud: "salud",
  entretenimiento: "entretenimiento",
  otros: "otros gastos",
};

/** Flag activo para el segmento (segment null = todos). */
export function isEnabled(
  flags: FeatureFlag[],
  key: string,
  segment: Segment,
): boolean {
  const f = flags.find((x) => x.key === key);
  return !!f && f.enabled && (f.segment === null || f.segment === segment);
}

export function localHour(now: Date, timeZone = TIME_ZONE): number {
  const h = new Intl.DateTimeFormat("en-US", {
    hour: "numeric",
    hourCycle: "h23",
    timeZone,
  }).format(now);
  return Number(h) % 24;
}

export function greetingFor(hour: number): string {
  if (hour >= 5 && hour < 12) return "Buenos días";
  if (hour >= 12 && hour < 19) return "Buenas tardes";
  return "Buenas noches";
}

function firstName(fullName: string): string {
  return fullName.trim().split(/\s+/)[0] || "";
}

export function buildHomeLayout(
  s: CustomerSnapshot,
  flags: FeatureFlag[],
  now: Date,
): SduiLayout {
  const seg = s.segment;
  const on = (key: string) => isEnabled(flags, key, seg);
  const sections: SduiSection[] = [];
  const name = firstName(s.full_name);

  // 1. Saludo según la hora local del cliente.
  sections.push({
    id: "greeting",
    type: "greeting",
    props: {
      text: `${greetingFor(localHour(now))}${name ? `, ${name}` : ""}`,
      subtitle: subtitleFor(seg),
    },
  });

  // 2. Resumen de cuentas (la app lo llena con su propio repositorio).
  sections.push({ id: "accounts", type: "accounts_summary", props: {} });

  // 3. Saldo bajo -> fondo de emergencia (prioridad alta).
  if (s.total_balance < LOW_BALANCE_THRESHOLD && on("emergency_fund")) {
    sections.push({
      id: "emergency_fund",
      type: "banner",
      props: {
        style: "warning",
        icon: "savings",
        title: "Arma tu fondo de emergencia",
        subtitle: `Tu saldo es ${money(s.total_balance, s.currency)}. ` +
          "Ahorrar un poco cada semana te protege de imprevistos.",
        action: { type: "route", value: "/accounts" } satisfies SduiAction,
      },
    });
  }

  // 4. Accesos rápidos personalizados.
  const items: Array<Record<string, unknown>> = [];
  const frequentTransfers = s.transfers_30d >= FREQUENT_TRANSFERS_THRESHOLD;
  if (frequentTransfers && on("quick_transfer")) {
    items.push({
      icon: "send",
      label: "Transferir",
      action: { type: "route", value: "/accounts" },
    });
  }
  if (seg === "pyme" && on("collections")) {
    items.push({
      icon: "request_quote",
      label: "Cobros",
      action: { type: "microapp", value: "collections" },
    });
  }
  items.push({
    icon: "account_balance_wallet",
    label: "Mis cuentas",
    action: { type: "route", value: "/accounts" },
  });
  if (on("marketplace")) {
    items.push({
      icon: "storefront",
      label: "Beneficios",
      action: { type: "microapp", value: "marketplace" },
    });
  }
  sections.push({
    id: "quick_actions",
    type: "quick_actions",
    props: { items },
  });

  // 5. Oferta premium.
  if (seg === "premium" && on("investment_offer")) {
    sections.push({
      id: "investment_offer",
      type: "offer_card",
      props: {
        icon: "trending_up",
        title: "Inversión a plazo fijo",
        body:
          "Tu saldo puede trabajar por ti: tasa preferencial para clientes " +
          "Premium desde $1,000 a 180 días.",
        cta: "Ver beneficios",
        action: { type: "microapp", value: "marketplace" },
      },
    });
  }

  // 6. Insight de gasto (si hubo gastos en el mes).
  if (s.spent_30d > 0 && s.top_spend_category) {
    const label = CATEGORY_LABELS[s.top_spend_category] ??
      s.top_spend_category;
    sections.push({
      id: "spend_insight",
      type: "insight",
      props: {
        icon: "insights",
        text: `En los últimos 30 días gastaste ${
          money(s.spent_30d, s.currency)
        }; tu mayor gasto fue en ${label}.`,
      },
    });
  }

  // 7. Marketplace para quien no lo tiene como acceso rápido destacado.
  if (on("marketplace") && seg === "joven") {
    sections.push({
      id: "marketplace_banner",
      type: "banner",
      props: {
        style: "info",
        icon: "storefront",
        title: "Beneficios para ti",
        subtitle: "Descuentos en comida, transporte y entretenimiento.",
        action: { type: "microapp", value: "marketplace" },
      },
    });
  }

  return {
    version: 1,
    layout_id: `home-${seg}-v1`,
    generated_at: now.toISOString(),
    ttl_seconds: 300,
    sections,
  };
}

function subtitleFor(seg: Segment): string {
  switch (seg) {
    case "pyme":
      return "Tu negocio, al día";
    case "premium":
      return "Tu patrimonio, a tu manera";
    default:
      return "Tu dinero, bajo control";
  }
}
