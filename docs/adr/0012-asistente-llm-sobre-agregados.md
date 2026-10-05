# ADR-0012: Asistente con LLM sobre agregados y tarjetas SDUI generadas

- **Estado:** Aceptado · **Fecha:** 2026-10-05

## Problema a resolver
Ofrecer asistencia personalizada ("¿cuánto gasté en comida?", "¿cómo puedo ahorrar?") y experiencias generadas dinámicamente, sin exponer datos financieros crudos a un proveedor externo ni permitir que un modelo controle la UI.

## Alternativas evaluadas
| Alternativa | Pros | Contras |
|---|---|---|
| **LLM sobre agregados + salida estructurada + saneamiento + fallback por reglas** (elegida) | Mínima exposición de datos; UI segura; nunca "cae" | Respuestas limitadas a lo que permiten los agregados |
| Enviar movimientos crudos al LLM (o RAG sobre ellos) | Respuestas más ricas (comercios, fechas) | Descripciones y montos individuales salen del banco; mayor riesgo regulatorio |
| LLM que devuelve UI libre (HTML/JSON arbitrario) | Máxima flexibilidad | Inyección de acciones/rutas; contenido no controlado |
| Solo reglas (sin LLM) | Determinístico, gratis | Lenguaje rígido; no cubre preguntas abiertas |

## Opción seleccionada
1. **Datos:** RPC `spending_summary()` (security invoker, RLS) que devuelve solo totales por categoría, ingresos, gastos y saldo de 30 días. Los movimientos crudos no salen de Postgres.
2. **Modelo:** Edge Function `assistant` llama al LLM (Anthropic, configurable con `LLM_MODEL`) con *tool use forzado*: la salida debe cumplir un esquema cerrado (`answer` + hasta 3 tarjetas `insight | banner | offer_card`, íconos y acciones `accounts | marketplace | none` de lista blanca). La pregunta va delimitada y tratada como datos (mitiga prompt injection).
3. **Saneamiento:** `sanitizeCards` traduce las tarjetas a secciones SDUI v1 con textos acotados y acciones tipadas; lo que no cumple se descarta. La app las dibuja con el mismo registry del home.
4. **Resiliencia:** sin API key, con timeout (6 s) o con salida inválida, responde con reglas determinísticas sobre los mismos agregados (`source: rules`).
5. **Control:** flag `ai_assistant` (apagable sin release); la app no reintenta automáticamente (cada llamada cuesta tokens); se registran latencia, origen y tokens, nunca la pregunta ni la respuesta.

## Trade-offs
Respuestas menos detalladas que con datos crudos, a cambio de privacidad y de una superficie de ataque mínima. Dependencia de un proveedor de LLM mitigada por el fallback.

## Impacto a largo plazo
El mismo patrón (agregados → modelo con esquema cerrado → saneamiento → SDUI) sirve para nuevas experiencias generadas (metas de ahorro, resúmenes mensuales) sin publicar la app. Siguientes pasos: rate limit por usuario, evaluación offline de respuestas, y modelo alojado en la región si la regulación lo exige.
