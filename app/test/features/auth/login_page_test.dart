import 'package:fintech_platform/core/errors/failures.dart';
import 'package:fintech_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fintech_platform/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  late AuthBloc bloc;

  setUp(() => bloc = AuthBloc(FakeAuthRepository()));
  tearDown(() => bloc.close());

  Widget host() => MaterialApp(
        home: BlocProvider.value(value: bloc, child: const LoginPage()),
      );

  testWidgets('valida campos vacíos sin llamar al backend', (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(find.text('Ingresa tu correo'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    expect(bloc.state, const AuthInitial());
  });

  testWidgets('credenciales inválidas muestran el error de dominio',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.enterText(find.byKey(const Key('login_email')), 'joven@test.com');
    await tester.enterText(find.byKey(const Key('login_password')), 'incorrecta');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth_error')), findsOneWidget);
    expect(
      find.text(
        AuthFailure.fromReason(AuthFailureReason.invalidCredentials).message,
      ),
      findsOneWidget,
    );
  });

  testWidgets('login correcto autentica', (tester) async {
    await tester.pumpWidget(host());
    await tester.enterText(find.byKey(const Key('login_email')), 'joven@test.com');
    await tester.enterText(find.byKey(const Key('login_password')), 'Test1234!');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    expect(bloc.state, const AuthAuthenticated(testUser));
  });
}
