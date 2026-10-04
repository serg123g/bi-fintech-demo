# Uso de herramientas de IA

Registro por fase de cómo se usó IA (Claude, modo agente) durante el desarrollo, qué se corrigió manualmente y su impacto. Se consolida al final en un resumen de impacto en productividad, calidad, documentación y pruebas.

| Fase | Generado con IA | Corregido / decidido por mí | Ahorro estimado |
|------|-----------------|-----------------------------|-----------------|
| 1 — Setup | Estructura de carpetas, `analysis_options.yaml` estricto, composition root con get_it, router, tema, logger estructurado, workflow de CI, README inicial, script de ejecución. | Revisión de versiones de dependencias y del lint set (se quitó `require_trailing_commas` por ruido); generación de carpetas de plataforma con `flutter create .` en local. | ~40 min |

## Flujo de trabajo con IA

1. Plan por fases con criterios de aceptación (prompt inicial versionado en este documento).
2. La IA implementa cada fase en commits pequeños (conventional commits sobre `main`).
3. Yo reviso el diff, corro `flutter analyze` / `flutter test` en local y en CI, y corrijo.
4. Al cierre de cada fase se añade una fila a esta tabla.

## Límites observados

- La IA no tiene acceso a credenciales: proyectos de Supabase/Firebase y secretos se crean manualmente.
- Las versiones de paquetes propuestas se validan contra `flutter pub get`/`pub outdated`.
