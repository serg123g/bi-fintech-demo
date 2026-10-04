import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../design_system/app_theme.dart';
import '../../domain/entities/account.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({required this.account, this.onTap, super.key});

  final Account account;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balance = Formatters.money(
      account.balanceCents,
      currency: account.currency,
    );
    return Card(
      key: Key('account_${account.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: onTap != null,
          label:
              '${account.type.label} ${account.numberMasked}, '
              'saldo disponible $balance',
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    account.type == AccountType.ahorros
                        ? Icons.savings_outlined
                        : Icons.account_balance_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.type.label,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        account.numberMasked,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      balance,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text('Disponible', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
