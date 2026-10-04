import 'package:fintech_platform/app.dart';
import 'package:fintech_platform/core/config/env.dart';
import 'package:fintech_platform/core/di/injection.dart';
import 'package:fintech_platform/core/logging/app_logger.dart';
import 'package:fintech_platform/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_auth_repository.dart';

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
