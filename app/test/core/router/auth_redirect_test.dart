import 'package:fintech_platform/core/errors/failures.dart';
import 'package:fintech_platform/core/router/app_routes.dart';
import 'package:fintech_platform/core/router/auth_redirect.dart';
import 'package:fintech_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  String? go(AuthState s, String location) =>
      authRedirect(s, Uri.parse(location));

  group('sesión sin resolver', () {
    test('cualquier ruta va a splash', () {
      expect(go(const AuthInitial(), '/'), AppRoutes.splash);
      expect(go(const AuthInitial(), AppRoutes.splash), isNull);
    });

    test('ruta profunda se recuerda en from', () {
      expect(
        go(const AuthInitial(), '/accounts/a1?tab=mov'),
        '/splash?from=%2Faccounts%2Fa1%3Ftab%3Dmov',
      );
    });
  });

  group('sin sesión', () {
    const states = <AuthState>[
      AuthUnauthenticated(),
      AuthLoading(),
      AuthError(NetworkFailure()),
    ];

    for (final s in states) {
      test('${s.runtimeType}: home -> login, rutas públicas se respetan', () {
        expect(go(s, '/'), AppRoutes.login);
        expect(go(s, AppRoutes.login), isNull);
        expect(go(s, AppRoutes.onboarding), isNull);
      });
    }

    test('desde splash conserva el destino original', () {
      expect(
        go(const AuthUnauthenticated(), '/splash?from=%2Faccounts'),
        '/login?from=%2Faccounts',
      );
    });
  });

  group('con sesión', () {
    const auth = AuthAuthenticated(testUser);

    test('login/onboarding/splash -> home', () {
      expect(go(auth, AppRoutes.login), AppRoutes.home);
      expect(go(auth, AppRoutes.onboarding), AppRoutes.home);
      expect(go(auth, AppRoutes.splash), AppRoutes.home);
    });

    test('rutas protegidas no redirigen', () {
      expect(go(auth, '/'), isNull);
      expect(go(auth, '/accounts'), isNull);
    });

    test('restaura el deep link guardado', () {
      expect(go(auth, '/login?from=%2Faccounts%2Fa1'), '/accounts/a1');
    });

    test('ignora destinos externos (open redirect)', () {
      expect(go(auth, '/login?from=https%3A%2F%2Fevil.com'), AppRoutes.home);
      expect(go(auth, '/login?from=%2F%2Fevil.com'), AppRoutes.home);
    });
  });
}
