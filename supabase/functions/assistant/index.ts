// Edge Function `assistant` — asistente financiero con LLM.
//
// POST /functions/v1/assistant  { "question": "¿Cuánto gasté en comida?" }
// Authorization: Bearer <access token del usuario>
//
// 1. Valida el token y el flag `ai_assistant` (apagable sin release).
// 2. Lee `spending_summary()` con el JWT del usuario (RLS): solo agregados.
// 3. Pregunta al LLM con salida estructurada; si no hay API key, se agota el
//    tiempo o la salida no cumple el contrato, responde con reglas
//    determinísticas (el asistente nunca queda "caído").
// 4. Devuelve `{ answer, source, layout }`, donde `layout` es SDUI v1 que la
//    app renderiza con su registry (experiencia generada dinámicamente).

import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import { log } from "../_shared/log.ts";
import { askLlm } from "./llm.ts";
import {
  type AssistantReply,
  buildLayout,
  normalizeQuestion,
  rulesAnswer,
  sanitizeCards,
  type SpendingSummary,
} from "./logic.ts";

function json(
  body: unknown,
  status: number,
  extra: Record<string, string> = {},
) {
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
  const trace = { "x-correlation-id": correlationId };
  const started = performance.now();

  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405, trace);
  }
  const authorization = req.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return json({ error: "unauthorized" }, 401, trace);
  }

  let question: string | null = null;
  try {
    question = normalizeQuestion((await req.json())?.question);
  } catch {
    question = null;
  }
  if (!question) return json({ error: "invalid_question" }, 400, trace);

  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_ANON_KEY") ??
    Deno.env.get("PUBLISHABLE_KEY");
  if (!url || !key) return json({ error: "misconfigured" }, 500, trace);

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

    const { data: flag } = await supabase
      .from("feature_flags")
      .select("enabled")
      .eq("key", "ai_assistant")
      .maybeSingle();
    if (!flag?.enabled) {
      return json({ error: "assistant_disabled" }, 403, trace);
    }

    const { data, error } = await supabase.rpc("spending_summary", {
      p_days: 30,
    });
    if (error) throw error;
    const summary = data as SpendingSummary;

    let reply: AssistantReply;
    let source: "llm" | "rules" = "rules";
    let tokens: Record<string, number | undefined> = {};
    const apiKey = Deno.env.get("LLM_API_KEY");
    if (apiKey) {
      try {
        const r = await askLlm(
          {
            apiKey,
            model: Deno.env.get("LLM_MODEL") ?? "claude-haiku-4-5",
            timeoutMs: 6000,
          },
          question,
          summary,
        );
        reply = r.reply;
        source = "llm";
        tokens = { inputTokens: r.inputTokens, outputTokens: r.outputTokens };
      } catch (e) {
        log("warn", "assistant_llm_fallback", {
          correlationId,
          reason: e instanceof Error ? e.message : String(e),
        });
        reply = rulesAnswer(question, summary);
      }
    } else {
      reply = rulesAnswer(question, summary);
    }

    const sections = sanitizeCards(reply.cards);
    log("info", "assistant_ok", {
      correlationId,
      userId: userData.user.id,
      source,
      cards: sections.map((s) => s.type),
      ms: Math.round(performance.now() - started),
      ...tokens,
      // Nunca se loguea la pregunta ni la respuesta (pueden tener datos personales).
    });

    return json(
      {
        answer: reply.answer,
        source,
        layout: buildLayout(sections, new Date()),
      },
      200,
      trace,
    );
  } catch (e) {
    log("error", "assistant_failed", {
      correlationId,
      error: e instanceof Error ? e.message : String(e),
    });
    return json({ error: "internal_error", correlationId }, 500, trace);
  }
});
