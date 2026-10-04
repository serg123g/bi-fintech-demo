# Plataforma Financiera Digital — Prueba Técnica Front-End

App Flutter para una plataforma financiera 100 % digital: onboarding, cuentas y movimientos, home personalizado vía **Server-Driven UI**, micro-app externa, notificaciones push y resiliencia ante red degradada. Backend real en **Supabase** (Auth, Postgres + RLS, Edge Functions como BFF).

> Estado: 🚧 en construcción por fases (ver historial de commits sobre `main`).

## Estructura

```
app/            # Flutter app (feature-first, Clean Architecture por feature)
  lib/core/     # di, network, cache, connectivity, errors, logging, flags, router
  lib/sdui/     # contrato, registry de componentes, renderer, fallback
  lib/design_system/
  lib/features/ # auth, accounts, home, notifications, marketplace, debug
supabase/       # migrations, seed, edge functions (home-layout, send-push)
microapp/       # micro-app externa (HTML/JS, GitHub Pages)
docs/           # ARCHITECTURE, OPERATIONS, AI_USAGE, adr/
scripts/        # utilidades de desarrollo
```

## Requisitos

- Flutter **3.38.9** / Dart 3.10.8 (misma versión fijada en CI)
- Android Studio / Xcode para emuladores
- (Fase 2+) [Supabase CLI](https://supabase.com/docs/guides/cli) y una cuenta de Supabase
- (Fase 7) Proyecto de Firebase con app Android

## Puesta en marcha

```bash
# 1. Variables de entorno
cp .env.example .env        # completar SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, ...

# 2. Carpetas de plataforma (solo la primera vez tras clonar)
cd app
flutter create . --org ec.fintech --project-name fintech_platform --platforms android,ios
rm -f test/widget_test.dart   # el template de flutter create referencia MyApp

# 3. Dependencias
flutter pub get

# 4. Ejecutar (inyecta .env como --dart-define)
../scripts/run.sh
```

## Backend (Supabase)

Proyecto: `olpbrryqkogxxxkuyhbo`. Esquema versionado en `supabase/migrations/`:

| Migración | Contenido |
|-----------|-----------|
| `…140000_core_banking_schema` | `profiles`, `accounts`, `movements`; trigger que mantiene `balance` = Σ movimientos; trigger de alta que crea perfil + cuenta al registrarse |
| `…141000_feature_flags_and_device_tokens` | `feature_flags`, `device_tokens` y RPCs `register_device_token` / `unregister_device_token` |
| `…142000_row_level_security` | RLS en todas las tablas, políticas owner-only, grants mínimos (el cliente nunca escribe saldos ni movimientos) |
| `…143000_customer_snapshot` | RPC `customer_snapshot()` con señales de personalización (saldo, movimientos y transferencias a 30 días) |

```bash
# Solo la primera vez (si no existe supabase/config.toml; responder N a las preguntas)
supabase init
supabase link --project-ref olpbrryqkogxxxkuyhbo   # pide la contraseña de la BD
supabase db push --include-seed                    # migraciones + seed.sql
```

Verificación de RLS: ejecutar `supabase/tests/rls_check.sql` en el SQL Editor de Supabase (o con `psql`). Corre dentro de una transacción con `ROLLBACK` e imprime `RLS CHECK OK`.

### Usuarios de prueba

Creados en Supabase Auth (no por SQL); `seed.sql` les asigna perfil, cuentas y movimientos.

| Email | Segmento | Escenario |
|-------|----------|-----------|
| `joven@test.com` | joven | Saldo bajo (60.81 USD) → banner "fondo de emergencia" |
| `pyme@test.com` | pyme | 2 cuentas, muchas transferencias → acceso rápido a transferir + cobros |
| `premium@test.com` | premium | Saldo alto → oferta de inversión |

## Calidad

```bash
cd app
dart format lib test        # formato
flutter analyze             # lints estrictos (analysis_options.yaml)
flutter test                # unit + widget
```

El CI (`.github/workflows/ci.yml`) ejecuta formato, análisis y tests en cada push a `main`.

## Flujo de contribución — Trunk Based Development

- Se trabaja directamente sobre `main` con commits pequeños y frecuentes.
- Mensajes con [Conventional Commits](https://www.conventionalcommits.org/): `feat(accounts): …`, `fix(sdui): …`, `test(auth): …`, `docs(adr): …`, `ci: …`.
- `main` siempre desplegable: el CI debe estar en verde; el trabajo incompleto se oculta tras **feature flags** (tabla `feature_flags`).
- Releases desde `main` mediante tags (`vX.Y.Z`). Ver `docs/OPERATIONS.md`.

## Documentación

- `docs/ARCHITECTURE.md` — diagramas C4 y de secuencia, supuestos, riesgos, escalamiento
- `docs/adr/` — decisiones de arquitectura
- `docs/OPERATIONS.md` — despliegue y monitoreo
- `docs/AI_USAGE.md` — uso de IA por fase
