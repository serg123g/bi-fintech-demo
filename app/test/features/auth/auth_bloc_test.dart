import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fintech_platform/core/errors/failures.dart';
import 'package:fintech_platform/features/auth/domain/entities/app_user.dart';
import 'package:fintech_platform/features/auth/domain/entities/customer_segment.dart';
import 'package:fintech_platform/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_auth_repository.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;
  late StreamController<AppUser?> changes;

  final invalid = AuthFailure.fromReason(AuthFailureReason.invalidCredentials);

  setUpAll(() => registerFallbackValue(CustomerSegment.joven));

  setUp(() {
    repo = _MockAuthRepository();
    changes = StreamController<AppUser?>.broadcast();
    when(() => repo.authStateChanges()).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  test('estado inicial es AuthInitial', () {
    expect(AuthBloc(repo).state, const AuthInitial());
  });

  group('AuthStarted', () {
    blocTest<AuthBloc, AuthState>(
      'con sesión persistida emite Authenticated',
      build: () {
        when(() => repo.currentUser()).thenAnswer((_) async => testUser);
        return AuthBloc(repo);
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [const AuthAuthenticated(testUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'sin sesión emite Unauthenticated',
      build: () {
        when(() => repo.currentUser()).thenAnswer((_) async => null);
        return AuthBloc(repo);
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'si la sesión expira (stream emite null) vuelve a Unauthenticated',
      build: () {
        when(() => repo.currentUser()).thenAnswer((_) async => testUser);
        return AuthBloc(repo);
      },
      act: (bloc) async {
        bloc.add(const AuthStarted());
        await Future<void>.delayed(Duration.zero);
        changes.add(null);
      },
      expect: () => [
        const AuthAuthenticated(testUser),
        const AuthUnauthenticated(),
      ],
    );
  });

  group('AuthSignInRequested', () {
    blocTest<AuthBloc, AuthState>(
      'credenciales válidas: Loading -> Authenticated',
      build: () {
        when(
          () => repo.signIn(email: 'joven@test.com', password: 'Test1234!'),
        ).thenAnswer((_) async => testUser);
        return AuthBloc(repo);
      },
      act: (bloc) => bloc.add(
        const AuthSignInRequested(
          email: 'joven@test.com',
          password: 'Test1234!',
        ),
      ),
      expect: () => [const AuthLoading(), const AuthAuthenticated(testUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'credenciales inválidas: Loading -> Error con el fallo de dominio',
      build: () {
        when(
          () => repo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(invalid);
        return AuthBloc(repo);
      },
      act: (bloc) => bloc.add(
        const AuthSignInRequested(email: 'x@test.com', password: 'wrong123'),
      ),
      expect: () => [const AuthLoading(), AuthError(invalid)],
    );

    blocTest<AuthBloc, AuthState>(
      'sin red: Loading -> Error(NetworkFailure)',
      build: () {
        when(
          () => repo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const NetworkFailure());
        return AuthBloc(repo);
      },
      act: (bloc) => bloc.add(
        const AuthSignInRequested(email: 'x@test.com', password: 'Test1234!'),
      ),
      expect: () => [const AuthLoading(), const AuthError(NetworkFailure())],
    );
  });

  group('AuthSignUpRequested', () {
    const newUser = AppUser(
      id: 'u-new',
      email: 'nuevo@test.com',
      fullName: 'Nuevo Cliente',
      segment: CustomerSegment.pyme,
    );

    blocTest<AuthBloc, AuthState>(
      'registra con el segmento elegido',
      build: () {
        when(
          () => repo.signUp(
            email: 'nuevo@test.com',
            password: 'Test1234!',
            fullName: 'Nuevo Cliente',
            segment: CustomerSegment.pyme,
          ),
        ).thenAnswer((_) async => newUser);
        return AuthBloc(repo);
      },
      act: (bloc) => bloc.add(
        const AuthSignUpRequested(
          email: 'nuevo@test.com',
          password: 'Test1234!',
          fullName: 'Nuevo Cliente',
          segment: CustomerSegment.pyme,
        ),
      ),
      expect: () => [const AuthLoading(), const AuthAuthenticated(newUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'correo ya registrado: Error',
      build: () {
        when(
          () => repo.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
            segment: any(named: 'segment'),
          ),
        ).thenThrow(
          AuthFailure.fromReason(AuthFailureReason.emailAlreadyRegistered),
        );
        return AuthBloc(repo);
      },
      act: (bloc) => bloc.add(
        const AuthSignUpRequested(
          email: 'joven@test.com',
          password: 'Test1234!',
          fullName: 'Ana',
          segment: CustomerSegment.joven,
        ),
      ),
      expect: () => [
        const AuthLoading(),
        AuthError(
          AuthFailure.fromReason(AuthFailureReason.emailAlreadyRegistered),
        ),
      ],
    );
  });

  group('AuthSignOutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'cierra sesión aunque falle la revocación remota',
      build: () {
        when(() => repo.signOut()).thenThrow(const NetworkFailure());
        return AuthBloc(repo);
      },
      seed: () => const AuthAuthenticated(testUser),
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => [const AuthLoading(), const AuthUnauthenticated()],
    );
  });
}
