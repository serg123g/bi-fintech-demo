import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app.dart';
import 'core/cache/cache_store.dart';
import 'core/config/env.dart';
import 'core/connectivity/connectivity_cubit.dart';
import 'core/connectivity/connectivity_service.dart';
import 'core/di/injection.dart';
import 'core/logging/app_logger.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/session_cache_cleaner.dart';
import 'features/notifications/data/firebase_push_messaging_client.dart';
import 'features/notifications/domain/push_messaging_client.dart';
import 'features/notifications/presentation/push_notifications_coordinator.dart';
import 'firebase_options.dart';

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

  final router = buildRouter(authBloc: authBloc);
  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  final push = await _setUpPush(authBloc, router, messengerKey, logger);

  runApp(
    FintechApp(
      authBloc: authBloc,
      connectivity: ConnectivityCubit(sl<ConnectivityService>()),
      router: router,
      scaffoldMessengerKey: messengerKey,
    ),
  );

  // Notificación que abrió la app desde cerrada: tras el primer frame.
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => push?.handleInitialMessage().ignore(),
  );
}

/// Push es opcional: si Firebase no está configurado para la plataforma
/// (p. ej. iOS, ver ADR-0011) la app funciona igual, sin notificaciones.
Future<PushNotificationsCoordinator?> _setUpPush(
  AuthBloc authBloc,
  GoRouter router,
  GlobalKey<ScaffoldMessengerState> messengerKey,
  AppLogger logger,
) async {
  try {
    // firebase_options.dart lo genera `flutterfire configure` (local) o el
    // CI desde un secret; no se versiona (ADR-0011).
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on Object catch (e) {
    logger.warning('push_disabled', {'reason': e.runtimeType});
    return null;
  }
  return PushNotificationsCoordinator(
    client: FirebasePushMessagingClient(),
    tokens: sl<DeviceTokenRepository>(),
    authStates: authBloc.stream,
    initialState: authBloc.state,
    navigate: (location) => router.push(location).ignore(),
    logger: logger,
    onForeground: (message, route) {
      messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 6),
            content: Text(
              [message.title, message.body].whereType<String>().join('\n'),
            ),
            action: route == null
                ? null
                : SnackBarAction(
                    label: 'Ver',
                    onPressed: () => router.push(route).ignore(),
                  ),
          ),
        );
    },
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
