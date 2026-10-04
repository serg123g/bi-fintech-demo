import 'package:flutter/material.dart';

import '../../design_system/app_theme.dart';
import '../sdui_icons.dart';
import '../sdui_models.dart';

Widget buildInsight(BuildContext context, SduiSection s) {
  final text = s.string('text');
  if (text == null) throw const FormatException('insight.text requerido');
  return InsightSection(text: text, icon: s.string('icon'));
}

class InsightSection extends StatelessWidget {
  const InsightSection({required this.text, this.icon, super.key});

  final String text;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(SduiIcons.of(icon), color: theme.colorScheme.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
