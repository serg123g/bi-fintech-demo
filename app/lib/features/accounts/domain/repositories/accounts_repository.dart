import '../../../../core/cache/data_result.dart';
import '../entities/account.dart';
import '../entities/movement.dart';

/// Lecturas con stale-while-revalidate: cada stream emite primero la cache
/// (si hay) y después los datos frescos. Si la red falla, el stream termina
/// con un `AppFailure` como error.
abstract interface class AccountsRepository {
  Stream<DataResult<List<Account>>> watchAccounts();

  Stream<DataResult<List<Movement>>> watchMovements(String accountId);
}
