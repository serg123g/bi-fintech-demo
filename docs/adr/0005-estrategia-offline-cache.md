# ADR-0005: Estrategia offline — stale-while-revalidate con Hive cifrado

- **Estado:** Aceptado · **Fecha:** 2026-10-04

## Problema a resolver
Mostrar información útil con conectividad limitada, alta latencia o servicios caídos sin mostrar datos de otra persona ni datos engañosos.

## Alternativas evaluadas
| Alternativa | Pros | Contras |
|---|---|---|
| **SWR: cache primero, luego red, con frescura visible** (elegida) | Percepción instantánea; offline útil; simple | Datos potencialmente desactualizados (se indica en UI) |
| Network-first con cache solo si falla | Siempre fresco si hay red | Pantallas en blanco con latencia alta |
| Offline-first con sincronización (drift/PowerSync) | Escrituras offline | Complejidad alta; escrituras offline de dinero son riesgosas |

## Opción seleccionada
`staleWhileRevalidate` + `SwrBloc`. Cache en Hive cifrada con AES-256 (llave en Keychain/Keystore), claves por usuario y borrado en logout/cambio de usuario (`SessionCacheCleaner`). UI con "Actualizado / Datos guardados · hace X min / No pudimos actualizar". Solo lecturas; operaciones de dinero nunca offline.

## Trade-offs
El usuario puede ver saldos de hace minutos (siempre etiquetados) a cambio de no quedarse sin información.

## Impacto a largo plazo
El helper es genérico: cualquier dominio nuevo obtiene el mismo comportamiento offline con una línea.
