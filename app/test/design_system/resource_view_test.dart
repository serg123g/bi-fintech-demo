import 'package:fintech_platform/core/connectivity/offline_scope.dart';
import 'package:fintech_platform/core/presentation/resource_state.dart';
import 'package:fintech_platform/design_system/app_theme.dart';
import 'package:fintech_platform/design_system/widgets/resource_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fresh = ResourceState<String>(
    status: ResourceStatus.success,
    data: 'datos',
    updatedAt: DateTime.now(),
  );

  Widget host({
    required bool offline,
    required ResourceState<String> state,
    VoidCallback? onRetry,
  }) => MaterialApp(
    home: Scaffold(
      body: OfflineScope(
        isOffline: offline,
        child: ResourceView<String>(
          state: state,
          onRetry: onRetry ?? () {},
          builder: (_, d) => ListView(children: [Text(d)]),
        ),
      ),
    ),
  );

  testWidgets('online con datos frescos: "Actualizado" con check', (
    tester,
  ) async {
    await tester.pumpWidget(host(offline: false, state: fresh));
    expect(find.text('Actualizado hace un momento'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('offline: "Datos guardados", cloud_off y color de advertencia', (
    tester,
  ) async {
    await tester.pumpWidget(host(offline: true, state: fresh));

    expect(find.text('Datos guardados · hace un momento'), findsOneWidget);
    final icon = tester.widget<Icon>(find.byIcon(Icons.cloud_off));
    expect(icon.color, AppColors.warning);
    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
  });

  testWidgets('al reconectar refresca si los datos estaban desactualizados', (
    tester,
  ) async {
    var retries = 0;
    final cached = fresh.copyWith(fromCache: true);

    await tester.pumpWidget(
      host(offline: true, state: cached, onRetry: () => retries++),
    );
    await tester.pumpWidget(
      host(offline: false, state: cached, onRetry: () => retries++),
    );
    await tester.pump();

    expect(retries, 1);
  });

  testWidgets('al reconectar NO refresca si los datos ya eran frescos', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      host(offline: true, state: fresh, onRetry: () => retries++),
    );
    await tester.pumpWidget(
      host(offline: false, state: fresh, onRetry: () => retries++),
    );
    await tester.pump();

    expect(retries, 0);
  });
}
