import 'package:fintech_platform/core/cache/data_result.dart';
import 'package:fintech_platform/core/errors/failures.dart';
import 'package:fintech_platform/features/accounts/domain/entities/account.dart';
import 'package:fintech_platform/features/accounts/presentation/pages/account_detail_page.dart';
import 'package:fintech_platform/features/accounts/presentation/pages/accounts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_accounts_repository.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: child);

  testWidgets('muestra cuentas y saldo total', (tester) async {
    await tester.pumpWidget(
      host(AccountsPage(repository: FakeAccountsRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('account_a1')), findsOneWidget);
    expect(find.byKey(const Key('account_a2')), findsOneWidget);
    expect(find.text(r'$4,473.21'), findsOneWidget); // 60.81 + 4412.40
  });

  testWidgets('error sin cache muestra reintentar y recupera', (tester) async {
    final repo = FakeAccountsRepository(
      accountsScripts: [
        [const NetworkFailure()],
        [
          DataResult<List<Account>>(
            testAccounts,
            DataSource.network,
            seedUpdatedAt,
          ),
        ],
      ],
    );
    await tester.pumpWidget(host(AccountsPage(repository: repo)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('retry_button')), findsOneWidget);
    expect(find.text(const NetworkFailure().message), findsOneWidget);

    await tester.tap(find.byKey(const Key('retry_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('account_a1')), findsOneWidget);
    expect(repo.accountsCalls, 2);
  });

  testWidgets('red caída con cache: datos guardados + aviso', (tester) async {
    final repo = FakeAccountsRepository(
      accountsScripts: [
        [
          DataResult<List<Account>>(
            testAccounts,
            DataSource.cache,
            DateTime.now().subtract(const Duration(minutes: 12)),
          ),
          const NetworkFailure(),
        ],
      ],
    );
    await tester.pumpWidget(host(AccountsPage(repository: repo)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('account_a1')), findsOneWidget);
    expect(find.textContaining('No pudimos actualizar'), findsOneWidget);
    expect(find.textContaining('hace 12 min'), findsOneWidget);
    expect(find.byKey(const Key('freshness_retry')), findsOneWidget);
  });

  testWidgets('detalle de cuenta lista movimientos', (tester) async {
    await tester.pumpWidget(
      host(
        AccountDetailPage(
          accountId: 'a1',
          account: testAccounts.first,
          repository: FakeAccountsRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('movement_m1')), findsOneWidget);
    expect(find.text(r'-$45.30'), findsOneWidget);
    expect(find.text(r'+$250.00'), findsOneWidget);
  });
}
