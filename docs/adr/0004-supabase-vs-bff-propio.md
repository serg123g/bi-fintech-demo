# ADR-0004: Supabase (BaaS + Edge Functions como BFF) vs BFF propio

- **Estado:** Aceptado · **Fecha:** 2026-10-04

## Problema a resolver
Tener interacción real con servicios (auth, datos, personalización, push) en un día, sin datos simulados.

## Alternativas evaluadas
| Alternativa | Pros | Contras |
|---|---|---|
| **Supabase: Auth + Postgres/RLS + Edge Functions** (elegida) | Backend real en horas; seguridad declarativa (RLS); funciones Deno como BFF | Lock-in moderado; límites del plan; menos control de red/observabilidad |
| BFF propio (NestJS/.NET) + DB | Control total | Días de trabajo en infraestructura, auth y despliegue |
| Firebase (Auth + Firestore) | Ecosistema integrado con FCM | Modelo documental menos natural para dinero; reglas menos expresivas que SQL |

## Opción seleccionada
Lecturas simples directas a PostgREST con RLS; lógica de composición (SDUI) y de integración (push) en Edge Functions.

## Trade-offs
Velocidad y seguridad por defecto a cambio de acoplarse a un proveedor. Se mitiga con repositorios detrás de interfaces en la app y reglas de negocio como funciones puras (portables).

## Impacto a largo plazo
Si el volumen o los requisitos regulatorios lo exigen, `home-layout` y `send-push` se migran a un BFF propio sin cambiar la app (mismo contrato HTTP).
