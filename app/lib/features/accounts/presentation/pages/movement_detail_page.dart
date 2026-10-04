import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/resource_state.dart';
import '../../../../core/presentation/swr_bloc.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../design_system/app_theme.dart';
import '../../../../design_system/widgets/resource_view.dart';
import '../../domain/entities/movement.dart';
import '../../domain/repositories/accounts_repository.dart';
import '../bloc/movement_detail_bloc.dart';

/// Detalle de un movimiento. Es el destino del deep link de las
/// notificaciones push: funciona solo con el id (abre en frío).
class MovementDetailPage extends StatelessWidget {
  const MovementDetailPage({
    required this.movementId,
    required this.repository,
    super.key,
  });

  final String movementId;
  final AccountsRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MovementDetailBloc(repository, movementId)
            ..add(const ResourceRequested()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Detalle del movimiento')),
        body: BlocBuilder<MovementDetailBloc, ResourceState<Movement>>(
          builder: (context, state) => ResourceView<Movement>(
            state: state,
            skeletonItems: 3,
            onRetry: () => context.read<MovementDetailBloc>().add(
              const ResourceRequested(),
            ),
            builder: (context, m) => _Detail(movement: m),
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.movement});

  final Movement movement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = Formatters.money(movement.amountCents);
    return ListView(
      key: Key('movement_detail_${movement.id}'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          movement.isCredit ? '+$amount' : amount,
          style: theme.textTheme.displaySmall?.copyWith(
            color: movement.isCredit ? AppColors.success : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(movement.description, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.lg),
        _Row(label: 'Categoría', value: movement.category.label),
        _Row(
          label: 'Fecha',
          value: Formatters.shortDateTime(movement.createdAt),
        ),
        _Row(label: 'Tipo', value: movement.isCredit ? 'Crédito' : 'Débito'),
        _Row(label: 'Referencia', value: movement.id.split('-').first),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: Text(value, style: Theme.of(context).textTheme.bodyLarge),
  );
}
