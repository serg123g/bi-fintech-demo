import 'package:flutter/material.dart';

import '../../design_system/app_theme.dart';
import '../sdui_models.dart';
import '../sdui_scope.dart';

Widget buildGreeting(BuildContext context, SduiSection s) {
  final text = s.string('text');
  if (text == null) throw const FormatException('greeting.text requerido');
  return GreetingSection(text: text, subtitle: s.string('subtitle'));
}

class GreetingSection extends StatelessWidget {
  const GreetingSection({required this.text, this.subtitle, super.key});

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final env = SduiScope.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            env.interpolate(text),
            key: const Key('sdui_greeting'),
            style: theme.textTheme.headlineSmall,
          ),
          if (subtitle case final sub?)
            Text(sub, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
