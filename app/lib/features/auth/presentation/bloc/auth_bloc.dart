import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/customer_segment.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Fuente de verdad de la sesión para toda la app (router incluido).
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthSignOutRequested>(_onSignOut);
    on<_AuthUserChanged>(_onUserChanged);
  }

  final AuthRepository _repository;
  StreamSubscription<AppUser?>? _subscription;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    await _subscription?.cancel();
    _subscription = _repository.authStateChanges().listen(
          (user) => add(_AuthUserChanged(user)),
          onError: (Object _) {},
        );
    try {
      final user = await _repository.currentUser();
      emit(user == null ? const AuthUnauthenticated() : AuthAuthenticated(user));
    } on AppFailure {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSignIn(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.signIn(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user));
    } on AppFailure catch (f) {
      emit(AuthError(f));
    }
  }

  Future<void> _onSignUp(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.signUp(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
        segment: event.segment,
      );
      emit(AuthAuthenticated(user));
    } on AppFailure catch (f) {
      emit(AuthError(f));
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _repository.signOut();
    } on AppFailure {
      // Aun si falla la revocación remota, la sesión local se descarta.
    }
    emit(const AuthUnauthenticated());
  }

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    final user = event.user;
    // Durante login/registro manda el resultado de la operación en curso.
    if (state is AuthLoading) return;
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else if (state is AuthAuthenticated) {
      // Expiración o revocación de sesión.
      emit(const AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
