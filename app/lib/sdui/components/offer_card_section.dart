import 'package:flutter/material.dart';

import '../../design_system/app_theme.dart';
import '../sdui_icons.dart';
import '../sdui_models.dart';
import '../sdui_scope.dart';

Widget buildOfferCard(BuildContext context, SduiSection s) {
  final title = s.string('title');
  final body = s.string('body');
  if (title == null || body == null) {
    throw const FormatException('offer_card.title/body requeridos');
  }
  return OfferCardSection(
    id: s.id,
    title: title,
    body: body,
    icon: s.string('icon'),
    cta: s.string('cta'),
    action: s.action(),
  );
}

class OfferCardSection extends StatelessWidget {
  const OfferCardSection({
    required this.id,
    required this.title,
    required this.body,
    this.icon,
    this.cta,
    this.action,
    super.key,
  });

  final String id;
  final String title;
  final String body;
  final String? icon;
  final String? cta;
  final SduiAction? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = action;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Card(
        key: Key('sdui_offer_$id'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(SduiIcons.of(icon), color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(body),
              if (a != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        SduiScope.of(context).actions.handle(context, a),
                    child: Text(cta ?? 'Ver más'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
