import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../design_system/app_theme.dart';
import '../../domain/entities/movement.dart';

class MovementTile extends StatelessWidget {
  const MovementTile({required this.movement, this.onTap, super.key});

  final Movement movement;
  final VoidCallback? onTap;

  static const _icons = {
    MovementCategory.ingreso: Icons.south_west,
    MovementCategory.transferencia: Icons.swap_horiz,
    MovementCategory.comida: Icons.restaurant,
    MovementCategory.transporte: Icons.directions_bus,
    MovementCategory.servicios: Icons.receipt_long,
    MovementCategory.compras: Icons.shopping_bag_outlined,
    MovementCategory.salud: Icons.local_hospital_outlined,
    MovementCategory.entretenimiento: Icons.movie_outlined,
    MovementCategory.otros: Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = movement.isCredit
        ? AppColors.success
        : theme.colorScheme.onSurface;
    final amount = Formatters.money(movement.amountCents);
    return ListTile(
      key: Key('movement_${movement.id}'),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(_icons[movement.category], size: 20),
      ),
      title: Text(
        movement.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${movement.category.label} · '
        '${Formatters.shortDateTime(movement.createdAt)}',
      ),
      trailing: Text(
        movement.isCredit ? '+$amount' : amount,
        style: theme.textTheme.titleMedium?.copyWith(color: color),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    );
  }
}
