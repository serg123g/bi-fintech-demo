/// Configuración inyectada en compilación vía `--dart-define-from-file=../.env`.
///
/// Ningún secreto vive en el código: solo la publishable key de Supabase
/// (`sb_publishable_...`, pública por diseño). La protección real es RLS.
class EnvConfig {
  const EnvConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.microappUrl,
    required this.enableChaosPanel,
  });

  factory EnvConfig.fromEnvironment() => const EnvConfig(
        supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
        supabasePublishableKey:
            String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
        microappUrl: String.fromEnvironment('MICROAPP_URL'),
        enableChaosPanel: bool.fromEnvironment('ENABLE_CHAOS_PANEL'),
      );

  final String supabaseUrl;
  final String supabasePublishableKey;
  final String microappUrl;
  final bool enableChaosPanel;

  /// `true` cuando hay backend configurado. Permite correr tests y CI sin keys.
  bool get hasBackend => supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
