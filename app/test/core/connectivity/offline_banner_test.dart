import 'dart:async';

import 'package:fintech_platform/core/connectivity/connectivity_cubit.dart';
import 'package:fintech_platform/core/connectivity/connectivity_service.dart';
import 'package:fintech_platform/core/connectivity/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConnectivity implements ConnectivityService {
  final controller = StreamController<bool>.broadcast();
  bool initial = true;

  @override
  Future<bool> isOnline() async => initial;

  @override
  Stream<bool> get onlineChanges => controller.stream;

  Future<void> dispose() => controller.close();
}

void main() {
  testWidgets('aparece sin conexión y desaparece al volver', (tester) async {
    final service = _FakeConnectivity();
    final cubit = ConnectivityCubit(service);
    addTearDown(() async {
      await cubit.close();
      await service.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const OfflineBanner(child: Scaffold(body: Text('contenido'))),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('offline_banner')), findsNothing);

    // pumpAndSettle y no pump(): el cambio llega por microtasks (stream del
    // servicio -> emit del cubit -> listener del provider). pump() sin
    // duración decide si dibuja ANTES de drenarlas, así que el rebuild
    // quedaría para el siguiente frame.
    service.controller.add(false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('offline_banner')), findsOneWidget);
    expect(find.text('contenido'), findsOneWidget);

    service.controller.add(true);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('offline_banner')), findsNothing);
  });
}
