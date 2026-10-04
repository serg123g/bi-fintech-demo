import 'package:equatable/equatable.dart';

/// Errores de dominio. Las capas `data` traducen excepciones de SDKs
/// (Supabase, Dio, plataforma) a estos tipos; la UI nunca ve excepciones crudas.
sealed class AppFailure extends Equatable implements Exception {
  const AppFailure(this.message);

  /// Mensaje apto para mostrar al usuario (es-EC).
  final String message;

  @override
  List<Object?> get props => [runtimeType, message];
}

/// Sin conectividad, timeout o servicio inalcanzable. Reintentable.
class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message =
        'No pudimos conectarnos. Revisa tu conexión e inténtalo de nuevo.',
  ]);
}

/// Error del servidor (5xx, respuesta inválida). Reintentable con backoff.
class ServerFailure extends AppFailure {
  const ServerFailure([
    super.message = 'El servicio no está disponible en este momento.',
  ]);
}

enum AuthFailureReason {
  invalidCredentials,
  emailAlreadyRegistered,
  weakPassword,
  emailNotConfirmed,
  rateLimited,
  sessionExpired,
  unknown,
}

class AuthFailure extends AppFailure {
  const AuthFailure(this.reason, String message) : super(message);

  factory AuthFailure.fromReason(
    AuthFailureReason reason,
  ) => AuthFailure(reason, switch (reason) {
    AuthFailureReason.invalidCredentials => 'Correo o contraseña incorrectos.',
    AuthFailureReason.emailAlreadyRegistered =>
      'Ya existe una cuenta con este correo.',
    AuthFailureReason.weakPassword =>
      'La contraseña es muy débil. Usa al menos 8 caracteres.',
    AuthFailureReason.emailNotConfirmed => 'Confirma tu correo para continuar.',
    AuthFailureReason.rateLimited =>
      'Demasiados intentos. Espera un momento e inténtalo de nuevo.',
    AuthFailureReason.sessionExpired =>
      'Tu sesión expiró. Inicia sesión nuevamente.',
    AuthFailureReason.unknown =>
      'No pudimos completar la operación. Inténtalo de nuevo.',
  });

  final AuthFailureReason reason;

  @override
  List<Object?> get props => [reason, message];
}

class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure([super.message = 'Ocurrió un error inesperado.']);
}
