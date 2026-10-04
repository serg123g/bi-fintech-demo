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

### Autenticación

- Email + contraseña con Supabase Auth. En **Authentication → Providers → Email** desactivar *Confirm email* para la demo (si está activo, el registro muestra "Confirma tu correo").
- El onboarding (3 pasos) envía `full_name` y `segment` en `user_metadata`; el trigger `handle_new_user` crea el perfil y una cuenta de ahorros.
- La sesión se guarda cifrada con `flutter_secure_storage` (Keychain / EncryptedSharedPreferences), no en SharedPreferences.
- Navegación protegida por `authRedirect` (`lib/core/router/auth_redirect.dart`): sin sesión → login; los deep links protegidos se conservan en `?from=`.

### Resiliencia y modo offline

Todas las llamadas remotas pasan por `ResilientExecutor` (`lib/core/network/`):

| Mecanismo | Comportamiento |
|-----------|----------------|
| Timeout | 8 s por intento |
| Reintentos | 3 intentos, backoff exponencial con *full jitter* (300 ms → máx. 3 s). Solo operaciones idempotentes y errores transitorios (red, 5xx) |
| Circuit breaker | Por servicio: 3 fallos seguidos → abierto 15 s (no se llama al backend) → half-open con una llamada de prueba |
| Trazabilidad | Un `correlationId` por operación lógica (compartido entre reintentos) en los logs; las Edge Functions lo reciben en el header `x-correlation-id` |

Lecturas con **stale-while-revalidate**: se muestra al instante lo guardado (Hive cifrado con AES, llave en Keychain/Keystore, claves por usuario, se borra al cerrar sesión) con "actualizado hace X", y se refresca en segundo plano. Estados en UI: skeleton → datos (frescos / guardados) → error con **Reintentar**. Banner global sin conexión vía `connectivity_plus`.

Prueba manual: abrir *Mis cuentas* con red → activar modo avión → reabrir: se ven los datos guardados con aviso; al volver la red, *Reintentar* (o pull-to-refresh) actualiza.

### Home personalizado (Server-Driven UI)

El home lo arma la Edge Function `supabase/functions/home-layout` a partir de `customer_snapshot()` y `feature_flags`, con reglas puras en `rules.ts` (testeadas con `deno test`):

| Señal | Resultado en el home |
|-------|---------------------|
| Hora local (America/Guayaquil) | "Buenos días / Buenas tardes / Buenas noches, {nombre}" |
| Saldo total < $100 | Banner "Arma tu fondo de emergencia" |
| ≥ 5 transferencias en 30 días | Acceso rápido "Transferir" primero |
| Segmento pyme | Acceso rápido "Cobros" |
| Segmento premium | Tarjeta de oferta de inversión |
| Gastos del mes | Insight con la categoría de mayor gasto |

Contrato v1: `{version, layout_id, generated_at, ttl_seconds, sections: [{id, type, props}]}`; acciones tipadas `route | url | microapp` validadas contra lista blanca en la app. Tipos de sección desconocidos se ignoran (compatibilidad hacia adelante) y una sección con props inválidas se omite sin afectar al resto.

Degradación: red → último layout guardado → `assets/sdui/home_fallback.json`. Apagar un flag en `feature_flags` cambia el home sin publicar la app.

```bash
# Deploy (la función valida el token del usuario con auth.getUser)
supabase functions deploy home-layout --no-verify-jwt
# Tests de reglas
cd supabase/functions && deno test home-layout/
```

### Panel chaos (demostración de resiliencia)

Disponible en debug o con `ENABLE_CHAOS_PANEL=true` (ícono 🐞 en el home → `/debug`). Se implementa como decorador del `ResilientExecutor` (`lib/core/chaos/`), así que repositorios y UI no saben que existe: las fallas se inyectan dentro de cada intento y los reintentos, el circuit breaker, la cache y el fallback reaccionan igual que en producción.

| Control | Efecto |
|---------|--------|
| Latencia 0–5 s | Se suma a cada intento → skeletons y "Actualizando…" |
| Tasa de fallo 0–100 % | Falla aleatoria por intento → reintentos con backoff |
| Caer home-layout | Home desde el último layout guardado o el empaquetado |
| Caer cuentas | Solo la tarjeta de saldo muestra error (fallo parcial) |
| Caer micro-app | La micro-app muestra error con reintento (Fase 8) |
| Circuit breakers | Estado por servicio (cerrado / ABIERTO / semi-abierto) |
| Borrar cache local | Para probar el fallback empaquetado |

Escenario de aceptación: preset **3 s + 50 % fallas** → volver al home y hacer pull-to-refresh.

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
