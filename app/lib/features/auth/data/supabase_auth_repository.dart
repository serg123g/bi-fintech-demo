import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/entities/app_user.dart';
import '../domain/entities/customer_segment.dart';
import '../domain/repositories/auth_repository.dart';

/// Implementación de [AuthRepository] sobre Supabase Auth.
///
/// * La sesión la persiste el SDK en `SecureSessionStorage` (ver DI).
/// * Nombre y segmento se leen de `profiles` (fuente de verdad, protegida por
///   RLS); si la consulta falla se usa `user_metadata` como respaldo para no
///   bloquear el login por un fallo parcial.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(
    this._client,
    this._logger, {
    this.timeout = const Duration(seconds: 15),
  });

  final SupabaseClient _client;
  final AppLogger _logger;
  final Duration timeout;

  AppUser? _cache;

  GoTrueClient get _auth => _client.auth;

  @override
  Future<AppUser?> currentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _toAppUser(user);
  }

  @override
  Stream<AppUser?> authStateChanges() =>
      _auth.onAuthStateChange.asyncMap((event) async {
        final user = event.session?.user;
        _logger.info('auth_state_change', {'event': event.event.name});
        if (user == null) {
          _cache = null;
          return null;
        }
        return _toAppUser(user);
      });

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) =>
      _guard('sign_in', () async {
        final res = await _auth
            .signInWithPassword(email: email.trim(), password: password)
            .timeout(timeout);
        final user = res.user;
        if (user == null) {
          throw AuthFailure.fromReason(AuthFailureReason.invalidCredentials);
        }
        return _toAppUser(user, forceRefresh: true);
      });

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
    required CustomerSegment segment,
  }) =>
      _guard('sign_up', () async {
        final res = await _auth.signUp(
          email: email.trim(),
          password: password,
          // El trigger handle_new_user crea profile + cuenta con estos datos.
          data: {'full_name': fullName.trim(), 'segment': segment.name},
        ).timeout(timeout);
        final user = res.user;
        if (user == null) {
          throw AuthFailure.fromReason(AuthFailureReason.unknown);
        }
        if (res.session == null) {
          // Proyecto con confirmación de email activa.
          throw AuthFailure.fromReason(AuthFailureReason.emailNotConfirmed);
        }
        return _toAppUser(user, forceRefresh: true);
      });

  @override
  Future<void> signOut() => _guard('sign_out', () async {
        _cache = null;
        // scope local: cierra la sesión en este dispositivo aunque no haya red.
        await _auth.signOut(scope: SignOutScope.local);
      });

  Future<AppUser> _toAppUser(User user, {bool forceRefresh = false}) async {
    final cached = _cache;
    if (!forceRefresh && cached != null && cached.id == user.id) return cached;

    final meta = user.userMetadata ?? const <String, dynamic>{};
    var fullName = (meta['full_name'] as String?) ?? '';
    var segment = CustomerSegment.fromName(meta['segment'] as String?);

    try {
      final row = await _client
          .from('profiles')
          .select('full_name, segment')
          .eq('id', user.id)
          .maybeSingle()
          .timeout(timeout);
      if (row != null) {
        fullName = (row['full_name'] as String?) ?? fullName;
        segment = CustomerSegment.fromName(row['segment'] as String?);
      }
    } on Object catch (e) {
      // Degradación: seguimos con los datos del JWT.
      _logger.warning('profile_fetch_failed', {'error': e.runtimeType});
    }

    final appUser = AppUser(
      id: user.id,
      email: user.email ?? '',
      fullName: fullName.isEmpty ? (user.email ?? 'Cliente') : fullName,
      segment: segment,
    );
    _cache = appUser;
    return appUser;
  }

  Future<T> _guard<T>(String op, Future<T> Function() body) async {
    try {
      return await body();
    } on AppFailure {
      rethrow;
    } on AuthException catch (e, st) {
      _logger.error(
        'auth_failed',
        error: e,
        stackTrace: st,
        context: {'op': op, 'code': e.code, 'status': e.statusCode},
      );
      throw mapAuthException(e);
    } on TimeoutException {
      throw const NetworkFailure();
    } on SocketException {
      throw const NetworkFailure();
    } on Object catch (e, st) {
      _logger.error('auth_unexpected', error: e, stackTrace: st);
      throw const UnexpectedFailure();
    }
  }
}

/// Traduce errores de GoTrue a fallos de dominio. Público para testearlo.
AppFailure mapAuthException(AuthException e) {
  if (e is AuthRetryableFetchException) return const NetworkFailure();
  if (e is AuthWeakPasswordException) {
    return AuthFailure.fromReason(AuthFailureReason.weakPassword);
  }
  final reason = switch (e.code) {
    'invalid_credentials' => AuthFailureReason.invalidCredentials,
    'user_already_exists' ||
    'email_exists' =>
      AuthFailureReason.emailAlreadyRegistered,
    'weak_password' => AuthFailureReason.weakPassword,
    'email_not_confirmed' => AuthFailureReason.emailNotConfirmed,
    'over_request_rate_limit' ||
    'over_email_send_rate_limit' =>
      AuthFailureReason.rateLimited,
    'session_expired' ||
    'session_not_found' ||
    'refresh_token_not_found' =>
      AuthFailureReason.sessionExpired,
    _ => e.statusCode == '400'
        ? AuthFailureReason.invalidCredentials
        : AuthFailureReason.unknown,
  };
  return AuthFailure.fromReason(reason);
}
