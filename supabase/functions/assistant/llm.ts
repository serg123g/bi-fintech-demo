/**
 * Cliente mínimo de LLM (Anthropic Messages API) con salida estructurada vía
 * tool use forzado. Proveedor detrás de una función: cambiarlo no toca la
 * lógica del asistente.
 */

import {
  type AssistantReply,
  buildUserMessage,
  parseLlmReply,
  RESPOND_TOOL,
  type SpendingSummary,
  SYSTEM_PROMPT,
} from "./logic.ts";

export interface LlmConfig {
  apiKey: string;
  model: string;
  timeoutMs: number;
}

export interface LlmResult {
  reply: AssistantReply;
  inputTokens?: number;
  outputTokens?: number;
}

export async function askLlm(
  cfg: LlmConfig,
  question: string,
  summary: SpendingSummary,
  fetchFn: typeof fetch = fetch,
): Promise<LlmResult> {
  const res = await fetchFn("https://api.anthropic.com/v1/messages", {
    method: "POST",
    signal: AbortSignal.timeout(cfg.timeoutMs),
    headers: {
      "x-api-key": cfg.apiKey,
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: cfg.model,
      max_tokens: 700,
      temperature: 0.3,
      system: SYSTEM_PROMPT,
      tools: [RESPOND_TOOL],
      tool_choice: { type: "tool", name: RESPOND_TOOL.name },
      messages: [{
        role: "user",
        content: buildUserMessage(question, summary),
      }],
    }),
  });
  if (!res.ok) {
    throw new Error(`llm_http_${res.status}`);
  }
  const body = await res.json() as {
    content?: Array<{ type: string; name?: string; input?: unknown }>;
    usage?: { input_tokens?: number; output_tokens?: number };
  };
  const tool = body.content?.find((c) =>
    c.type === "tool_use" && c.name === RESPOND_TOOL.name
  );
  const reply = parseLlmReply(tool?.input);
  if (!reply) throw new Error("llm_invalid_output");
  return {
    reply,
    inputTokens: body.usage?.input_tokens,
    outputTokens: body.usage?.output_tokens,
  };
}
