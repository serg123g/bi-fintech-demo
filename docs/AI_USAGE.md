# Uso de herramientas de IA

Registro por fase de cómo se usó IA (Claude, modo agente) durante el desarrollo, qué se corrigió manualmente y su impacto. Se consolida al final en un resumen de impacto en productividad, calidad, documentación y pruebas.

| Fase | Generado con IA | Corregido / decidido por mí | Ahorro estimado |
|------|-----------------|-----------------------------|-----------------|
| 1 — Setup | Estructura de carpetas, `analysis_options.yaml` estricto, composition root con get_it, router, tema, logger estructurado, workflow de CI, README inicial, script de ejecución. | Revisión de versiones de dependencias y del lint set (se quitó `require_trailing_commas` por ruido); generación de carpetas de plataforma con `flutter create .` en local. | ~40 min |
| 2 — Backend Supabase | Migraciones (esquema, triggers de saldo y alta, RLS, grants, RPCs), `seed.sql` idempotente y script de verificación de RLS. La IA levantó un Postgres 16 local con un stub de `auth` para aplicar migraciones + seed + checks antes de entregarlos. | Decisiones de modelo: saldo derivado de movimientos vía trigger, cliente sin permisos de escritura sobre dinero, usuarios creados en Auth (no por SQL), publishable key en lugar de anon key. `supabase link` / `db push` ejecutados por mí. | ~1 h |
| 3 — Auth | Capa domain (entidades, `AuthRepository`, fallos tipados), `SupabaseAuthRepository` con mapeo de errores de GoTrue y respaldo a `user_metadata`, almacenamiento de sesión en `flutter_secure_storage`, `AuthBloc`, splash/login/onboarding de 3 pasos, redirect de go_router como función pura (con `?from=` para deep links y protección contra open redirect) y tests (bloc, redirect, validadores, mapeo de errores, widget de login, smoke). | Ejecución de `flutter analyze`/`flutter test` y prueba manual contra Supabase real; corrección de un commit que la IA hizo con un `git add` demasiado amplio (se deshizo antes del push). | ~1.5 h |

## Flujo de trabajo con IA

1. Plan por fases con criterios de aceptación (prompt inicial versionado en este documento).
2. La IA implementa cada fase en commits pequeños (conventional commits sobre `main`).
3. Yo reviso el diff, corro `flutter analyze` / `flutter test` en local y en CI, y corrijo.
4. Al cierre de cada fase se añade una fila a esta tabla.

## Límites observados

- La IA no tiene acceso a credenciales: proyectos de Supabase/Firebase y secretos se crean manualmente.
- Las versiones de paquetes propuestas se validan contra `flutter pub get`/`pub outdated`.
