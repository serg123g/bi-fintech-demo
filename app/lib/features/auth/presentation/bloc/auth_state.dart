part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Aún no sabemos si hay sesión (splash).
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Operación de login/registro/logout en curso.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final AppUser user;

  @override
  List<Object?> get props => [user];
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// La última operación falló; el usuario sigue sin sesión.
final class AuthError extends AuthState {
  const AuthError(this.failure);

  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}
