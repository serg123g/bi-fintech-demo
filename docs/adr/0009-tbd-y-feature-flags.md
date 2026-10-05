# ADR-0009: Trunk Based Development con feature flags

- **Estado:** Aceptado · **Fecha:** 2026-10-04

## Problema a resolver
Integrar continuamente con un `main` siempre desplegable, aun con trabajo incompleto.

## Alternativas evaluadas
| Alternativa | Pros | Contras |
|---|---|---|
| **TBD: commits pequeños a `main` + flags** (elegida) | Integración continua real; historial legible; menos conflictos | Exige CI rápido y disciplina |
| GitFlow | Ramas de release claras | Ramas largas, merges grandes, integración tardía |
| Feature branches + PR | Revisión formal | Para un solo desarrollador agrega latencia sin revisor |

## Opción seleccionada
Commits pequeños con Conventional Commits directo a `main`; regla local: `dart format`, `flutter analyze` y `flutter test` en verde antes de cada commit; CI en cada push (Flutter + Deno). Tabla `feature_flags` por segmento para encender/apagar secciones (p. ej. `emergency_fund`, `ai_assistant` apagado) sin releases. Releases por tags (`vX.Y.Z`) desde `main`.

## Trade-offs
Sin revisión por PR; se compensa con checks automáticos y commits atómicos fáciles de revertir. En equipo se usarían PRs de vida corta (< 1 día) con el mismo pipeline.

## Impacto a largo plazo
Los flags habilitan rollouts graduales y experimentos; se deben limpiar los flags viejos para evitar deuda.
