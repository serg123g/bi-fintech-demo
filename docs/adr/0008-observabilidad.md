# ADR-0008: Observabilidad — logs estructurados con correlation ID

- **Estado:** Aceptado (implementación base) · **Fecha:** 2026-10-04

## Problema a resolver
Detectar y diagnosticar problemas operativos y de experiencia en producción, y poder seguir una operación de punta a punta.

## Alternativas evaluadas
| Alternativa | Pros | Contras |
|---|---|---|
| **Abstracción `AppLogger` + correlation ID; Crashlytics/Sentry como sinks** (elegida) | Features desacopladas del proveedor; trazabilidad app↔Edge Function hoy | Requiere conectar el sink en producción |
| Integrar Sentry/Crashlytics directamente en cada feature | Rápido | Acopla el código al proveedor |
| OpenTelemetry completo en móvil | Estándar | SDK móvil inmaduro; costo de setup |

## Opción seleccionada
- `AppLogger` estructurado (`clave=valor`); `FlutterError.onError` y `PlatformDispatcher.onError` centralizados.
- `ResilientExecutor` loguea `request_ok/request_failed` con servicio, intento, duración y `correlationId` (uno por operación lógica, compartido entre reintentos), que viaja en `x-correlation-id` a las Edge Functions, que también lo registran en JSON.
- Producción: implementación de `AppLogger` que envía errores a Crashlytics o Sentry y métricas de performance (ver `docs/OPERATIONS.md`).

## Trade-offs
Hoy los logs del cliente quedan en el dispositivo; se aceptó porque el punto de enganche está listo y el cambio no toca features.

## Impacto a largo plazo
Cambiar de proveedor de observabilidad es reemplazar una clase en el composition root.
