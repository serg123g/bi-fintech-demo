# Uso de herramientas de IA

Registro por fase de cómo se usó IA (Claude, modo agente) durante el desarrollo, qué se corrigió manualmente y su impacto. Se consolida al final en un resumen de impacto en productividad, calidad, documentación y pruebas.

| Fase | Generado con IA | Corregido / decidido por mí | Ahorro estimado |
|------|-----------------|-----------------------------|-----------------|
| 1 — Setup | Estructura de carpetas, `analysis_options.yaml` estricto, composition root con get_it, router, tema, logger estructurado, workflow de CI, README inicial, script de ejecución. | Revisión de versiones de dependencias y del lint set (se quitó `require_trailing_commas` por ruido); generación de carpetas de plataforma con `flutter create .` en local. | ~40 min |
| 2 — Backend Supabase | Migraciones (esquema, triggers de saldo y alta, RLS, grants, RPCs), `seed.sql` idempotente y script de verificación de RLS. La IA levantó un Postgres 16 local con un stub de `auth` para aplicar migraciones + seed + checks antes de entregarlos. | Decisiones de modelo: saldo derivado de movimientos vía trigger, cliente sin permisos de escritura sobre dinero, usuarios creados en Auth (no por SQL), publishable key en lugar de anon key. `supabase link` / `db push` ejecutados por mí. | ~1 h |
| 3 — Auth | Capa domain (entidades, `AuthRepository`, fallos tipados), `SupabaseAuthRepository` con mapeo de errores de GoTrue y respaldo a `user_metadata`, almacenamiento de sesión en `flutter_secure_storage`, `AuthBloc`, splash/login/onboarding de 3 pasos, redirect de go_router como función pura (con `?from=` para deep links y protección contra open redirect) y tests (bloc, redirect, validadores, mapeo de errores, widget de login, smoke). | Ejecución de `flutter analyze`/`flutter test` y prueba manual contra Supabase real; corrección de un commit que la IA hizo con un `git add` demasiado amplio (se deshizo antes del push). | ~1.5 h |
| 4 — Cuentas + resiliencia | `ResilientExecutor` (timeout por intento, backoff exponencial con full jitter solo para operaciones idempotentes, circuit breaker por servicio, correlation ID), cache Hive cifrada con AES (llave en Keychain/Keystore) y claves por usuario, helper stale-while-revalidate, `SwrBloc` genérico, pantallas de cuentas y movimientos con skeleton / datos guardados / error con reintento, banner offline y tests (executor, breaker, SWR, mapper, bloc, widgets). | Validación con `flutter analyze`/`flutter test` en local antes de cada commit; prueba manual en modo avión. | ~2 h |
| 4b — Feedback Fase 4 | Padding del botón del home con tokens, estado offline en la barra de frescura (cloud_off, "Datos guardados", color de advertencia), refresco automático al reconectar, `SessionCacheCleaner` y tests de aislamiento de cache entre usuarios. | Detecté los defectos en prueba manual y definí el comportamiento esperado. | ~30 min |
| 5 — SDUI + personalización | Edge Function `home-layout` (Deno) con reglas puras + 8 tests `deno test` ejecutados por la IA antes de entregar; contrato SDUI v1; parser tolerante, registry, renderer con fallo parcial por sección, acciones tipadas con lista blanca; repositorio con red → cache → layout empaquetado; job de CI para Deno; tests de parser, renderer y repositorio. | Decisión de contrato y reglas de negocio; deploy de la función y prueba con los 3 usuarios. | ~2 h |
| 6 — Panel chaos | `ChaosResilientExecutor` (decorador que inyecta latencia, fallas aleatorias y servicios caídos *dentro* de cada intento), `ChaosController` con presets, panel con sliders/switches, estado de circuit breakers y borrado de cache para probar el fallback; tests del decorador y del panel. | Validación manual del escenario 3 s + 50 % en el emulador. | ~45 min |
| 7 — Push FCM | Trigger `movements_notify_push` con pg_net + Vault (validado por la IA en Postgres local con stubs de Vault/pg_net: seed sin pushes, sin Vault solo WARNING, falla de pg_net no bloquea el insert), Edge Function `send-push` con OAuth de service account (JWT RS256 con WebCrypto, sin dependencias) y limpieza de tokens inválidos + 5 tests Deno (incluye verificación criptográfica de la firma), coordinador de push en la app (registro/refresh/logout, deep link en background/terminated, primer plano en la app), detalle de movimiento por id y tests. | Proyecto Firebase y `flutterfire configure`; decisión de mantener la config de Firebase fuera del repo con secrets en CI (ADR-0011); secretos (service account, secreto del webhook) y prueba end-to-end en el emulador. | ~2 h |
| 8 — Micro-app | Micro-app web (HTML/JS sin dependencias, CSP estricta, render con `textContent`), protocolo v1 versionado, workflow de GitHub Pages; la IA la probó en Chromium headless (Playwright): handshake `ready`→`init`, `benefit_selected`, `close`, mensajes inválidos/otra versión ignorados, intento de XSS neutralizado, modo demo sin puente. En Flutter: protocolo tipado, `MicroappCubit` (carga/timeout/error/reintento, chaos) testeable sin WebView, WebView restringido al origen, acciones SDUI `marketplace`/`collections`. | Habilitar GitHub Pages, configurar `MICROAPP_URL` y validar en el emulador. | ~1 h |
| 9 — Tests E2E | Escenarios E2E compartidos (`test/e2e/critical_flow.dart`): flujo crítico login → home SDUI → cuentas → movimientos → detalle → logout, y flujo degradado con `home-layout` caído usando el repositorio y el asset reales; runner VM (CI en cada push) y runner `integration_test` (emulador), workflow nocturno/manual en emulador Android. | Ejecución en emulador y ajuste de esperas. | ~1 h |
| 10 — Documentación | Borradores de `ARCHITECTURE.md` (C4 en Mermaid, secuencias, riesgos, escalamiento), ADR 0001–0010, `OPERATIONS.md` (pipeline, SLOs, métricas de UX, runbook) y este resumen; la IA validó que los diagramas Mermaid compilan. | Revisión de decisiones y alcance, ajuste de redacción y prioridades. | ~1.5 h |

## Resumen de impacto

**Herramienta:** Claude (modo agente) con acceso al repositorio local, a un sandbox en la nube (Postgres 16, Deno, Chromium/Playwright) y sin acceso a credenciales.

| Dimensión | Impacto |
|-----------|---------|
| **Productividad** | ~14 h de trabajo estimado comprimidas en una jornada (ahorro estimado ~11–12 h sumando la tabla). La IA generó el grueso del código, las migraciones, las funciones y la documentación; mi tiempo se fue a decisiones, configuración de servicios y validación en dispositivo. |
| **Calidad** | Lints estrictos desde el primer commit; la IA verificó en su sandbox lo que no dependía de Flutter (migraciones + seed + RLS en Postgres local, 13 tests Deno, micro-app en Chromium headless con un intento de XSS). Los errores que cometió (APIs de paquetes de memoria, un test con zonas de `FakeAsync`, un `git add` demasiado amplio, comandos con comentarios que zsh no interpreta) los detectaron los checks o yo antes del push. |
| **Pruebas** | 119 tests Flutter (unit, widget y 2 E2E que también corren en emulador), 13 tests Deno y un script de verificación de RLS; la IA propuso casos que no habría escrito con el tiempo disponible (aislamiento de cache entre usuarios, firma JWT verificada criptográficamente, contratos inválidos de SDUI y micro-app). |
| **Documentación** | README por capacidad, 11 ADRs, arquitectura con diagramas y operación escritos en paralelo al código, no al final; cada fase dejó su entrada aquí. |

**Cómo se controló el riesgo de usar IA**

- Regla de trabajo: ningún commit de código Dart sin `dart format`, `flutter analyze` y `flutter test` en verde en mi máquina; el CI lo vuelve a comprobar.
- Commits pequeños con Conventional Commits (TBD): cada cambio de la IA es revisable y reversible.
- La IA no tuvo credenciales: proyectos, secretos y despliegues los hice yo.
- Las decisiones de producto y arquitectura (contrato SDUI, reglas de personalización, qué recortar, ADR-0011) las tomé yo; la IA propuso alternativas y trade-offs.

**Lo que haría distinto:** fijar desde el inicio un entorno donde la IA pueda ejecutar Flutter (evita ciclos de "escribe → yo corro los checks → corrige") y pedirle tests de contrato SDUI compartidos entre Deno y Dart.

## Flujo de trabajo con IA

1. Plan por fases con criterios de aceptación (prompt inicial versionado en este documento).
2. La IA implementa cada fase en commits pequeños (conventional commits sobre `main`).
3. Yo reviso el diff, corro `flutter analyze` / `flutter test` en local y en CI, y corrijo.
4. Al cierre de cada fase se añade una fila a esta tabla.

## Límites observados

- La IA no tiene acceso a credenciales: proyectos de Supabase/Firebase y secretos se crean manualmente.
- Las versiones de paquetes propuestas se validan contra `flutter pub get`/`pub outdated`.
