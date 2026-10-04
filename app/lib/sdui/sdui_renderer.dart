import 'package:flutter/material.dart';

import '../core/logging/app_logger.dart';
import 'sdui_models.dart';
import 'sdui_registry.dart';

/// Renderiza un [SduiLayout] con el [SduiRegistry].
///
/// * Tipo desconocido -> se omite (compatibilidad hacia adelante).
/// * Props inválidas -> solo esa sección se omite (fallo parcial).
class SduiRenderer extends StatelessWidget {
  const SduiRenderer({
    required this.layout,
    required this.registry,
    this.logger,
    super.key,
  });

  final SduiLayout layout;
  final SduiRegistry registry;
  final AppLogger? logger;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final section in layout.sections) {
      final builder = registry[section.type];
      if (builder == null) {
        logger?.info('sdui_unknown_section', {
          'type': section.type,
          'layout': layout.layoutId,
        });
        continue;
      }
      try {
        children.add(
          KeyedSubtree(
            key: ValueKey('sdui_${section.id}'),
            child: builder(context, section),
          ),
        );
      } on Object catch (e) {
        logger?.warning('sdui_invalid_section', {
          'id': section.id,
          'type': section.type,
          'error': e.toString(),
        });
      }
    }
    return ListView(
      key: const Key('sdui_list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: children,
    );
  }
}
