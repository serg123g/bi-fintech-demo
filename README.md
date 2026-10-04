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

- Flutter **stable** ≥ 3.27 (`flutter --version`)
- Android Studio / Xcode para emuladores
- (Fase 2+) [Supabase CLI](https://supabase.com/docs/guides/cli) y una cuenta de Supabase
- (Fase 7) Proyecto de Firebase con app Android

## Puesta en marcha

```bash
# 1. Variables de entorno
cp .env.example .env        # completar SUPABASE_URL, SUPABASE_ANON_KEY, ...

# 2. Carpetas de plataforma (solo la primera vez tras clonar)
cd app
flutter create . --org ec.fintech --project-name fintech_platform --platforms android,ios

# 3. Dependencias
flutter pub get

# 4. Ejecutar (inyecta .env como --dart-define)
../scripts/run.sh
```

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
