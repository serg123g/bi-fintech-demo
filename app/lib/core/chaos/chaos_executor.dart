import 'dart:io';
import 'dart:math';

import '../network/resilient_executor.dart';
import 'chaos_config.dart';

/// Decorador de [ResilientExecutor] que inyecta fallas *dentro* de cada
/// intento, de modo que timeouts, reintentos, circuit breaker, cache y
/// fallbacks reaccionan exactamente igual que ante una falla real.
///
/// No toca repositorios ni UI: se activa solo desde el composition root.
class ChaosResilientExecutor implements ResilientExecutor {
  ChaosResilientExecutor({
    required ResilientExecutor inner,
    required ChaosController controller,
    Future<void> Function(Duration)? sleep,
    Random? random,
  }) : _inner = inner,
       _chaos = controller,
       _sleep = sleep ?? Future<void>.delayed,
       _random = random ?? Random();

  final ResilientExecutor _inner;
  final ChaosController _chaos;
  final Future<void> Function(Duration) _sleep;
  final Random _random;

  @override
  Future<T> run<T>(
    String service,
    ResilientCall<T> call, {
    bool idempotent = true,
  }) => _inner.run<T>(service, (ctx) async {
    final c = _chaos.state;
    if (c.latency > Duration.zero) await _sleep(c.latency);
    if (c.isDown(service)) {
      throw SocketException('chaos: $service caído');
    }
    if (c.failureRate > 0 && _random.nextDouble() < c.failureRate) {
      throw SocketException('chaos: falla inyectada en $service');
    }
    return call(ctx);
  }, idempotent: idempotent);
}
