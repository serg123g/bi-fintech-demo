import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/resilient_executor.dart';
import '../domain/entities/account.dart';
import '../domain/entities/movement.dart';
import 'accounts_mapper.dart';

abstract interface class AccountsRemoteDataSource {
  Future<List<Account>> fetchAccounts();
  Future<List<Movement>> fetchMovements(String accountId, {int limit = 50});
}

/// Lecturas directas a PostgREST: RLS garantiza que solo vuelven las filas
/// del usuario autenticado. Todas pasan por el [ResilientExecutor].
class SupabaseAccountsRemoteDataSource implements AccountsRemoteDataSource {
  SupabaseAccountsRemoteDataSource(this._client, this._executor);

  static const service = 'accounts';

  final SupabaseClient _client;
  final ResilientExecutor _executor;

  @override
  Future<List<Account>> fetchAccounts() => _executor.run(service, (_) async {
    final rows = await _client
        .from('accounts')
        .select('id, type, number_masked, balance, currency')
        .order('created_at');
    return rows.map(AccountsMapper.accountFromRow).toList();
  });

  @override
  Future<List<Movement>> fetchMovements(String accountId, {int limit = 50}) =>
      _executor.run(service, (_) async {
        final rows = await _client
            .from('movements')
            .select('id, account_id, amount, description, category, created_at')
            .eq('account_id', accountId)
            .order('created_at', ascending: false)
            .limit(limit);
        return rows.map(AccountsMapper.movementFromRow).toList();
      });
}
