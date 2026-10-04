import 'package:fintech_platform/core/errors/failures.dart';
import 'package:fintech_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fintech_platform/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  /// El bloc se crea DENTRO del cuerpo de `testWidgets`. Si se crea en
  /// `setUp`, sus streams y microtasks quedan en la zona real (fuera del
  /// FakeAsync del tester) y `pump`/`pumpAndSettle` no los drenan: el estado
  /// se queda en AuthLoading.
  Future<AuthBloc> pumpLogin(WidgetTester tester) async {
    final bloc = AuthBloc(FakeAuthRepository());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: bloc, child: const LoginPage()),
      ),
    );
    return bloc;
  }

  Future<void> submit(WidgetTester tester, String email, String pass) async {
    await tester.enterText(find.byKey(const Key('login_email')), email);
    await tester.enterText(find.byKey(const Key('login_password')), pass);
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();
  }

  testWidgets('valida campos vacíos sin llamar al backend', (tester) async {
    final bloc = await pumpLogin(tester);
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(find.text('Ingresa tu correo'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    expect(bloc.state, const AuthInitial());
  });

  testWidgets('credenciales inválidas muestran el error de dominio', (
    tester,
  ) async {
    final bloc = await pumpLogin(tester);
    await submit(tester, 'joven@test.com', 'incorrecta');

    expect(bloc.state, isA<AuthError>());
    expect(find.byKey(const Key('auth_error')), findsOneWidget);
    expect(
      find.text(
        AuthFailure.fromReason(AuthFailureReason.invalidCredentials).message,
      ),
      findsOneWidget,
    );
  });

  testWidgets('login correcto autentica', (tester) async {
    final bloc = await pumpLogin(tester);
    await submit(tester, 'joven@test.com', 'Test1234!');

    expect(bloc.state, const AuthAuthenticated(testUser));
  });
}
