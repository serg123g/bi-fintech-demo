import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Placeholder estático (sin animación infinita: no bloquea pumpAndSettle y
/// respeta "reducir movimiento").
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.items = 4, this.itemHeight = 72});

  final int items;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Semantics(
      label: 'Cargando',
      child: ListView.separated(
        key: const Key('skeleton'),
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: items,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, _) => Container(
          height: itemHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        ),
      ),
    );
  }
}
