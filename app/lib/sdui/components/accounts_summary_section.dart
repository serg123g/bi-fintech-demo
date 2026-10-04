import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/presentation/resource_state.dart';
import '../../core/presentation/swr_bloc.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../design_system/app_theme.dart';
import '../../features/accounts/domain/entities/account.dart';
import '../../features/accounts/presentation/bloc/accounts_bloc.dart';
import '../sdui_models.dart';
import '../sdui_scope.dart';

Widget buildAccountsSummary(BuildContext context, SduiSection s) =>
    const AccountsSummarySection();

/// Sección con datos propios: carga las cuentas con su propio bloc. Si falla,
/// solo esta tarjeta muestra el error (fallo parcial); el resto del home
/// sigue funcionando.
class AccountsSummarySection extends StatelessWidget {
  const AccountsSummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    final env = SduiScope.of(context);
    return BlocProvider(
      create: (_) => AccountsBloc(env.accounts)..add(const ResourceRequested()),
      child: BlocBuilder<AccountsBloc, ResourceState<List<Account>>>(
        builder: (context, state) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: _content(context, state),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, ResourceState<List<Account>> state) {
    final theme = Theme.of(context);
    final accounts = state.data;
    if (accounts == null) {
      if (state.status == ResourceStatus.failure) {
        return Card(
          key: const Key('sdui_accounts_error'),
          child: ListTile(
            leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
            title: const Text('No pudimos cargar tus saldos'),
            trailing: TextButton(
              onPressed: () =>
                  context.read<AccountsBloc>().add(const ResourceRequested()),
              child: const Text('Reintentar'),
            ),
          ),
        );
      }
      return Container(
        key: const Key('sdui_accounts_loading'),
        height: 96,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      );
    }

    final total = accounts.fold<int>(0, (sum, a) => sum + a.balanceCents);
    final saved = state.fromCache || state.failure != null;
    return Card(
      key: const Key('sdui_accounts_summary'),
      color: theme.colorScheme.primary,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => SduiScope.of(
          context,
        ).actions.handle(context, const RouteAction(AppRoutes.accounts)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo disponible',
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
              Text(
                Formatters.money(total),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${accounts.length} '
                '${accounts.length == 1 ? 'cuenta' : 'cuentas'}'
                '${saved ? ' · datos guardados' : ''}',
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
