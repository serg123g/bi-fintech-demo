import 'dart:async';

import 'package:fintech_platform/core/cache/cache_store.dart';
import 'package:fintech_platform/core/cache/data_result.dart';
import 'package:fintech_platform/core/errors/failures.dart';
import 'package:fintech_platform/features/accounts/data/accounts_remote_data_source.dart';
import 'package:fintech_platform/features/accounts/data/accounts_repository_impl.dart';
import 'package:fintech_platform/features/accounts/domain/entities/account.dart';
import 'package:fintech_platform/features/accounts/domain/entities/movement.dart';
import 'package:fintech_platform/features/auth/domain/entities/app_user.dart';
import 'package:fintech_platform/features/auth/domain/entities/customer_segment.dart';
import 'package:fintech_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fintech_platform/features/auth/presentation/session_cache_cleaner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_accounts_repository.dart';

/// Remoto que devuelve las cuentas del usuario "logueado" o falla (offline).
class _Remote implements AccountsRemoteDataSource {
  bool offline = false;
  List<Account> accounts = const [];

  @override
  Future<List<Account>> fetchAccounts() async {
    if (offline) throw const NetworkFailure();
    return accounts;
  }

  @override
  Future<List<Movement>> fetchMovements(String accountId, {int limit = 50}) =>
      throw UnimplementedError();
}

const _ana = AppUser(
  id: 'user-ana',
  email: 'joven@test.com',
  fullName: 'Ana Torres',
  segment: CustomerSegment.joven,
);
const _carlos = AppUser(
  id: 'user-carlos',
  email: 'pyme@test.com',
  fullName: 'Carlos Méndez',
  segment: CustomerSegment.pyme,
);

Future<List<Object>> _collect(Stream<DataResult<List<Account>>> s) async {
  final out = <Object>[];
  await s.handleError(out.add).forEach(out.add);
  return out;
}

void main() {
  late InMemoryCacheStore cache;
  late _Remote remote;
  late String currentUser;
  late AccountsRepositoryImpl repo;

  setUp(() {
    cache = InMemoryCacheStore();
    remote = _Remote();
    currentUser = _ana.id;
    repo = AccountsRepositoryImpl(
      remote: remote,
      cache: cache,
      currentUserId: () => currentUser,
    );
  });

  group('claves por usuario (capa 1)', () {
    test('otro usuario offline NO recibe la cache del anterior', () async {
      // Ana carga sus cuentas -> quedan en cache.
      remote.accounts = testAccounts;
      await _collect(repo.watchAccounts());

      // Cambia el usuario sin limpiar la cache y se cae la red.
      currentUser = _carlos.id;
      remote.offline = true;
      final events = await _collect(repo.watchAccounts());

      expect(events.whereType<DataResult<List<Account>>>(), isEmpty);
      expect(events.single, isA<NetworkFailure>());
    });

    test('el mismo usuario sí recupera su cache offline', () async {
      remote.accounts = testAccounts;
      await _collect(repo.watchAccounts());

      remote.offline = true;
      final events = await _collect(repo.watchAccounts());

      final cached = events.whereType<DataResult<List<Account>>>().single;
      expect(cached.isFromCache, isTrue);
      expect(cached.data, testAccounts);
    });
  });

  group('SessionCacheCleaner (capa 2)', () {
    late StreamController<AuthState> auth;

    setUp(() {
      auth = StreamController<AuthState>();
      SessionCacheCleaner(cache: cache, authStates: auth.stream);
    });

    tearDown(() => auth.close());

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('logout borra toda la cache', () async {
      await cache.write('accounts:${_ana.id}', '[]');
      auth
        ..add(const AuthAuthenticated(_ana))
        ..add(const AuthUnauthenticated());
      await settle();
      expect(await cache.read('accounts:${_ana.id}'), isNull);
    });

    test('login de un usuario distinto borra la cache', () async {
      auth.add(const AuthAuthenticated(_ana));
      await settle();
      await cache.write('accounts:${_ana.id}', '[]');

      auth.add(const AuthAuthenticated(_carlos));
      await settle();
      expect(await cache.read('accounts:${_ana.id}'), isNull);
    });

    test('refresh de sesión del mismo usuario conserva la cache', () async {
      auth.add(const AuthAuthenticated(_ana));
      await settle();
      await cache.write('accounts:${_ana.id}', '[]');

      auth.add(const AuthAuthenticated(_ana));
      await settle();
      expect(await cache.read('accounts:${_ana.id}'), isNotNull);
    });
  });
}
