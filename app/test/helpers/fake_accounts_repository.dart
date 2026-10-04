import 'package:fintech_platform/core/cache/data_result.dart';
import 'package:fintech_platform/core/errors/failures.dart';
import 'package:fintech_platform/features/accounts/domain/entities/account.dart';
import 'package:fintech_platform/features/accounts/domain/entities/movement.dart';
import 'package:fintech_platform/features/accounts/domain/repositories/accounts_repository.dart';

final seedUpdatedAt = DateTime(2026, 10, 4, 9);

const testAccounts = [
  Account(
    id: 'a1',
    type: AccountType.ahorros,
    numberMasked: '****4821',
    balanceCents: 6081,
  ),
  Account(
    id: 'a2',
    type: AccountType.corriente,
    numberMasked: '****7310',
    balanceCents: 441240,
  ),
];

final testMovements = [
  Movement(
    id: 'm1',
    accountId: 'a1',
    amountCents: -4530,
    description: 'Supermercado Santa María',
    category: MovementCategory.comida,
    createdAt: DateTime(2026, 9, 16, 13),
  ),
  Movement(
    id: 'm2',
    accountId: 'a1',
    amountCents: 25000,
    description: 'Pago freelance diseño web',
    category: MovementCategory.ingreso,
    createdAt: DateTime(2026, 9, 14, 10),
  ),
];

/// Repositorio programable: cada llamada consume el siguiente "guion".
/// Un guion es la lista de eventos que emitirá el stream (DataResult o
/// AppFailure como error final).
class FakeAccountsRepository implements AccountsRepository {
  FakeAccountsRepository({
    List<List<Object>>? accountsScripts,
    List<List<Object>>? movementsScripts,
  }) : _accounts = accountsScripts ?? [_ok(testAccounts)],
       _movements = movementsScripts ?? [_ok(testMovements)];

  final List<List<Object>> _accounts;
  final List<List<Object>> _movements;
  int accountsCalls = 0;
  int movementsCalls = 0;

  static List<Object> _ok<T>(T data) => [
    DataResult<T>(data, DataSource.network, seedUpdatedAt),
  ];

  static Stream<DataResult<T>> _play<T>(List<Object> script) async* {
    for (final e in script) {
      if (e is AppFailure) throw e;
      yield e as DataResult<T>;
    }
  }

  List<Object> _next(List<List<Object>> scripts, int call) =>
      scripts[call < scripts.length ? call : scripts.length - 1];

  @override
  Stream<DataResult<List<Account>>> watchAccounts() =>
      _play(_next(_accounts, accountsCalls++));

  @override
  Stream<DataResult<List<Movement>>> watchMovements(String accountId) =>
      _play(_next(_movements, movementsCalls++));
}
