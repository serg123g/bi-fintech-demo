import 'dart:convert';

import '../../../core/cache/cache_store.dart';
import '../../../core/cache/data_result.dart';
import '../../../core/cache/stale_while_revalidate.dart';
import '../domain/entities/account.dart';
import '../domain/entities/movement.dart';
import '../domain/repositories/accounts_repository.dart';
import 'accounts_mapper.dart';
import 'accounts_remote_data_source.dart';

class AccountsRepositoryImpl implements AccountsRepository {
  AccountsRepositoryImpl({
    required AccountsRemoteDataSource remote,
    required CacheStore cache,
    required String Function() currentUserId,
    DateTime Function()? clock,
  }) : _remote = remote,
       _cache = cache,
       _userId = currentUserId,
       _clock = clock;

  final AccountsRemoteDataSource _remote;
  final CacheStore _cache;
  final String Function() _userId;
  final DateTime Function()? _clock;

  // Claves namespaced por usuario: nunca se muestran datos de otra sesión.
  String _accountsKey() => 'accounts:${_userId()}';
  String _movementsKey(String id) => 'movements:${_userId()}:$id';

  @override
  Stream<DataResult<List<Account>>> watchAccounts() => staleWhileRevalidate(
    cache: _cache,
    key: _accountsKey(),
    fetch: _remote.fetchAccounts,
    decode: AccountsMapper.decodeAccounts,
    encode: AccountsMapper.encodeAccounts,
    clock: _clock,
  );

  @override
  Stream<DataResult<List<Movement>>> watchMovements(String accountId) =>
      staleWhileRevalidate(
        cache: _cache,
        key: _movementsKey(accountId),
        fetch: () => _remote.fetchMovements(accountId),
        decode: AccountsMapper.decodeMovements,
        encode: AccountsMapper.encodeMovements,
        clock: _clock,
      );

  @override
  Stream<DataResult<Movement>> watchMovement(String movementId) =>
      staleWhileRevalidate(
        cache: _cache,
        key: 'movement:${_userId()}:$movementId',
        fetch: () => _remote.fetchMovement(movementId),
        decode: (s) => AccountsMapper.movementFromRow(
          jsonDecode(s) as Map<String, dynamic>,
        ),
        encode: (m) => jsonEncode(AccountsMapper.movementToJson(m)),
        clock: _clock,
      );
}
