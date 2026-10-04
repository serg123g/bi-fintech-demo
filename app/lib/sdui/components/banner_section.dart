import 'package:flutter/material.dart';

import '../../design_system/app_theme.dart';
import '../sdui_icons.dart';
import '../sdui_models.dart';
import '../sdui_scope.dart';

Widget buildBanner(BuildContext context, SduiSection s) {
  final title = s.string('title');
  if (title == null) throw const FormatException('banner.title requerido');
  return BannerSection(
    id: s.id,
    title: title,
    subtitle: s.string('subtitle'),
    icon: s.string('icon'),
    warning: s.string('style') == 'warning',
    action: s.action(),
  );
}

class BannerSection extends StatelessWidget {
  const BannerSection({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon,
    this.warning = false,
    this.action,
    super.key,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? icon;
  final bool warning;
  final SduiAction? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = warning ? scheme.tertiaryContainer : scheme.secondaryContainer;
    final fg = warning
        ? scheme.onTertiaryContainer
        : scheme.onSecondaryContainer;
    final a = action;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Material(
        key: Key('sdui_banner_$id'),
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: a == null
              ? null
              : () => SduiScope.of(context).actions.handle(context, a),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(SduiIcons.of(icon), color: fg, size: 32),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: fg),
                      ),
                      if (subtitle case final sub?)
                        Text(sub, style: TextStyle(color: fg)),
                    ],
                  ),
                ),
                if (a != null) Icon(Icons.chevron_right, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
