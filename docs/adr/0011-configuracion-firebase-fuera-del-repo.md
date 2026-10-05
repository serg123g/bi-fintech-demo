# ADR-0011: Configuración de Firebase fuera del repositorio

- **Estado:** Aceptado
- **Fecha:** 2026-10-04

## Problema a resolver

La app necesita `lib/firebase_options.dart` (generado por FlutterFire) y `android/app/google-services.json` para inicializar Firebase y recibir push. Hay que decidir si esos archivos viven en el repositorio público.

## Alternativas evaluadas

| Alternativa | Pros | Contras |
|-------------|------|---------|
| **Versionarlos** | Clonar y correr; es la recomendación por defecto de Firebase (no son secretos: la seguridad real está en reglas, App Check y restricciones de la API key) | Expone ids de proyecto y API keys en un repo público; acopla el código a un único ambiente (cambiar a staging/prod implica commits) |
| **Generarlos localmente + secrets en CI** (elegida) | Nada de configuración de ambiente en el repo; cada ambiente (dev/staging/prod) se inyecta en el pipeline | Más fricción de setup: hay que ejecutar `flutterfire configure` antes de correr la app |
| Inyectarlos con `--dart-define` | Sin archivos generados | `google-services.json` lo sigue necesitando Gradle; más código propio que mantener |

## Opción seleccionada

`firebase_options.dart`, `google-services.json` y `firebase.json` están en `.gitignore`.

- **Local:** `flutterfire configure --project=bi-fintech-demo --platforms=android` dentro de `app/`.
- **CI:** los secrets `FIREBASE_OPTIONS_DART` y `GOOGLE_SERVICES_JSON` (base64) se decodifican antes de `analyze`/`test`.
- **CI sin secrets** (PRs de Dependabot y forks, que no reciben los secrets de Actions): se genera un stub de `firebase_options.dart` que compila; `analyze`/`test` no usan Firebase.
- **Runtime:** si Firebase no está configurado para la plataforma, la app arranca sin push (degradación explícita, ver `main.dart`).

## Trade-offs

Más fricción de setup y una dependencia del CI en dos secrets, a cambio de no exponer configuración en un repo público ni acoplar el código a un ambiente.

## Impacto a largo plazo

Habilita varios ambientes (sabores dev/staging/prod) con distintos proyectos de Firebase sin tocar el código: solo cambian los secrets del pipeline. Si se rotan proyectos o keys, no queda historial en git que limpiar.
