import 'dart:async';

import 'package:fintech_platform/core/logging/app_logger.dart';
import 'package:fintech_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fintech_platform/features/notifications/domain/push_message.dart';
import 'package:fintech_platform/features/notifications/domain/push_messaging_client.dart';
import 'package:fintech_platform/features/notifications/presentation/push_notifications_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';

class _FakeClient implements PushMessagingClient {
  bool permission = true;
  String? token = 'token-1';
  int deleted = 0;
  final refresh = StreamController<String>.broadcast();
  final foreground = StreamController<PushMessage>.broadcast();
  final opened = StreamController<PushMessage>.broadcast();
  PushMessage? initial;

  @override
  Future<bool> requestPermission() async => permission;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> deleteToken() async => deleted++;

  @override
  Stream<String> get onTokenRefresh => refresh.stream;

  @override
  Stream<PushMessage> get onForegroundMessage => foreground.stream;

  @override
  Stream<PushMessage> get onMessageOpenedApp => opened.stream;

  @override
  Future<PushMessage?> getInitialMessage() async => initial;

  @override
  String get platform => 'android';

  Future<void> close() async {
    await refresh.close();
    await foreground.close();
    await opened.close();
  }
}

class _FakeTokens implements DeviceTokenRepository {
  final registered = <String>[];
  bool fail = false;

  @override
  Future<void> register(String token, String platform) async {
    if (fail) throw Exception('offline');
    registered.add('$token@$platform');
  }
}

const _movementPush = PushMessage(
  title: r'Recibiste $100.00',
  body: 'Depósito · cuenta ****4821',
  data: {'account_id': 'a-1', 'movement_id': 'm-1'},
);

void main() {
  late _FakeClient client;
  late _FakeTokens tokens;
  late StreamController<AuthState> auth;
  late List<String> navigated;
  late List<(PushMessage, String?)> foreground;
  late PushNotificationsCoordinator coordinator;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    client = _FakeClient();
    tokens = _FakeTokens();
    auth = StreamController<AuthState>.broadcast();
    navigated = [];
    foreground = [];
    coordinator = PushNotificationsCoordinator(
      client: client,
      tokens: tokens,
      authStates: auth.stream,
      navigate: navigated.add,
      onForeground: (m, r) => foreground.add((m, r)),
      logger: const ConsoleLogger(),
    );
  });

  tearDown(() async {
    await coordinator.dispose();
    await client.close();
    await auth.close();
  });

  test('login registra el token del dispositivo', () async {
    auth.add(const AuthAuthenticated(testUser));
    await settle();
    expect(tokens.registered, ['token-1@android']);
  });

  test('refresh del token se vuelve a registrar', () async {
    auth.add(const AuthAuthenticated(testUser));
    await settle();
    client.refresh.add('token-2');
    await settle();
    expect(tokens.registered, ['token-1@android', 'token-2@android']);
  });

  test('sin permiso no se registra nada', () async {
    client.permission = false;
    auth.add(const AuthAuthenticated(testUser));
    await settle();
    expect(tokens.registered, isEmpty);
  });

  test('logout invalida el token y deja de escuchar refresh', () async {
    auth.add(const AuthAuthenticated(testUser));
    await settle();
    auth.add(const AuthUnauthenticated());
    await settle();
    expect(client.deleted, 1);

    client.refresh.add('token-3');
    await settle();
    expect(tokens.registered, ['token-1@android']);
  });

  test('fallo al registrar no rompe el flujo (best-effort)', () async {
    tokens.fail = true;
    auth.add(const AuthAuthenticated(testUser));
    await settle();
    expect(tokens.registered, isEmpty);
  });

  test('tocar la notificación (background) abre el detalle', () async {
    client.opened.add(_movementPush);
    await settle();
    expect(navigated, ['/accounts/a-1/movements/m-1']);
  });

  test('notificación que abrió la app cerrada (terminated)', () async {
    client.initial = _movementPush;
    await coordinator.handleInitialMessage();
    expect(navigated, ['/accounts/a-1/movements/m-1']);
  });

  test('primer plano: se muestra dentro de la app con su ruta', () async {
    client.foreground.add(_movementPush);
    await settle();
    expect(foreground.single.$2, '/accounts/a-1/movements/m-1');
    expect(navigated, isEmpty);
  });

  test('payload inválido no navega', () async {
    client.opened.add(const PushMessage(data: {'route': '/debug'}));
    await settle();
    expect(navigated, isEmpty);
  });
}
