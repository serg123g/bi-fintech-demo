# Changelog

Generado automáticamente desde los mensajes de commit ([Conventional Commits](https://www.conventionalcommits.org/)) con [git-cliff](https://git-cliff.org).

## v1.1.0 — 2026-10-05

### ✨ Funcionalidades

- **db:** spending_summary RPC exposing only per-category aggregates ([`1530d0f`](https://github.com/serg123g/bi-fintech-demo/commit/1530d0f00ac2cfe811b6b2542a375212d43ef4a3))
- **edge:** LLM assistant on aggregates with structured output, sanitized SDUI cards and rules fallback ([`708a3ab`](https://github.com/serg123g/bi-fintech-demo/commit/708a3abcf029dcb9334baa717eec845ef275ea3e))
- **edge:** assistant quick action behind the ai_assistant flag ([`c67f52f`](https://github.com/serg123g/bi-fintech-demo/commit/c67f52f374f2bea0985220bf9ea5d9cf57cac98b))
- **sdui:** embedded renderer mode, assistant icon and allowed route ([`1ce6f02`](https://github.com/serg123g/bi-fintech-demo/commit/1ce6f02a6f8591fd2f1e5ad80c0b2bc5fff5bbf8))
- **assistant:** chat that renders LLM-generated SDUI cards over spending aggregates ([`55af7d1`](https://github.com/serg123g/bi-fintech-demo/commit/55af7d1c61d4287e189fa6c2b5c60bbfd5554ac0))

### 📝 Documentación

- LLM assistant (ADR-0012), automation and AI usage for bonus features ([`94d5c84`](https://github.com/serg123g/bi-fintech-demo/commit/94d5c8468538fe9dd72844b560094e6195eda90e))

### ⚙️ CI/CD y build

- **deps:** weekly grouped Dependabot updates for pub and GitHub Actions ([`ca4a588`](https://github.com/serg123g/bi-fintech-demo/commit/ca4a58891c2521511275e12e14ace9e2d4469378))
- **release:** changelog from conventional commits with git-cliff in release notes ([`6310a48`](https://github.com/serg123g/bi-fintech-demo/commit/6310a48810bb8a5596bdd4be2485de03196ba5fc))

### 🧹 Mantenimiento

- **release:** bump app version to 1.1.0 ([`8cc7f58`](https://github.com/serg123g/bi-fintech-demo/commit/8cc7f58cf10ac79388a68df99c2159d9a3d4bfc3))

## v1.0.0 — 2026-10-05

### ✨ Funcionalidades

- **core:** add env config, structured logger and get_it composition root ([`e73f28e`](https://github.com/serg123g/bi-fintech-demo/commit/e73f28ec88f1c99ec13c1a352be28396a1f7b236))
- **app:** app shell with go_router, design system theme and global error hooks ([`a099eec`](https://github.com/serg123g/bi-fintech-demo/commit/a099eecbb78b13277e8b129244719f71b1af63eb))
- **db:** core banking schema with balance trigger and signup provisioning ([`12d5ec0`](https://github.com/serg123g/bi-fintech-demo/commit/12d5ec02af2a88f7521a57ab5ef0ce72a9e08797))
- **db:** feature flags table and device token registration RPCs ([`5bc26b3`](https://github.com/serg123g/bi-fintech-demo/commit/5bc26b3f156a970097aff35fa72a43c220aa82ce))
- **db:** enable RLS with owner-only policies and least-privilege grants ([`ae20c32`](https://github.com/serg123g/bi-fintech-demo/commit/ae20c3235b2c62cfdff891ca6c9fdfbfd45bad67))
- **db:** customer_snapshot RPC with personalization signals ([`7ee413d`](https://github.com/serg123g/bi-fintech-demo/commit/7ee413d4be38dbff2c9f828d5c8d2b9a22a79b09))
- **db:** idempotent seed for joven, pyme and premium demo users ([`4eed7af`](https://github.com/serg123g/bi-fintech-demo/commit/4eed7af46e0e552502ee1347866c5a8707f7a833))
- **core:** typed domain failures and secure session storage for Supabase ([`6210e2d`](https://github.com/serg123g/bi-fintech-demo/commit/6210e2d5fa6e907ef4e0a4333ab0b86a71127299))
- **auth:** domain entities and AuthRepository contract ([`3161140`](https://github.com/serg123g/bi-fintech-demo/commit/3161140964e4da6e24723034eab2a2fc5376935a))
- **auth:** Supabase auth repository with profile fallback and error mapping ([`ee17fc9`](https://github.com/serg123g/bi-fintech-demo/commit/ee17fc91b5a874bd2d484082ce519de79505e1ae))
- **auth:** AuthBloc with session restore, sign-in, sign-up and sign-out ([`afc0fc8`](https://github.com/serg123g/bi-fintech-demo/commit/afc0fc8a4914e595aa3c07868380f7e961727a99))
- **auth:** splash, login and 3-step onboarding with segment selection ([`db577b1`](https://github.com/serg123g/bi-fintech-demo/commit/db577b1d12ffbc65329c7719855569a89b22b132))
- **router:** auth-aware redirects, Supabase bootstrap and auth DI wiring ([`332c5bc`](https://github.com/serg123g/bi-fintech-demo/commit/332c5bc9db7759c0d56a0f0093053e3e734a2fcc))
- **core:** resilient executor with timeout, jittered backoff and per-service circuit breaker ([`da0d33d`](https://github.com/serg123g/bi-fintech-demo/commit/da0d33df5671a3326f3511da88a8665be5b982cd))
- **core:** AES-encrypted Hive cache and stale-while-revalidate helper ([`b39ff12`](https://github.com/serg123g/bi-fintech-demo/commit/b39ff123279e4815452261548a60cbd78d1a7450))
- **core:** connectivity service, cubit and global offline banner ([`abe448f`](https://github.com/serg123g/bi-fintech-demo/commit/abe448fc0830191a0ece40d699ea154267228d72))
- **accounts:** domain entities, Supabase data source and cached repository ([`5d39b3d`](https://github.com/serg123g/bi-fintech-demo/commit/5d39b3d5b2099f78e9d98e58d49fd74e192d1a58))
- **accounts:** generic SwrBloc with ResourceState and accounts/movements blocs ([`43e3c0c`](https://github.com/serg123g/bi-fintech-demo/commit/43e3c0c46049692b5b902d21df1b2c2d084bda64))
- **accounts:** accounts and movements screens with skeleton, freshness and retry states ([`23d66b4`](https://github.com/serg123g/bi-fintech-demo/commit/23d66b48f9a0538a64d609beacd44f92ab30a3db))
- **edge:** home-layout function with pure personalization rules and deno tests ([`b66eb68`](https://github.com/serg123g/bi-fintech-demo/commit/b66eb683906360ef92972d29a6d5a9f40ca4d4fa))
- **sdui:** contract models, tolerant parser, registry, renderer and typed actions ([`99b37d1`](https://github.com/serg123g/bi-fintech-demo/commit/99b37d1870d25294889364efeb3aa7bb7df8ab02))
- **home:** server-driven home with cached layout and bundled fallback ([`ef9c085`](https://github.com/serg123g/bi-fintech-demo/commit/ef9c08518f651e1a10237fd612e68c45fc4e0868))
- **core:** chaos executor decorator with latency, failure rate and service outages ([`e982c39`](https://github.com/serg123g/bi-fintech-demo/commit/e982c39a9d9ad85d9f22837ae8e063e115e0d467))
- **debug:** chaos panel with presets, circuit breaker status and cache reset ([`ff3daf5`](https://github.com/serg123g/bi-fintech-demo/commit/ff3daf5c4e15b6c68eecfeb54ec6b2d799532b91))
- **db:** notify send-push on movement insert via pg_net with Vault secrets ([`a45f519`](https://github.com/serg123g/bi-fintech-demo/commit/a45f5199521d3b8a1224db56fff546c53aabf34c))
- **edge:** send-push function with FCM HTTP v1, service-account OAuth and stale token cleanup ([`d02bd21`](https://github.com/serg123g/bi-fintech-demo/commit/d02bd2116ffa57669e99d3c29ccff62c903a0aaa))
- **accounts:** movement detail by id as push deep-link target ([`517355b`](https://github.com/serg123g/bi-fintech-demo/commit/517355bf0a7e60c71c60ddf58ed709674518fa3e))
- **notifications:** push coordinator with token lifecycle and validated deep links ([`52be260`](https://github.com/serg123g/bi-fintech-demo/commit/52be260553452d9fd95b982a54ae5ed3e9ff6ca2))
- **app:** initialise Firebase from generated options and wire push into the app ([`7e43047`](https://github.com/serg123g/bi-fintech-demo/commit/7e430470f5177aa0b6e5673c4aec347d20ba6202))
- **microapp:** benefits micro-app with versioned host bridge protocol and CSP ([`529662e`](https://github.com/serg123g/bi-fintech-demo/commit/529662e7c5390334c849e95e4c7625e87f9234a0))
- **marketplace:** typed micro-app protocol and lifecycle cubit with timeout and retry ([`3efa3b5`](https://github.com/serg123g/bi-fintech-demo/commit/3efa3b54ed2a8ee3709a78bc4ac677bb1c70d9a8))
- **marketplace:** origin-restricted WebView host wired to SDUI microapp actions ([`8da8c8d`](https://github.com/serg123g/bi-fintech-demo/commit/8da8c8d5d411dc5c8b748755f5397e1670c6b26e))

### 🐛 Correcciones

- **app:** drop unused import and document platform folder generation ([`d9154ad`](https://github.com/serg123g/bi-fintech-demo/commit/d9154ad21fc20db1fbaf2ab7b4574ad99c536cef))
- **android:** declare INTERNET permission for release builds ([`d188d5e`](https://github.com/serg123g/bi-fintech-demo/commit/d188d5eb582bf244bae6c9b5eff5220abab322de))
- **core:** use publishableKey in Supabase.initialize (anonKey is deprecated) ([`b2b7fd0`](https://github.com/serg123g/bi-fintech-demo/commit/b2b7fd024b0e87b1c7f462d0b65a437ece388fc6))
- **accounts:** show saved-data state while offline and refresh on reconnect ([`bdb66e4`](https://github.com/serg123g/bi-fintech-demo/commit/bdb66e4ac053328a37d36ded7e3231ec62ac1695))
- **auth:** clear cache on logout and user switch; test cross-user cache isolation ([`c1d2d62`](https://github.com/serg123g/bi-fintech-demo/commit/c1d2d62a235c4227d60828df044263a7810f2ae8))

### ♻️ Refactor

- **config:** use Supabase publishable key instead of legacy anon key ([`e09525c`](https://github.com/serg123g/bi-fintech-demo/commit/e09525c79a3e2739547e7965c4ed254e9620e2ff))

### 🧪 Pruebas

- **db:** RLS and data-rule checks runnable against the linked project ([`7c03df9`](https://github.com/serg123g/bi-fintech-demo/commit/7c03df985c305e7138a414f8ac7a16879f30ab78))
- **auth:** AuthBloc, redirect rules, validators, error mapping and login widget tests ([`713618a`](https://github.com/serg123g/bi-fintech-demo/commit/713618ad15c61a9f1fbf2a52a9ff4e4d262148e6))
- **auth:** register mocktail fallback for CustomerSegment matcher ([`fd13d4e`](https://github.com/serg123g/bi-fintech-demo/commit/fd13d4ed8794dfdfbcf44299459642ff5a5fabe5))
- **app:** keep widget-test blocs inside the FakeAsync zone ([`0cad3e5`](https://github.com/serg123g/bi-fintech-demo/commit/0cad3e51b0ce78441e8a73ec9e452d035ee7f2a3))
- **e2e:** shared critical and degraded-home flows on the real composition root ([`6ac0df4`](https://github.com/serg123g/bi-fintech-demo/commit/6ac0df4aa39d7294b85061ed5a80376051416cc0))

### 📝 Documentación

- initial README, env template and run script ([`ef4f239`](https://github.com/serg123g/bi-fintech-demo/commit/ef4f239bcf2c2d897889faa84ab3e9148ad3de50))
- **ai:** start AI usage log and ADR template ([`1015554`](https://github.com/serg123g/bi-fintech-demo/commit/101555475222c52c8e484d193b3354c4f756509a))
- **readme:** Supabase setup, migrations overview and demo users ([`41e9c5e`](https://github.com/serg123g/bi-fintech-demo/commit/41e9c5e41d37bb43e7791a7831bf2965ecbdefa1))
- **ai:** log AI usage for phase 2 ([`ea47d96`](https://github.com/serg123g/bi-fintech-demo/commit/ea47d969f9ef6e61f7ab252ab626961fa1c146ec))
- document auth flow and log AI usage for phase 3 ([`e972abd`](https://github.com/serg123g/bi-fintech-demo/commit/e972abd140c044a90ff0b3f661e2f3cebe4b8c2d))
- resilience and offline behaviour, AI usage for phase 4 ([`a5f5957`](https://github.com/serg123g/bi-fintech-demo/commit/a5f59577cab3de02f6dadc7c6b6f08eb079e93aa))
- SDUI personalization and AI usage for phases 4b and 5 ([`26126cc`](https://github.com/serg123g/bi-fintech-demo/commit/26126cc58768a80a7b5b6a9d03ae8c63db05b3f1))
- chaos panel usage and AI usage for phase 6 ([`e2de7a1`](https://github.com/serg123g/bi-fintech-demo/commit/e2de7a1774b94b1251e21186baf718e387bb65d1))
- **adr:** keep Firebase config out of the repo (ADR-0011); push setup and AI usage ([`270756a`](https://github.com/serg123g/bi-fintech-demo/commit/270756a745dcb1af20da3c532c669e0eb8686d52))
- micro-app protocol, Pages setup and AI usage for phase 8 ([`393533f`](https://github.com/serg123g/bi-fintech-demo/commit/393533f5098bcd48ee8d6e91e071c696a49029de))
- test strategy matrix and AI usage for phase 9 ([`8b9678e`](https://github.com/serg123g/bi-fintech-demo/commit/8b9678e140bd176e4c5e9f16119481962ee51051))
- **architecture:** C4 views, critical sequences, risks and scaling strategy ([`5fac58e`](https://github.com/serg123g/bi-fintech-demo/commit/5fac58e2a9f62ccaf99594dd0fee6c6d64259e0b))
- **adr:** ADRs 0001-0010 and decision index ([`b3d0426`](https://github.com/serg123g/bi-fintech-demo/commit/b3d0426bd72df10680e26c7a5807eab911fce173))
- **operations:** pipeline, environments, rollout, monitoring, SLOs and runbook ([`6d23942`](https://github.com/serg123g/bi-fintech-demo/commit/6d2394216869129f1add0848dc2f29aec2f7468d))
- AI impact summary and final README documentation index ([`43f496c`](https://github.com/serg123g/bi-fintech-demo/commit/43f496c6178769cde7040fa4bc9cb7b0ad4ed989))
- install-without-building section and release pipeline ([`9ede630`](https://github.com/serg123g/bi-fintech-demo/commit/9ede6301036e704adb6ce6d8740c5333bf37e45e))

### ⚙️ CI/CD y build

- run format, analyze and tests on every push to main ([`9ccf1e5`](https://github.com/serg123g/bi-fintech-demo/commit/9ccf1e57610d5559176080d90b9b1a80ea2445d5))
- pin Flutter 3.38.9 (Dart 3.10.8) to match local toolchain ([`2bf2757`](https://github.com/serg123g/bi-fintech-demo/commit/2bf2757194f5accd0504a81c978eb0c7b931b80c))
- lint, typecheck and test edge functions with Deno ([`e38a05e`](https://github.com/serg123g/bi-fintech-demo/commit/e38a05e78f6673e7d1de2ba34aafdb9b991a42c5))
- **android:** apply Google Services plugin and request POST_NOTIFICATIONS ([`445fce1`](https://github.com/serg123g/bi-fintech-demo/commit/445fce1e35668d09bfe001feedb662dd31e5f857))
- rebuild Firebase config from secrets and format only tracked files ([`214ebc6`](https://github.com/serg123g/bi-fintech-demo/commit/214ebc64326e016b2b0c8000c1b52ffad74143a6))
- deploy the micro-app to GitHub Pages ([`d2ee5e9`](https://github.com/serg123g/bi-fintech-demo/commit/d2ee5e930b382523e28e47c1263a4c734af89738))
- nightly/manual E2E on an Android emulator ([`d04948c`](https://github.com/serg123g/bi-fintech-demo/commit/d04948ca8867e6e7e2efd417b8500e98554634de))
- **release:** build release APK on version tags and publish it to GitHub Releases ([`150830c`](https://github.com/serg123g/bi-fintech-demo/commit/150830cd6368eff0470dc850849d1bf0937c6a52))

### 📦 Dependencias

- **deps:** refresh lockfile after Dart 3.10 SDK constraint ([`bf6db15`](https://github.com/serg123g/bi-fintech-demo/commit/bf6db159f41725b06d200849d3c29b0c573ecfdb))
- **deps:** add supabase_flutter and flutter_secure_storage ([`5ca69da`](https://github.com/serg123g/bi-fintech-demo/commit/5ca69da24b3dd26dcca209527968bdbea9f0880a))
- **deps:** lock supabase_flutter 2.18 and flutter_secure_storage 9.2 ([`f743172`](https://github.com/serg123g/bi-fintech-demo/commit/f743172a4534e0c6def9aaeae51fbddeb6beb07d))
- **deps:** add hive_ce, hive_ce_flutter and connectivity_plus ([`34e6b33`](https://github.com/serg123g/bi-fintech-demo/commit/34e6b331f397f1a8fa26bb0d9fdd3d23dc368c06))
- **deps:** add url_launcher for SDUI url actions ([`fefc826`](https://github.com/serg123g/bi-fintech-demo/commit/fefc8262f365ab3e38a853edcdd8ae4ab94b6151))
- **deps:** add firebase_core and firebase_messaging ([`81d4781`](https://github.com/serg123g/bi-fintech-demo/commit/81d47819e7720b47b00aa63ca2f466b48025ef79))
- **deps:** add webview_flutter for hosted micro-apps ([`a64717a`](https://github.com/serg123g/bi-fintech-demo/commit/a64717aa3b5bedd3ff606cc8322ede612e2695e3))

### 🧹 Mantenimiento

- scaffold repo structure, strict lints and gitignore ([`e42ecde`](https://github.com/serg123g/bi-fintech-demo/commit/e42ecdec95cd45f2c8f9a9bd398ab9c9e3940fe8))
- **app:** generate android and ios platform folders ([`24bae89`](https://github.com/serg123g/bi-fintech-demo/commit/24bae89e8fd5d500179dafab68aa3e8791b5c0f5))
- **security:** harden gitignore for env files, service accounts and signing keys ([`0b21b89`](https://github.com/serg123g/bi-fintech-demo/commit/0b21b8973d4c4b53250d9f3c9aec55c146ea2e85))
- **ios:** add CocoaPods Podfile for native plugins ([`b71a03e`](https://github.com/serg123g/bi-fintech-demo/commit/b71a03e29e2e22297a76027b99a433175d9006a7))
- apply dart format ([`2814e4f`](https://github.com/serg123g/bi-fintech-demo/commit/2814e4fc1e9625110229a89c61643238f70627d8))
- **supabase:** add cli config ([`31ecab9`](https://github.com/serg123g/bi-fintech-demo/commit/31ecab99ab421e8f1d7aceeba4228412aff92659))
- **release:** bump app version to 1.0.0 ([`e897cce`](https://github.com/serg123g/bi-fintech-demo/commit/e897cce5562d2b8df9ee6a11242b817e613a0625))

