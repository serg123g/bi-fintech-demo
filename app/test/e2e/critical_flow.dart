import 'package:fintech_platform/app.dart';
import 'package:fintech_platform/core/cache/cache_store.dart';
import 'package:fintech_platform/core/config/env.dart';
import 'package:fintech_platform/core/di/injection.dart';
import 'package:fintech_platform/core/errors/failures.dart';
import 'package:fintech_platform/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:fintech_platform/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fintech_platform/features/home/data/home_layout_remote_data_source.dart';
import 'package:fintech_platform/features/home/data/home_layout_repository_impl.dart';
import 'package:fintech_platform/features/home/domain/home_layout_repository.dart';
import 'package:fintech_platform/sdui/sdui_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_accounts_repository.dart';
import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_home_layout_repository.dart';

/// Escenarios E2E compartidos entre:
/// * `test/e2e/critical_flow_test.dart` (VM, corre en cada push en CI), y
/// * `integration_test/app_e2e_test.dart` (emulador/dispositivo real).
///
/// La app se arma con el composition root REAL (`configureDependencies`) y
/// solo se reemplazan los bordes (repositorios) por fakes deterministas.

const _noBackend = EnvConfig(
  supabaseUrl: '',
  supabasePublishableKey: '',
  microappUrl: '',
  enableChaosPanel: true,
);

/// Home personalizado de Ana (segmento joven, saldo bajo) tal como lo
/// devolvería la Edge Function `home-layout`.
const anaHomeLayout = SduiLayout(
  version: 1,
  layoutId: 'home-joven-v1',
  sections: [
    SduiSection(
      id: 'greeting',
      type: 'greeting',
      data: {'text': 'Buenas tardes, {first_name}', 'subtitle': 'Tu dinero'},
    ),
    SduiSection(id: 'accounts', type: 'accounts_summary'),
    SduiSection(
      id: 'emergency_fund',
      type: 'banner',
      data: {
        'style': 'warning',
        'title': 'Arma tu fondo de emergencia',
        'action': {'type': 'route', 'value': '/accounts'},
      },
    ),
    SduiSection(
      id: 'quick_actions',
      type: 'quick_actions',
      data: {
        'items': [
          {
            'icon': 'account_balance_wallet',
            'label': 'Mis cuentas',
            'action': {'type': 'route', 'value': '/accounts'},
          },
        ],
      },
    ),
  ],
);

class _DownHomeRemote implements HomeLayoutRemoteDataSource {
  @override
  Future<Map<String, dynamic>> fetchLayout() async =>
      throw const ServiceUnavailableFailure('home-layout');
}

Future<AuthBloc> pumpE2EApp(
  WidgetTester tester, {
  HomeLayoutRepository? home,
}) async {
  await configureDependencies(
    env: _noBackend,
    overrides: (sl) => sl
      ..registerSingleton<AuthRepository>(FakeAuthRepository())
      ..registerSingleton<AccountsRepository>(FakeAccountsRepository())
      ..registerSingleton<HomeLayoutRepository>(
        home ?? FakeHomeLayoutRepository(anaHomeLayout),
      ),
  );
  addTearDown(sl.reset);

  final authBloc = sl<AuthBloc>()..add(const AuthStarted());
  await tester.pumpWidget(FintechApp(authBloc: authBloc));
  await tester.pumpAndSettle();
  return authBloc;
}

Future<void> _login(
  WidgetTester tester, {
  String password = 'Test1234!',
}) async {
  await tester.enterText(
    find.byKey(const Key('login_email')),
    'joven@test.com',
  );
  await tester.enterText(find.byKey(const Key('login_password')), password);
  await tester.tap(find.byKey(const Key('login_submit')));
  await tester.pumpAndSettle();
}

Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Flujo crítico: login -> home personalizado -> cuentas -> detalle de
/// cuenta -> movimientos -> detalle de movimiento -> logout.
Future<void> runCriticalFlow(WidgetTester tester) async {
  await pumpE2EApp(tester);

  // 1. Sin sesión -> login. Credenciales inválidas muestran error de dominio.
  expect(find.byKey(const Key('login_submit')), findsOneWidget);
  await _login(tester, password: 'incorrecta');
  expect(find.byKey(const Key('auth_error')), findsOneWidget);

  // 2. Login correcto -> home personalizado vía SDUI.
  await _login(tester);
  expect(find.text('Buenas tardes, Ana'), findsOneWidget);
  expect(find.text('Arma tu fondo de emergencia'), findsOneWidget);
  expect(find.byKey(const Key('sdui_accounts_summary')), findsOneWidget);

  // 3. Acceso rápido -> Mis cuentas.
  await _tapAndSettle(tester, find.byKey(const Key('sdui_quick_Mis cuentas')));
  expect(find.text('Mis cuentas'), findsWidgets);
  expect(find.byKey(const Key('account_a1')), findsOneWidget);
  expect(find.byKey(const Key('accounts_total')), findsOneWidget);

  // 4. Detalle de cuenta -> movimientos.
  await _tapAndSettle(tester, find.byKey(const Key('account_a1')));
  expect(find.byKey(const Key('movement_m1')), findsOneWidget);
  expect(find.text(r'-$45.30'), findsOneWidget);

  // 5. Detalle del movimiento (mismo destino que el deep link de push).
  await _tapAndSettle(tester, find.byKey(const Key('movement_m1')));
  expect(find.byKey(const Key('movement_detail_m1')), findsOneWidget);
  expect(find.text('Supermercado Santa María'), findsOneWidget);

  // 6. Volver al home y cerrar sesión -> login.
  for (var i = 0; i < 3; i++) {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }
  expect(find.text('Buenas tardes, Ana'), findsOneWidget);
  await _tapAndSettle(tester, find.byKey(const Key('logout_button')));
  expect(find.byKey(const Key('login_submit')), findsOneWidget);
}

/// Flujo degradado: `home-layout` caído y sin cache -> el home se arma con el
/// layout empaquetado (repositorio REAL + asset real) y el saldo sigue
/// disponible.
Future<void> runDegradedHomeFlow(WidgetTester tester) async {
  await pumpE2EApp(
    tester,
    home: HomeLayoutRepositoryImpl(
      remote: _DownHomeRemote(),
      cache: InMemoryCacheStore(),
      currentUserId: () => 'u-joven',
      loadFallback: () =>
          rootBundle.loadString('assets/sdui/home_fallback.json'),
    ),
  );
  await _login(tester);

  expect(find.text('Hola, Ana'), findsOneWidget);
  expect(find.text('Estamos mostrando una versión básica'), findsOneWidget);
  expect(find.byKey(const Key('sdui_accounts_summary')), findsOneWidget);
  expect(find.textContaining('No pudimos actualizar'), findsOneWidget);
}
