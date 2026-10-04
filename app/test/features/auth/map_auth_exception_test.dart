import 'package:fintech_platform/core/errors/failures.dart';
import 'package:fintech_platform/features/auth/data/supabase_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  AuthFailureReason? reasonOf(AuthException e) {
    final f = mapAuthException(e);
    return f is AuthFailure ? f.reason : null;
  }

  test('códigos de GoTrue se traducen a fallos de dominio', () {
    expect(
      reasonOf(const AuthException('x', code: 'invalid_credentials')),
      AuthFailureReason.invalidCredentials,
    );
    expect(
      reasonOf(const AuthException('x', code: 'user_already_exists')),
      AuthFailureReason.emailAlreadyRegistered,
    );
    expect(
      reasonOf(const AuthException('x', code: 'over_request_rate_limit')),
      AuthFailureReason.rateLimited,
    );
    expect(
      reasonOf(const AuthException('x', code: 'algo_nuevo')),
      AuthFailureReason.unknown,
    );
  });

  test('errores reintentables de red son NetworkFailure', () {
    expect(
      mapAuthException(AuthRetryableFetchException()),
      isA<NetworkFailure>(),
    );
  });
}
