import 'package:fintech_platform/app.dart';
import 'package:fintech_platform/core/config/env.dart';
import 'package:fintech_platform/core/di/injection.dart';
import 'package:fintech_platform/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    await configureDependencies(
      env: const EnvConfig(
        supabaseUrl: '',
        supabaseAnonKey: '',
        microappUrl: '',
        enableChaosPanel: false,
      ),
    );
  });

  test('DI registra configuración y logger', () {
    expect(sl.isRegistered<EnvConfig>(), isTrue);
    expect(sl.isRegistered<AppLogger>(), isTrue);
    expect(sl<EnvConfig>().hasBackend, isFalse);
  });

  testWidgets('la app arranca en el home', (tester) async {
    await tester.pumpWidget(const FintechApp());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home_placeholder')), findsOneWidget);
  });
}
