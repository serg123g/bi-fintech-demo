import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/resource_state.dart';
import '../../../../core/presentation/swr_bloc.dart';
import '../../../../design_system/app_theme.dart';
import '../../../../design_system/widgets/resource_view.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/movement.dart';
import '../../domain/repositories/accounts_repository.dart';
import '../bloc/movements_bloc.dart';
import '../widgets/account_card.dart';
import '../widgets/movement_tile.dart';

/// Detalle de cuenta: cabecera (si llegó por navegación) + movimientos.
/// Funciona también por deep link solo con el id.
class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({
    required this.accountId,
    required this.repository,
    this.account,
    super.key,
  });

  final String accountId;
  final Account? account;
  final AccountsRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MovementsBloc(repository, accountId)..add(const ResourceRequested()),
      child: Scaffold(
        appBar: AppBar(title: Text(account?.type.label ?? 'Movimientos')),
        body: BlocBuilder<MovementsBloc, ResourceState<List<Movement>>>(
          builder: (context, state) => ResourceView<List<Movement>>(
            state: state,
            skeletonItems: 8,
            onRetry: () =>
                context.read<MovementsBloc>().add(const ResourceRequested()),
            builder: (context, movements) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (account case final a?)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: AccountCard(account: a),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  child: Text(
                    'Últimos movimientos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (movements.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Text('Sin movimientos todavía.'),
                  ),
                for (final m in movements) MovementTile(movement: m),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
