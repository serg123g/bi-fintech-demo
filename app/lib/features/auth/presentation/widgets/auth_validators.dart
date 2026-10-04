/// Validaciones de formulario de auth (puras, testeables).
abstract final class AuthValidators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo';
    if (!_email.hasMatch(v)) return 'Correo no válido';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Ingresa tu contraseña';
    if (v.length < 8) return 'Mínimo 8 caracteres';
    return null;
  }

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < 2) return 'Ingresa tu nombre';
    return null;
  }
}
