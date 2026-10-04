import 'package:flutter/material.dart';

import '../../design_system/app_theme.dart';
import '../sdui_icons.dart';
import '../sdui_models.dart';
import '../sdui_scope.dart';

typedef QuickActionItem = ({String label, String? icon, SduiAction action});

Widget buildQuickActions(BuildContext context, SduiSection s) {
  final items = <QuickActionItem>[
    for (final raw in s.list('items'))
      if (raw['label'] case final String label)
        if (SduiAction.fromJson(raw['action']) case final action?)
          (label: label, icon: raw['icon'] as String?, action: action),
  ];
  if (items.isEmpty) throw const FormatException('quick_actions sin items');
  return QuickActionsSection(items: items);
}

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({required this.items, super.key});

  final List<QuickActionItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final item in items)
            SizedBox(
              width: 84,
              child: InkWell(
                key: Key('sdui_quick_${item.label}'),
                borderRadius: BorderRadius.circular(AppRadius.card),
                onTap: () =>
                    SduiScope.of(context).actions.handle(context, item.action),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          SduiIcons.of(item.icon),
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
