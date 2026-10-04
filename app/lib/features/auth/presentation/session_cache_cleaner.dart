import 'dart:async';

import '../../../core/cache/cache_store.dart';
import 'bloc/auth_bloc.dart';

/// Garantiza que ningún usuario vea datos cacheados de otro.
///
/// Dos capas de defensa:
/// 1. Las claves de cache incluyen el user id (ver repositorios).
/// 2. Este componente borra la cache al cerrar sesión / expirar la sesión y
///    cuando se autentica un usuario distinto al anterior.
class SessionCacheCleaner {
  SessionCacheCleaner({
    required CacheStore cache,
    required Stream<AuthState> authStates,
  }) : _cache = cache {
    _subscription = authStates.listen(_onState);
  }

  final CacheStore _cache;
  late final StreamSubscription<AuthState> _subscription;
  String? _lastUserId;

  Future<void> _onState(AuthState state) async {
    switch (state) {
      case AuthUnauthenticated():
        _lastUserId = null;
        await _cache.clear();
      case AuthAuthenticated(:final user):
        final previous = _lastUserId;
        _lastUserId = user.id;
        if (previous != null && previous != user.id) await _cache.clear();
      case AuthInitial() || AuthLoading() || AuthError():
        break;
    }
  }

  Future<void> dispose() => _subscription.cancel();
}
