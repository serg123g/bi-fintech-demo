import 'package:fintech_platform/app.dart';
import 'package:fintech_platform/core/config/env.dart';
import 'package:fintech_platform/core/di/injection.dart';
import 'package:fintech_platform/core/logging/app_logger.dart';
import 'package:fintech_platform/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:fintech_platform/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fintech_platform/features/home/domain/home_layout_repository.dart';
import 'package:fintech_platform/sdui/sdui_action_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_accounts_repository.dart';
import 'helpers/fake_auth_repository.dart';
import 'helpers/fake_home_layout_repository.dart';

const _noBackend = EnvConfig(
  supabaseUrl: '',
  supabasePublishableKey: '',
  microappUrl: '',
  enableChaosPanel: false,
);

void main() {
  test('DI registra configuración, logger y AuthBloc', () async {
    await configureDependencies(
      env: _noBackend,
      overrides: (sl) =>
          sl.registerSingleton<AuthRepository>(FakeAuthRepository()),
    );
    // Se resetea en la misma zona (real) donde se creó el bloc.
    addTearDown(sl.reset);

    expect(sl.isRegistered<EnvConfig>(), isTrue);
    expect(sl.isRegistered<AppLogger>(), isTrue);
    expect(sl<EnvConfig>().hasBackend, isFalse);
    expect(sl<AuthBloc>(), isA<AuthBloc>());
  });

  // Los widget tests NO pasan por GetIt: el bloc se crea dentro de la zona
  // FakeAsync de testWidgets. Un bloc creado fuera de ella (o un `await
  // sl.reset()` que cierra blocs de otra zona) deja futures que pump() nunca
  // drena y el test se cuelga.
  Future<void> pumpApp(WidgetTester tester, FakeAuthRepository repo) async {
    // El router resuelve las páginas desde GetIt: registros síncronos y sin
    // disposables, para que el reset no deje futures fuera de la zona.
    sl
      ..registerSingleton<HomeLayoutRepository>(FakeHomeLayoutRepository())
      ..registerSingleton<AccountsRepository>(FakeAccountsRepository())
      ..registerSingleton<SduiActionHandler>(
        const SduiActionHandler(logger: ConsoleLogger()),
      )
      ..registerSingleton<AppLogger>(const ConsoleLogger());
    addTearDown(sl.reset);
    final bloc = AuthBloc(repo)..add(const AuthStarted());
    addTearDown(bloc.close);
    await tester.pumpWidget(FintechApp(authBloc: bloc));
    await tester.pumpAndSettle();
  }

  testWidgets('sin sesión la app termina en login', (tester) async {
    await pumpApp(tester, FakeAuthRepository());
    expect(find.byKey(const Key('login_submit')), findsOneWidget);
  });

  testWidgets('con sesión restaurada la app abre el home', (tester) async {
    await pumpApp(tester, FakeAuthRepository(initialUser: testUser));
    expect(find.text('Hola, Ana'), findsOneWidget);
  });
}
