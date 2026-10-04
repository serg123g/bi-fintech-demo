import 'package:flutter/material.dart';

import '../../core/errors/failures.dart';
import '../../core/utils/formatters.dart';
import '../app_theme.dart';

/// Franja que explica qué tan frescos son los datos en pantalla.
class FreshnessBar extends StatelessWidget {
  const FreshnessBar({
    required this.updatedAt,
    required this.fromCache,
    required this.isRefreshing,
    this.failure,
    this.onRetry,
    super.key,
  });

  final DateTime? updatedAt;
  final bool fromCache;
  final bool isRefreshing;
  final AppFailure? failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final updated = updatedAt;
    final ago = updated == null ? '' : Formatters.timeAgo(updated);

    final (IconData icon, String text, Color color) = switch (this) {
      FreshnessBar(isRefreshing: true) => (
        Icons.sync,
        'Actualizando… (datos de $ago)',
        theme.colorScheme.primary,
      ),
      FreshnessBar(failure: final f?) => (
        Icons.history,
        'No pudimos actualizar. Mostrando datos de $ago.\n${f.message}',
        theme.colorScheme.error,
      ),
      FreshnessBar(fromCache: true) => (
        Icons.history,
        'Datos guardados, actualizados $ago',
        theme.colorScheme.tertiary,
      ),
      _ => (
        Icons.check_circle_outline,
        'Actualizado $ago',
        theme.colorScheme.outline,
      ),
    };

    return Semantics(
      liveRegion: true,
      child: Padding(
        key: const Key('freshness_bar'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
            ),
            if (failure != null && onRetry != null)
              TextButton(
                key: const Key('freshness_retry'),
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
          ],
        ),
      ),
    );
  }
}
