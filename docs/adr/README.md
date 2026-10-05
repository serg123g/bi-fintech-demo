# Architecture Decision Records

Formato: Problema · Alternativas evaluadas · Opción seleccionada · Trade-offs · Impacto a largo plazo ([plantilla](0000-template.md)).

| # | Decisión |
|---|----------|
| [0001](0001-estructura-modular-vs-melos.md) | Una app con carpetas por feature; evolución a paquetes Melos por equipo |
| [0002](0002-sdui-vs-code-push-vs-remote-config.md) | Server-Driven UI para el home (vs Shorebird y Remote Config) |
| [0003](0003-bloc-vs-riverpod.md) | Bloc + get_it para estado y DI |
| [0004](0004-supabase-vs-bff-propio.md) | Supabase (Auth, Postgres/RLS, Edge Functions como BFF) |
| [0005](0005-estrategia-offline-cache.md) | Stale-while-revalidate con Hive cifrado y claves por usuario |
| [0006](0006-fcm-vs-otros-proveedores.md) | FCM HTTP v1 desde Edge Function, disparado por trigger + pg_net |
| [0007](0007-microapp-webview-vs-paquete-nativo.md) | Micro-apps web en WebView con protocolo versionado |
| [0008](0008-observabilidad.md) | Logs estructurados con correlation ID; Crashlytics/Sentry como sinks |
| [0009](0009-tbd-y-feature-flags.md) | Trunk Based Development + feature flags por segmento |
| [0010](0010-recortes-de-alcance.md) | Recortes de alcance conscientes |
| [0011](0011-configuracion-firebase-fuera-del-repo.md) | Configuración de Firebase fuera del repo, inyectada en CI |
| [0012](0012-asistente-llm-sobre-agregados.md) | Asistente con LLM sobre agregados, salida estructurada y tarjetas SDUI saneadas |
