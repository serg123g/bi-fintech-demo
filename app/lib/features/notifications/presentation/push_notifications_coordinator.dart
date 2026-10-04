import 'dart:async';

import '../../../core/logging/app_logger.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../domain/push_message.dart';
import '../domain/push_messaging_client.dart';

/// Orquesta el ciclo de vida de push según la sesión:
///
/// * Login -> pide permiso, registra el token y escucha su refresh.
/// * Logout -> invalida el token del dispositivo (FCM). Así no llegan pushes
///   del usuario anterior; `send-push` limpia el token huérfano al recibir
///   UNREGISTERED.
/// * Notificación tocada (background / terminated) -> navega al detalle.
/// * Notificación en primer plano -> se muestra dentro de la app.
class PushNotificationsCoordinator {
  PushNotificationsCoordinator({
    required PushMessagingClient client,
    required DeviceTokenRepository tokens,
    required Stream<AuthState> authStates,
    required void Function(String location) navigate,
    required void Function(PushMessage message, String? route) onForeground,
    required AppLogger logger,
    AuthState? initialState,
  }) : _client = client,
       _tokens = tokens,
       _navigate = navigate,
       _onForeground = onForeground,
       _logger = logger {
    _subs
      ..add(authStates.listen(_onAuth))
      ..add(client.onMessageOpenedApp.listen(_open))
      ..add(
        client.onForegroundMessage.listen(
          (m) => _onForeground(m, routeFromPush(m.data)),
        ),
      );
    // La sesión pudo resolverse antes de crear el coordinador.
    if (initialState != null) _onAuth(initialState).ignore();
  }

  final PushMessagingClient _client;
  final DeviceTokenRepository _tokens;
  final void Function(String) _navigate;
  final void Function(PushMessage, String?) _onForeground;
  final AppLogger _logger;
  final List<StreamSubscription<Object?>> _subs = [];
  StreamSubscription<String>? _refreshSub;
  String? _userId;

  /// Notificación que abrió la app desde cerrada. Llamar una vez al arrancar.
  Future<void> handleInitialMessage() async {
    final m = await _client.getInitialMessage();
    if (m != null) _open(m);
  }

  void _open(PushMessage m) {
    final route = routeFromPush(m.data);
    _logger.info('push_opened', {'route': route ?? 'invalid'});
    // Si no hay sesión, el redirect de auth guarda la ruta en ?from= y la
    // retoma tras el login.
    if (route != null) _navigate(route);
  }

  Future<void> _onAuth(AuthState state) async {
    switch (state) {
      case AuthAuthenticated(:final user) when user.id != _userId:
        _userId = user.id;
        await _registerDevice();
      case AuthUnauthenticated() when _userId != null:
        _userId = null;
        await _refreshSub?.cancel();
        _refreshSub = null;
        await _safe('push_delete_token', _client.deleteToken);
      default:
        break;
    }
  }

  Future<void> _registerDevice() async {
    final granted = await _client.requestPermission();
    if (!granted) {
      _logger.warning('push_permission_denied');
      return;
    }
    final token = await _client.getToken();
    if (token != null) await _register(token);
    await _refreshSub?.cancel();
    _refreshSub = _client.onTokenRefresh.listen((t) => _register(t).ignore());
  }

  Future<void> _register(String token) => _safe(
    'push_register_token',
    () => _tokens.register(token, _client.platform),
  );

  Future<void> _safe(String op, Future<void> Function() body) async {
    try {
      await body();
      _logger.info(op);
    } on Object catch (e) {
      // Push es best-effort: nunca debe romper el login ni el logout.
      _logger.warning('${op}_failed', {'error': e.runtimeType});
    }
  }

  Future<void> dispose() async {
    await _refreshSub?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
  }
}
