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
  Future<void> setUpDi({FakeAuthRepository? repo}) => configureDependencies(
        env: _noBackend,
        overrides: (sl) => sl.registerSingleton<AuthRepository>(
          repo ?? FakeAuthRepository(),
        ),
      );

  test('DI registra configuración, logger y AuthBloc', () async {
    await setUpDi();
    expect(sl.isRegistered<EnvConfig>(), isTrue);
    expect(sl.isRegistered<AppLogger>(), isTrue);
    expect(sl<EnvConfig>().hasBackend, isFalse);
    expect(sl<AuthBloc>(), isA<AuthBloc>());
  });

  testWidgets('sin sesión la app termina en login', (tester) async {
    await setUpDi();
    await tester.pumpWidget(
      FintechApp(authBloc: sl<AuthBloc>()..add(const AuthStarted())),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login_submit')), findsOneWidget);
  });

  testWidgets('con sesión restaurada la app abre el home', (tester) async {
    await setUpDi(repo: FakeAuthRepository(initialUser: testUser));
    await tester.pumpWidget(
      FintechApp(authBloc: sl<AuthBloc>()..add(const AuthStarted())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hola, Ana'), findsOneWidget);
  });
}
