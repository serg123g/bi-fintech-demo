import 'dart:math';

import 'package:fintech_platform/core/chaos/chaos_config.dart';
import 'package:fintech_platform/core/chaos/chaos_executor.dart';
import 'package:fintech_platform/core/errors/failures.dart';
import 'package:fintech_platform/core/logging/app_logger.dart';
import 'package:fintech_platform/core/network/circuit_breaker.dart';
import 'package:fintech_platform/core/network/resilient_executor.dart';
import 'package:flutter_test/flutter_test.dart';

class _SilentLogger implements AppLogger {
  @override
  void log(
    LogLevel level,
    String message, {
    Map<String, Object?> context = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {}
}

void main() {
  late ChaosController chaos;
  late List<Duration> chaosSleeps;
  late DefaultResilientExecutor inner;
  late ChaosResilientExecutor executor;

  setUp(() {
    chaos = ChaosController();
    chaosSleeps = [];
    inner = DefaultResilientExecutor(
      logger: _SilentLogger(),
      sleep: (_) async {},
      random: Random(1),
    );
    executor = ChaosResilientExecutor(
      inner: inner,
      controller: chaos,
      sleep: (d) async => chaosSleeps.add(d),
      random: Random(42),
    );
  });

  tearDown(() => chaos.close());

  test('sin chaos la llamada pasa intacta', () async {
    expect(await executor.run('accounts', (_) async => 7), 7);
    expect(chaosSleeps, isEmpty);
  });

  test('latencia se aplica en cada intento', () async {
    chaos.setLatency(const Duration(seconds: 3));
    await executor.run('accounts', (_) async => 1);
    expect(chaosSleeps, [const Duration(seconds: 3)]);
  });

  test('servicio caído: reintenta, falla como NetworkFailure y abre el '
      'circuito; otros servicios siguen funcionando', () async {
    chaos.setServiceDown(ChaosServices.homeLayout, down: true);
    var calls = 0;

    await expectLater(
      executor.run(ChaosServices.homeLayout, (_) async => calls++),
      throwsA(isA<NetworkFailure>()),
    );
    expect(calls, 0, reason: 'la llamada real nunca se ejecuta');
    expect(inner.circuitStates[ChaosServices.homeLayout], CircuitState.open);

    expect(await executor.run(ChaosServices.accounts, (_) async => 'ok'), 'ok');
  });

  test('100 % de fallas agota los reintentos', () async {
    chaos.setFailureRate(1);
    var calls = 0;
    await expectLater(
      executor.run('accounts', (_) async => calls++),
      throwsA(isA<NetworkFailure>()),
    );
    expect(calls, 0);
  });

  test('50 % de fallas: los reintentos recuperan la mayoría', () async {
    chaos.setFailureRate(0.5);
    var ok = 0;
    for (var i = 0; i < 40; i++) {
      inner.resetCircuits();
      try {
        await executor.run('accounts', (_) async => 1);
        ok++;
      } on NetworkFailure {
        // esperado en ~12.5 % de los casos (0.5^3)
      }
    }
    expect(ok, greaterThan(25));
  });

  test('presets y reset', () {
    chaos.apply(ChaosPresets.unstable);
    expect(chaos.state.isActive, isTrue);
    expect(chaos.state.failureRate, 0.5);
    chaos.reset();
    expect(chaos.state.isActive, isFalse);
  });
}
