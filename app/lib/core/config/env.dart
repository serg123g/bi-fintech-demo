/// Configuración inyectada en compilación vía `--dart-define-from-file=../.env`.
///
/// Ningún secreto vive en el código: solo la anon key pública de Supabase,
/// que está protegida por RLS en el backend.
class EnvConfig {
  const EnvConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.microappUrl,
    required this.enableChaosPanel,
  });

  factory EnvConfig.fromEnvironment() => const EnvConfig(
        supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
        supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
        microappUrl: String.fromEnvironment('MICROAPP_URL'),
        enableChaosPanel: bool.fromEnvironment('ENABLE_CHAOS_PANEL'),
      );

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String microappUrl;
  final bool enableChaosPanel;

  /// `true` cuando hay backend configurado. Permite correr tests y CI sin keys.
  bool get hasBackend => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
