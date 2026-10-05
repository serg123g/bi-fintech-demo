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
  static const assistant = '/assistant';

  static String account(String id) => '$accounts/$id';

  /// Destino del deep link de notificaciones push.
  static String movement(String accountId, String movementId) =>
      '$accounts/$accountId/movements/$movementId';

  /// Rutas accesibles sin sesión.
  static const public = {login, onboarding};
}
