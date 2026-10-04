/// Rutas centralizadas. Las acciones SDUI de tipo `route` navegan a estos
/// paths, por eso son parte del contrato con el backend.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const home = '/';
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const accounts = '/accounts';
  static const marketplace = '/marketplace';
  static const debug = '/debug';

  /// Rutas accesibles sin sesión.
  static const public = {login, onboarding};
}
