# ADR-0010: Recortes de alcance conscientes

- **Estado:** Aceptado · **Fecha:** 2026-10-04

## Problema a resolver
Cubrir todo el alcance mínimo con funcionalidad real en un día, priorizando valor y evaluabilidad.

## Decisiones
| Recorte | Por qué | Mitigación / siguiente paso |
|---|---|---|
| Push solo Android (sin APNs) | APNs requiere cuenta de Apple Developer y dispositivo físico | La app detecta Firebase no configurado y arranca sin push; documentado |
| Transferencias y pagos no implementados | Escrituras de dinero exigen idempotencia, límites, 2FA; fuera del alcance de una prueba | El acceso "Transferir" lleva a cuentas; executor ya distingue operaciones no idempotentes |
| Core bancario simulado en Postgres | No hay core real disponible | Saldo derivado de movimientos por trigger; RLS como si fuera multi-tenant real |
| Una sola app (sin Melos) | Velocidad | ADR-0001: migración mecánica |
| Observabilidad sin sink remoto | Tiempo y cuentas de terceros | ADR-0008: abstracción lista; plan en OPERATIONS.md |
| Un solo ambiente | Tiempo | ADR-0011: config inyectada por CI, lista para varios ambientes |
| Bonus (asistente LLM) no implementado | Prioridad al alcance mínimo y a la resiliencia | Flag `ai_assistant` reservado; SDUI permite agregar la sección sin release |
| E2E con repositorios fake | Determinismo en CI | RLS check SQL, tests Deno y recorrido manual contra Supabase real |

## Trade-offs
Se priorizó profundidad (resiliencia, seguridad, degradación) sobre amplitud de pantallas.

## Impacto a largo plazo
Cada recorte tiene un punto de extensión ya preparado en la arquitectura.
