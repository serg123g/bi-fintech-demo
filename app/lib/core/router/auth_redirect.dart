import '../../features/auth/presentation/bloc/auth_bloc.dart';
import 'app_routes.dart';

/// Regla de navegación según la sesión (función pura, testeada).
///
/// * Sin resolver la sesión -> splash.
/// * Sin sesión en ruta protegida -> login, recordando el destino en `from`
///   (necesario para deep links de notificaciones push).
/// * Con sesión en login/onboarding/splash -> destino recordado o home.
String? authRedirect(AuthState state, Uri uri) {
  final path = uri.path;
  final isPublic = AppRoutes.public.contains(path);
  final isSplash = path == AppRoutes.splash;
  final from = uri.queryParameters['from'];

  String withFrom(String target) {
    if (isPublic || isSplash) {
      return from == null ? target : _withQuery(target, from);
    }
    if (path == AppRoutes.home) return target;
    return _withQuery(target, uri.toString());
  }

  return switch (state) {
    AuthInitial() => isSplash ? null : withFrom(AppRoutes.splash),
    AuthAuthenticated() =>
      (isPublic || isSplash) ? _safeFrom(from) ?? AppRoutes.home : null,
    AuthLoading() || AuthUnauthenticated() || AuthError() =>
      isPublic ? null : withFrom(AppRoutes.login),
  };
}

String _withQuery(String target, String from) =>
    Uri(path: target, queryParameters: {'from': from}).toString();

/// Solo se aceptan rutas internas (evita open redirects).
String? _safeFrom(String? from) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return null;
  }
  final path = Uri.parse(from).path;
  if (AppRoutes.public.contains(path) || path == AppRoutes.splash) return null;
  return from;
}
