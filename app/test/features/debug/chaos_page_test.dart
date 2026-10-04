import 'package:fintech_platform/core/cache/cache_store.dart';
import 'package:fintech_platform/core/chaos/chaos_config.dart';
import 'package:fintech_platform/features/debug/presentation/chaos_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('los controles modifican la configuración de chaos', (
    tester,
  ) async {
    final chaos = ChaosController();
    addTearDown(chaos.close);
    final cache = InMemoryCacheStore();
    await cache.write('k', 'v');

    await tester.pumpWidget(
      MaterialApp(
        home: ChaosPage(controller: chaos, cache: cache),
      ),
    );

    await tester.tap(find.byKey(const Key('chaos_preset_3 s + 50 % fallas')));
    await tester.pump();
    expect(chaos.state, ChaosPresets.unstable);
    expect(find.text('Chaos activo'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('chaos_down_${ChaosServices.homeLayout}')),
    );
    await tester.pump();
    expect(chaos.state.isDown(ChaosServices.homeLayout), isTrue);

    await tester.scrollUntilVisible(
      find.byKey(const Key('chaos_clear_cache')),
      200,
    );
    await tester.tap(find.byKey(const Key('chaos_clear_cache')));
    await tester.pump();
    expect(await cache.read('k'), isNull);

    await tester.tap(find.byKey(const Key('chaos_reset')));
    await tester.pump();
    expect(chaos.state.isActive, isFalse);
  });
}
