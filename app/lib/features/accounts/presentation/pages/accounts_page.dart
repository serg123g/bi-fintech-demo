import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/resource_state.dart';
import '../../../../core/presentation/swr_bloc.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../design_system/app_theme.dart';
import '../../../../design_system/widgets/resource_view.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/accounts_repository.dart';
import '../bloc/accounts_bloc.dart';
import '../widgets/account_card.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({required this.repository, super.key});

  final AccountsRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AccountsBloc(repository)..add(const ResourceRequested()),
      child: const _AccountsView(),
    );
  }
}

class _AccountsView extends StatelessWidget {
  const _AccountsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis cuentas')),
      body: BlocBuilder<AccountsBloc, ResourceState<List<Account>>>(
        builder: (context, state) => ResourceView<List<Account>>(
          state: state,
          onRetry: () =>
              context.read<AccountsBloc>().add(const ResourceRequested()),
          builder: (context, accounts) => _AccountsList(accounts: accounts),
        ),
      ),
    );
  }
}

class _AccountsList extends StatelessWidget {
  const _AccountsList({required this.accounts});

  final List<Account> accounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = accounts.fold<int>(0, (sum, a) => sum + a.balanceCents);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Saldo total', style: theme.textTheme.titleSmall),
        Text(
          Formatters.money(total),
          key: const Key('accounts_total'),
          style: theme.textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        if (accounts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Text('Aún no tienes cuentas.'),
          ),
        for (final a in accounts)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AccountCard(
              account: a,
              onTap: () => context.push(AppRoutes.account(a.id), extra: a),
            ),
          ),
      ],
    );
  }
}
