# ADR-0006: Firebase Cloud Messaging para notificaciones push

- **Estado:** Aceptado · **Fecha:** 2026-10-04

## Problema a resolver
Notificar al cliente cada movimiento y llevarlo al detalle, con la app abierta, en segundo plano o cerrada.

## Alternativas evaluadas
| Alternativa | Pros | Contras |
|---|---|---|
| **FCM HTTP v1 desde una Edge Function** (elegida) | Gratis; estándar en Android; un solo proveedor para Android/iOS; control total del payload | Requiere service account y APNs para iOS |
| Proveedores de engagement (OneSignal, Indigitall, Airship) | Segmentación, campañas, analítica | Costo; otro SDK con datos del cliente; sobredimensionado para transaccionales |
| APNs/FCM directo desde la base | Menos piezas | Lógica y secretos dentro de Postgres |

## Opción seleccionada
Trigger en `movements` → `pg_net` (asíncrono) → Edge Function `send-push` (secreto compartido vía Vault) → FCM HTTP v1 con OAuth de service account firmado con WebCrypto. Tokens por dispositivo con RPC de registro y limpieza automática de tokens inválidos. Deep link reconstruido desde ids validados.

## Trade-offs
Más piezas que un SDK de terceros, a cambio de no compartir datos del cliente con otro proveedor y tener control de seguridad y payload. iOS queda pendiente (APNs).

## Impacto a largo plazo
Campañas de marketing podrían usar un proveedor de engagement en paralelo; las notificaciones transaccionales siguen por este canal propio. Siguiente paso: outbox con reintentos y deduplicación.
