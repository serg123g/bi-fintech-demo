part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Restaura la sesión persistida y empieza a escuchar cambios de sesión.
final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email];
}

final class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.fullName,
    required this.segment,
  });

  final String email;
  final String password;
  final String fullName;
  final CustomerSegment segment;

  @override
  List<Object?> get props => [email, fullName, segment];
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Interno: el repositorio notificó un cambio de sesión.
final class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);

  final AppUser? user;

  @override
  List<Object?> get props => [user];
}
