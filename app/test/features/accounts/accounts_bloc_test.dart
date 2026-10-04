import 'package:bloc_test/bloc_test.dart';
import 'package:fintech_platform/core/cache/data_result.dart';
import 'package:fintech_platform/core/errors/failures.dart';
import 'package:fintech_platform/core/presentation/resource_state.dart';
import 'package:fintech_platform/core/presentation/swr_bloc.dart';
import 'package:fintech_platform/features/accounts/domain/entities/account.dart';
import 'package:fintech_platform/features/accounts/presentation/bloc/accounts_bloc.dart';

import '../../helpers/fake_accounts_repository.dart';

typedef S = ResourceState<List<Account>>;

void main() {
  final cachedAt = DateTime(2026, 10, 4, 8);
  final cached = DataResult<List<Account>>(
    testAccounts.take(1).toList(),
    DataSource.cache,
    cachedAt,
  );
  final fresh = DataResult<List<Account>>(
    testAccounts,
    DataSource.network,
    seedUpdatedAt,
  );

  blocTest<AccountsBloc, S>(
    'sin cache: loading -> success con datos de red',
    build: () => AccountsBloc(
      FakeAccountsRepository(
        accountsScripts: [
          [fresh],
        ],
      ),
    ),
    act: (b) => b.add(const ResourceRequested()),
    expect: () => [
      const S(status: ResourceStatus.loading),
      S(
        status: ResourceStatus.success,
        data: testAccounts,
        updatedAt: seedUpdatedAt,
      ),
    ],
  );

  blocTest<AccountsBloc, S>(
    'stale-while-revalidate: cache (refrescando) -> red',
    build: () => AccountsBloc(
      FakeAccountsRepository(
        accountsScripts: [
          [cached, fresh],
        ],
      ),
    ),
    act: (b) => b.add(const ResourceRequested()),
    expect: () => [
      const S(status: ResourceStatus.loading),
      S(
        status: ResourceStatus.success,
        data: cached.data,
        updatedAt: cachedAt,
        fromCache: true,
        isRefreshing: true,
      ),
      S(
        status: ResourceStatus.success,
        data: testAccounts,
        updatedAt: seedUpdatedAt,
      ),
    ],
  );

  blocTest<AccountsBloc, S>(
    'red caída con cache: conserva datos guardados y expone el fallo',
    build: () => AccountsBloc(
      FakeAccountsRepository(
        accountsScripts: [
          [cached, const NetworkFailure()],
        ],
      ),
    ),
    act: (b) => b.add(const ResourceRequested()),
    skip: 2,
    expect: () => [
      S(
        status: ResourceStatus.success,
        data: cached.data,
        updatedAt: cachedAt,
        fromCache: true,
        failure: const NetworkFailure(),
      ),
    ],
  );

  blocTest<AccountsBloc, S>(
    'red caída sin cache: failure; reintentar recupera',
    build: () => AccountsBloc(
      FakeAccountsRepository(
        accountsScripts: [
          [const NetworkFailure()],
          [fresh],
        ],
      ),
    ),
    act: (b) => b
      ..add(const ResourceRequested())
      ..add(const ResourceRequested()),
    expect: () => [
      const S(status: ResourceStatus.loading),
      const S(status: ResourceStatus.failure, failure: NetworkFailure()),
      const S(status: ResourceStatus.loading),
      S(
        status: ResourceStatus.success,
        data: testAccounts,
        updatedAt: seedUpdatedAt,
      ),
    ],
  );
}
