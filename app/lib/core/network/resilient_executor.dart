import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart'
    show FunctionException, PostgrestException;

import '../errors/failures.dart';
import '../logging/app_logger.dart';
import 'circuit_breaker.dart';
import 'request_context.dart';

typedef ResilientCall<T> = Future<T> Function(RequestContext ctx);

/// Punto único por el que pasan todas las llamadas remotas.
///
/// Aplica, en este orden: circuit breaker por servicio -> timeout por intento
/// -> reintentos con backoff exponencial + jitter (solo si la operación es
/// idempotente y el error es transitorio). Traduce cualquier excepción a un
/// [AppFailure] y loguea con correlation ID.
///
/// Es una interfaz para poder decorarla (panel chaos, métricas) sin tocar
/// repositorios.
abstract interface class ResilientExecutor {
  Future<T> run<T>(
    String service,
    ResilientCall<T> call, {
    bool idempotent = true,
  });
}

class RetryPolicy {
  const RetryPolicy({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 300),
    this.maxDelay = const Duration(seconds: 3),
    this.attemptTimeout = const Duration(seconds: 8),
  });

  /// Sin reintentos (operaciones no idempotentes).
  static const none = RetryPolicy(maxAttempts: 1);

  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final Duration attemptTimeout;

  /// Backoff exponencial con "full jitter": random(0, min(max, base*2^n)).
  Duration delayFor(int attempt, Random random) {
    final exp = baseDelay.inMilliseconds * pow(2, attempt - 1);
    final capped = min(exp.toInt(), maxDelay.inMilliseconds);
    return Duration(milliseconds: random.nextInt(capped + 1));
  }
}

class DefaultResilientExecutor implements ResilientExecutor {
  DefaultResilientExecutor({
    required AppLogger logger,
    this.policy = const RetryPolicy(),
    CircuitBreaker Function()? breakerFactory,
    Future<void> Function(Duration)? sleep,
    Random? random,
  }) : _logger = logger,
       _breakerFactory = breakerFactory ?? CircuitBreaker.new,
       _sleep = sleep ?? Future<void>.delayed,
       _random = random ?? Random();

  final AppLogger _logger;
  final RetryPolicy policy;
  final CircuitBreaker Function() _breakerFactory;
  final Future<void> Function(Duration) _sleep;
  final Random _random;
  final Map<String, CircuitBreaker> _breakers = {};

  CircuitBreaker breakerFor(String service) =>
      _breakers.putIfAbsent(service, _breakerFactory);

  @override
  Future<T> run<T>(
    String service,
    ResilientCall<T> call, {
    bool idempotent = true,
  }) async {
    final breaker = breakerFor(service);
    final correlationId = newCorrelationId(_random);
    final maxAttempts = idempotent ? policy.maxAttempts : 1;

    for (var attempt = 1; ; attempt++) {
      if (!breaker.allowsRequest) {
        _logger.warning('circuit_open', {
          'service': service,
          'correlationId': correlationId,
        });
        throw ServiceUnavailableFailure(
          service,
          retryAfter: breaker.retryAfter,
        );
      }

      final ctx = RequestContext(
        service: service,
        correlationId: correlationId,
        attempt: attempt,
      );
      final watch = Stopwatch()..start();
      try {
        final result = await call(ctx).timeout(policy.attemptTimeout);
        breaker.recordSuccess();
        _logger.info('request_ok', {
          'service': service,
          'correlationId': correlationId,
          'attempt': attempt,
          'ms': watch.elapsedMilliseconds,
        });
        return result;
      } on Object catch (error, stack) {
        final failure = classify(error);
        final transient = isTransient(failure);
        if (transient) breaker.recordFailure();
        final willRetry = transient && attempt < maxAttempts;
        _logger.log(
          willRetry ? LogLevel.warning : LogLevel.error,
          'request_failed',
          context: {
            'service': service,
            'correlationId': correlationId,
            'attempt': attempt,
            'ms': watch.elapsedMilliseconds,
            'failure': failure.runtimeType,
            'willRetry': willRetry,
          },
          error: error,
          stackTrace: willRetry ? null : stack,
        );
        if (!willRetry) throw failure;
        await _sleep(policy.delayFor(attempt, _random));
      }
    }
  }

  /// Traduce errores de red/SDK a fallos de dominio.
  static AppFailure classify(Object error) => switch (error) {
    AppFailure() => error,
    TimeoutException() || SocketException() => const NetworkFailure(),
    // Errores de PostgREST con código PGRST/SQL: el request llegó y fue
    // rechazado (RLS, validación). No son transitorios.
    PostgrestException(:final code) when code != null && code.isNotEmpty =>
      const ServerFailure(
        message: 'No pudimos procesar la solicitud.',
        retryable: false,
      ),
    FunctionException(:final status) when status >= 500 =>
      const ServerFailure(),
    FunctionException() => const ServerFailure(
      message: 'No pudimos procesar la solicitud.',
      retryable: false,
    ),
    // http.ClientException y similares: fallo de transporte.
    _ => const NetworkFailure(),
  };

  /// Solo se reintenta lo que puede resolverse esperando.
  static bool isTransient(AppFailure f) => switch (f) {
    NetworkFailure() => true,
    ServerFailure(:final retryable) => retryable,
    _ => false,
  };
}
