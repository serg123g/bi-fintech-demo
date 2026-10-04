import 'package:flutter/services.dart' show rootBundle;
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show FlutterAuthClientOptions, Supabase, SupabaseClient;

import '../../features/accounts/data/accounts_remote_data_source.dart';
import '../../features/accounts/data/accounts_repository_impl.dart';
import '../../features/accounts/domain/repositories/accounts_repository.dart';
import '../../features/auth/data/supabase_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/home/data/home_layout_remote_data_source.dart';
import '../../features/home/data/home_layout_repository_impl.dart';
import '../../features/home/domain/home_layout_repository.dart';
import '../../sdui/sdui_action_handler.dart';
import '../cache/cache_store.dart';
import '../cache/hive_cache_store.dart';
import '../config/env.dart';
import '../connectivity/connectivity_service.dart';
import '../logging/app_logger.dart';
import '../network/resilient_executor.dart';
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
    ..registerSingleton<AppLogger>(const ConsoleLogger())
    ..registerLazySingleton<ResilientExecutor>(
      () => DefaultResilientExecutor(logger: sl<AppLogger>()),
    )
    ..registerLazySingleton<SduiActionHandler>(
      () => SduiActionHandler(logger: sl<AppLogger>()),
    );

  // --- Backend -------------------------------------------------------------
  if (config.hasBackend) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      // Publishable key (sb_publishable_...). Nunca la secret key.
      publishableKey: config.supabasePublishableKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureSessionStorage(),
      ),
    );
    final client = Supabase.instance.client;
    sl
      ..registerSingleton<CacheStore>(await HiveCacheStore.open())
      ..registerLazySingleton<ConnectivityService>(PlusConnectivityService.new)
      ..registerSingleton<SupabaseClient>(client)
      ..registerLazySingleton<AccountsRemoteDataSource>(
        () => SupabaseAccountsRemoteDataSource(client, sl<ResilientExecutor>()),
      )
      ..registerLazySingleton<AccountsRepository>(
        () => AccountsRepositoryImpl(
          remote: sl<AccountsRemoteDataSource>(),
          cache: sl<CacheStore>(),
          currentUserId: () => client.auth.currentUser?.id ?? 'anonymous',
        ),
      )
      ..registerLazySingleton<HomeLayoutRemoteDataSource>(
        () =>
            SupabaseHomeLayoutRemoteDataSource(client, sl<ResilientExecutor>()),
      )
      ..registerLazySingleton<HomeLayoutRepository>(
        () => HomeLayoutRepositoryImpl(
          remote: sl<HomeLayoutRemoteDataSource>(),
          cache: sl<CacheStore>(),
          currentUserId: () => client.auth.currentUser?.id ?? 'anonymous',
          loadFallback: () =>
              rootBundle.loadString('assets/sdui/home_fallback.json'),
        ),
      )
      ..registerLazySingleton<AuthRepository>(
        () => SupabaseAuthRepository(sl<SupabaseClient>(), sl<AppLogger>()),
      );
  }

  if (!sl.isRegistered<CacheStore>()) {
    sl.registerSingleton<CacheStore>(InMemoryCacheStore());
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
