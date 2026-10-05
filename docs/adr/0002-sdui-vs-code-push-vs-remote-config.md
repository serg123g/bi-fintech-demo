# ADR-0002: Server-Driven UI para el home (vs code push y Remote Config)

- **Estado:** Aceptado · **Fecha:** 2026-10-04

## Problema a resolver
Incorporar experiencias, contenidos o componentes y personalizarlos por perfil/contexto **sin publicar una nueva versión** de la app.

## Alternativas evaluadas
| Alternativa | Pros | Contras |
|---|---|---|
| **SDUI con contrato propio** (elegida) | Personalización por usuario en tiempo real; orden y contenido decididos por el servidor; testeable | Hay que diseñar y versionar el contrato; solo compone componentes ya existentes en la app |
| Code push (Shorebird) | Cambia lógica Dart sin tiendas | No es personalización por usuario; riesgo regulatorio/políticas de tienda en banca; parches globales |
| Firebase Remote Config | Rápido para flags y textos | Pensado para parámetros, no para layouts; personalización limitada a condiciones de audiencia |

## Opción seleccionada
Contrato SDUI v1 (`version`, `sections[{id,type,props}]`, acciones tipadas `route|url|microapp`) generado por la Edge Function `home-layout` con reglas puras. En la app: parser tolerante, registry de componentes, renderer con fallo parcial por sección y fallback empaquetado.

## Trade-offs
Más diseño inicial y un catálogo de componentes que crece con la app; a cambio, cambiar el home (o apagarlo por flag) es un deploy de backend de segundos.

## Impacto a largo plazo
Los equipos de cada dominio pueden aportar secciones al home registrando componentes; las apps viejas ignoran tipos nuevos. Code push queda como complemento posible para hotfixes, no como mecanismo de personalización.
