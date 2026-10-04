import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:fintech_platform/core/errors/failures.dart';
import 'package:fintech_platform/core/logging/app_logger.dart';
import 'package:fintech_platform/core/network/circuit_breaker.dart';
import 'package:fintech_platform/core/network/request_context.dart';
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
  late List<Duration> sleeps;

  DefaultResilientExecutor executor({
    RetryPolicy policy = const RetryPolicy(),
    CircuitBreaker Function()? breaker,
  }) => DefaultResilientExecutor(
    logger: _SilentLogger(),
    policy: policy,
    breakerFactory: breaker,
    sleep: (d) async => sleeps.add(d),
    random: Random(1),
  );

  setUp(() => sleeps = []);

  test('éxito al primer intento no reintenta', () async {
    var calls = 0;
    final result = await executor().run('svc', (_) async {
      calls++;
      return 42;
    });
    expect(result, 42);
    expect(calls, 1);
    expect(sleeps, isEmpty);
  });

  test('reintenta errores transitorios y luego tiene éxito', () async {
    final attempts = <int>[];
    final ids = <String>{};
    final result = await executor().run('svc', (RequestContext ctx) async {
      attempts.add(ctx.attempt);
      ids.add(ctx.correlationId);
      if (ctx.attempt < 3) throw const SocketException('down');
      return 'ok';
    });
    expect(result, 'ok');
    expect(attempts, [1, 2, 3]);
    expect(ids, hasLength(1), reason: 'mismo correlation id en reintentos');
    expect(sleeps, hasLength(2));
  });

  test('backoff exponencial con jitter acotado por maxDelay', () {
    const p = RetryPolicy(
      baseDelay: Duration(milliseconds: 100),
      maxDelay: Duration(milliseconds: 250),
    );
    final r = Random(7);
    for (var attempt = 1; attempt <= 5; attempt++) {
      final d = p.delayFor(attempt, r);
      expect(d.inMilliseconds, inInclusiveRange(0, 250));
    }
  });

  test('agota reintentos y lanza NetworkFailure', () async {
    var calls = 0;
    await expectLater(
      executor().run<void>('svc', (_) async {
        calls++;
        throw const SocketException('down');
      }),
      throwsA(isA<NetworkFailure>()),
    );
    expect(calls, 3);
  });

  test('operación no idempotente NO se reintenta', () async {
    var calls = 0;
    await expectLater(
      executor().run<void>('svc', (_) async {
        calls++;
        throw const SocketException('down');
      }, idempotent: false),
      throwsA(isA<NetworkFailure>()),
    );
    expect(calls, 1);
  });

  test(
    'errores no transitorios (rechazo del servidor) no se reintentan',
    () async {
      var calls = 0;
      await expectLater(
        executor().run<void>('svc', (_) async {
          calls++;
          throw const ServerFailure(retryable: false);
        }),
        throwsA(isA<ServerFailure>()),
      );
      expect(calls, 1);
    },
  );

  test(
    'timeout por intento se reintenta y falla como NetworkFailure',
    () async {
      final ex = executor(
        policy: const RetryPolicy(
          maxAttempts: 2,
          attemptTimeout: Duration(milliseconds: 20),
        ),
      );
      await expectLater(
        ex.run<void>('svc', (_) => Completer<void>().future),
        throwsA(isA<NetworkFailure>()),
      );
      expect(sleeps, hasLength(1));
    },
  );

  test('circuit breaker abierto corta sin llamar al backend', () async {
    final ex = executor(
      policy: const RetryPolicy(maxAttempts: 1),
      breaker: () => CircuitBreaker(failureThreshold: 2),
    );
    var calls = 0;
    Future<void> failing(RequestContext _) async {
      calls++;
      throw const SocketException('down');
    }

    await expectLater(ex.run('svc', failing), throwsA(isA<NetworkFailure>()));
    await expectLater(ex.run('svc', failing), throwsA(isA<NetworkFailure>()));
    await expectLater(
      ex.run('svc', failing),
      throwsA(isA<ServiceUnavailableFailure>()),
    );
    expect(calls, 2);

    // Otro servicio tiene su propio breaker.
    expect(await ex.run('otro', (_) async => 1), 1);
  });
}
