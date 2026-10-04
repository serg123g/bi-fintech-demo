import '../entities/app_user.dart';
import '../entities/customer_segment.dart';

/// Contrato de autenticación. La implementación concreta (Supabase) vive en
/// `data/`; Bloc y tests dependen solo de esta interfaz.
///
/// Todos los métodos lanzan `AppFailure` (nunca excepciones del SDK).
abstract interface class AuthRepository {
  /// Usuario con sesión restaurada al arrancar, o `null`.
  Future<AppUser?> currentUser();

  /// Emite en cada cambio de sesión (login, logout, expiración, refresh).
  Stream<AppUser?> authStateChanges();

  Future<AppUser> signIn({required String email, required String password});

  /// Registro. El backend crea el perfil y una cuenta de ahorros
  /// (trigger `handle_new_user`) a partir de `fullName` y `segment`.
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
    required CustomerSegment segment,
  });

  Future<void> signOut();
}
