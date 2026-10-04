import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/cache/cache_store.dart';
import 'core/config/env.dart';
import 'core/connectivity/connectivity_cubit.dart';
import 'core/connectivity/connectivity_service.dart';
import 'core/di/injection.dart';
import 'core/logging/app_logger.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/session_cache_cleaner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  final logger = sl<AppLogger>();

  // Captura global de errores: punto de enganche para Crashlytics/Sentry.
  FlutterError.onError = (details) {
    logger.error(
      'flutter_error',
      error: details.exception,
      stackTrace: details.stack,
    );
    if (kDebugMode) FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.error('uncaught_error', error: error, stackTrace: stack);
    return true;
  };

  if (!sl<EnvConfig>().hasBackend) {
    runApp(const _MissingConfigApp());
    return;
  }

  final authBloc = sl<AuthBloc>()..add(const AuthStarted());

  // Al cerrar sesión (o cambiar de usuario) no deben quedar saldos ni
  // movimientos de otra persona en disco.
  SessionCacheCleaner(cache: sl<CacheStore>(), authStates: authBloc.stream);

  runApp(
    FintechApp(
      authBloc: authBloc,
      connectivity: ConnectivityCubit(sl<ConnectivityService>()),
    ),
  );
}

/// Falla temprana y explícita si se ejecuta sin `--dart-define-from-file`.
class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Falta configuración: ejecuta la app con '
              '--dart-define-from-file=../.env (ver README).',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
