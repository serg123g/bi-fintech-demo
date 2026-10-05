import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounts/domain/entities/account.dart';
import '../../features/accounts/domain/repositories/accounts_repository.dart';
import '../../features/accounts/presentation/pages/account_detail_page.dart';
import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/accounts/presentation/pages/movement_detail_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/debug/presentation/chaos_page.dart';
import '../../features/home/domain/home_layout_repository.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/marketplace/presentation/microapp_page.dart';
import '../../sdui/sdui_action_handler.dart';
import '../cache/cache_store.dart';
import '../chaos/chaos_config.dart';
import '../config/env.dart';
import '../di/injection.dart';
import '../logging/app_logger.dart';
import '../network/resilient_executor.dart';
import 'app_routes.dart';
import 'auth_redirect.dart';
import 'stream_listenable.dart';

export 'app_routes.dart';

GoRouter buildRouter({
  required AuthBloc authBloc,
  String initialLocation = AppRoutes.home,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: initialLocation,
    refreshListenable: StreamListenable(authBloc.stream),
    redirect: (context, state) => authRedirect(authBloc.state, state.uri),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => HomePage(
          homeRepository: sl<HomeLayoutRepository>(),
          accountsRepository: sl<AccountsRepository>(),
          actions: sl<SduiActionHandler>(),
          logger: sl<AppLogger>(),
          showDebugEntry: sl<EnvConfig>().chaosPanelAvailable,
        ),
      ),
      GoRoute(
        path: AppRoutes.marketplace,
        builder: (context, state) {
          final auth = context.read<AuthBloc>().state;
          final user = auth is AuthAuthenticated ? auth.user : null;
          return MicroappPage(
            url: sl<EnvConfig>().microappUrl,
            // Solo contexto mínimo: nunca el token de sesión.
            firstName: user?.firstName ?? '',
            segment: user?.segment.name ?? 'joven',
            section: state.uri.queryParameters['section'],
            logger: sl<AppLogger>(),
            isDown: () =>
                sl<ChaosController>().state.isDown(ChaosServices.microapp),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.debug,
        redirect: (context, state) =>
            sl<EnvConfig>().chaosPanelAvailable ? null : AppRoutes.home,
        builder: (context, state) => ChaosPage(
          controller: sl<ChaosController>(),
          cache: sl<CacheStore>(),
          executor: sl<DefaultResilientExecutor>(),
        ),
      ),
      GoRoute(
        path: AppRoutes.accounts,
        builder: (context, state) =>
            AccountsPage(repository: sl<AccountsRepository>()),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final extra = state.extra;
              return AccountDetailPage(
                accountId: state.pathParameters['id']!,
                account: extra is Account ? extra : null,
                repository: sl<AccountsRepository>(),
              );
            },
            routes: [
              GoRoute(
                path: 'movements/:movementId',
                builder: (context, state) => MovementDetailPage(
                  movementId: state.pathParameters['movementId']!,
                  repository: sl<AccountsRepository>(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Ruta no encontrada: ${state.uri}'))),
  );
}
