import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/presentation/resource_state.dart';
import '../../../core/presentation/swr_bloc.dart';
import '../../../design_system/widgets/resource_view.dart';
import '../../../sdui/sdui_action_handler.dart';
import '../../../sdui/sdui_models.dart';
import '../../../sdui/sdui_registry.dart';
import '../../../sdui/sdui_renderer.dart';
import '../../../sdui/sdui_scope.dart';
import '../../accounts/domain/repositories/accounts_repository.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../domain/home_layout_repository.dart';
import 'home_bloc.dart';

/// Home 100 % server-driven: el contenido y su orden los decide la Edge
/// Function `home-layout` según el perfil del cliente.
class HomePage extends StatelessWidget {
  const HomePage({
    required this.homeRepository,
    required this.accountsRepository,
    required this.actions,
    this.registry,
    this.logger,
    super.key,
  });

  final HomeLayoutRepository homeRepository;
  final AccountsRepository accountsRepository;
  final SduiActionHandler actions;
  final SduiRegistry? registry;
  final AppLogger? logger;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final firstName = auth is AuthAuthenticated ? auth.user.firstName : '';
    final reg = registry ?? SduiRegistry.defaults();

    return BlocProvider(
      create: (_) => HomeBloc(homeRepository)..add(const ResourceRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inicio'),
          actions: [
            IconButton(
              key: const Key('logout_button'),
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout),
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthSignOutRequested()),
            ),
          ],
        ),
        body: SduiScope(
          environment: SduiEnvironment(
            firstName: firstName,
            accounts: accountsRepository,
            actions: actions,
          ),
          child: BlocBuilder<HomeBloc, ResourceState<SduiLayout>>(
            builder: (context, state) => ResourceView<SduiLayout>(
              state: state,
              skeletonItems: 5,
              onRetry: () =>
                  context.read<HomeBloc>().add(const ResourceRequested()),
              builder: (context, layout) =>
                  SduiRenderer(layout: layout, registry: reg, logger: logger),
            ),
          ),
        ),
      ),
    );
  }
}
