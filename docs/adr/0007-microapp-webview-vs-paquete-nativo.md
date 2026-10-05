# ADR-0007: Micro-app web en WebView (vs paquete nativo)

- **Estado:** Aceptado · **Fecha:** 2026-10-04

## Problema a resolver
Integrar servicios propios o de terceros desarrollados por otros equipos, que se desplieguen sin publicar la app.

## Alternativas evaluadas
| Alternativa | Pros | Contras |
|---|---|---|
| **Micro-app web en WebView con protocolo de mensajes** (elegida) | Despliegue independiente; cualquier stack; aislada del proceso de datos de la app | UX menos nativa; superficie de ataque web |
| Paquete Flutter del otro equipo | UX nativa; tipado | Acopla releases; requiere publicar la app |
| Abrir navegador externo | Trivial | Sin integración ni contexto; experiencia rota |

## Opción seleccionada
`MicroappPage` con WebView restringido al origen de la micro-app, `JavaScriptChannel` y protocolo versionado `{v, type, payload}` (`ready`, `init`, `benefit_selected`, `close`). Solo se comparte contexto mínimo (nombre, segmento, sección), nunca el token. Estados de carga, timeout y error con reintento.

## Trade-offs
Experiencia algo menos nativa a cambio de autonomía total del equipo dueño de la micro-app.

## Impacto a largo plazo
Regla: capacidades críticas (pagos, transferencias) nativas; experiencias de aliados y catálogos como micro-apps. Si una micro-app necesita actuar en nombre del usuario, se agrega un intercambio de token de alcance limitado (token exchange) en lugar de compartir la sesión.
