import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_page.dart';

/// Rutas centralizadas. Las acciones SDUI de tipo `route` navegan a estos
/// paths, por eso son parte del contrato con el backend.
abstract final class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const accounts = '/accounts';
  static const marketplace = '/marketplace';
  static const debug = '/debug';
}

GoRouter buildRouter({
  String initialLocation = AppRoutes.home,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: initialLocation,
    // El redirect por estado de auth se añade en la Fase 3.
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.uri}')),
    ),
  );
}
