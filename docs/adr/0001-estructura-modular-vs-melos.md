# ADR-0001: Estructura modular por features en una sola app (evolución a Melos)

- **Estado:** Aceptado · **Fecha:** 2026-10-04

## Problema a resolver
La plataforma debe evolucionar hacia dominios administrados por equipos independientes, pero hoy hay un solo desarrollador y un plazo de un día.

## Alternativas evaluadas
| Alternativa | Pros | Contras |
|---|---|---|
| **Una app, carpetas por feature con capas** (elegida) | Cero overhead de tooling; refactors atómicos; CI simple | Las fronteras dependen de disciplina, no del compilador |
| Monorepo Melos con paquetes por feature | Fronteras forzadas por `pubspec`; CI y ownership por paquete | Mucho setup (versionado, bootstrap, paths) para un equipo de 1 |
| Super-app con módulos dinámicos | Despliegue independiente | Flutter no soporta carga dinámica de código de forma oficial |

## Opción seleccionada
`lib/features/<dominio>/{domain,data,presentation}` + `lib/core`, `lib/sdui`, `lib/design_system`. Las features solo dependen de interfaces de `domain`; todo se compone en `core/di/injection.dart` y el router.

## Trade-offs
Se gana velocidad hoy a cambio de que las fronteras no las garantice el compilador (se mitiga con revisión y una regla de imports: `presentation` no importa `data`).

## Impacto a largo plazo
La migración a Melos es mecánica: cada carpeta de feature ya tiene su API pública (interfaces + página) y no hay imports cruzados entre features salvo entidades compartidas, que irían a `packages/core`.
