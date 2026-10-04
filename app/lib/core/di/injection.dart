import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show FlutterAuthClientOptions, Supabase, SupabaseClient;

import '../../features/auth/data/supabase_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../config/env.dart';
import '../logging/app_logger.dart';
import '../storage/secure_session_storage.dart';

/// Service locator global. Las features solo dependen de interfaces de
/// `domain`; las implementaciones se registran aquí (composition root).
final GetIt sl = GetIt.instance;

/// Permite a tests y al E2E reemplazar registros (repos fake, executor
/// con chaos, etc.) antes de construir la app.
typedef DiOverrides = void Function(GetIt sl);

Future<void> configureDependencies({
  EnvConfig? env,
  DiOverrides? overrides,
}) async {
  await sl.reset();
  final config = env ?? EnvConfig.fromEnvironment();
  sl
    ..registerSingleton<EnvConfig>(config)
    ..registerSingleton<AppLogger>(const ConsoleLogger());

  // --- Backend -------------------------------------------------------------
  if (config.hasBackend) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      // Publishable key (sb_publishable_...). Nunca la secret key.
      anonKey: config.supabasePublishableKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureSessionStorage(),
      ),
    );
    sl
      ..registerSingleton<SupabaseClient>(Supabase.instance.client)
      ..registerLazySingleton<AuthRepository>(
        () => SupabaseAuthRepository(sl<SupabaseClient>(), sl<AppLogger>()),
      );
  }

  // --- Presentación (app-wide) --------------------------------------------
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(sl<AuthRepository>()),
    dispose: (bloc) => bloc.close(),
  );

  sl.allowReassignment = true;
  overrides?.call(sl);
  sl.allowReassignment = false;
}
