import 'package:fintech_platform/core/network/circuit_breaker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late CircuitBreaker breaker;

  setUp(() {
    now = DateTime(2026, 10, 4, 12);
    breaker = CircuitBreaker(
      failureThreshold: 3,
      openDuration: const Duration(seconds: 10),
      clock: () => now,
    );
  });

  test('se abre tras N fallos consecutivos', () {
    breaker
      ..recordFailure()
      ..recordFailure();
    expect(breaker.state, CircuitState.closed);
    breaker.recordFailure();
    expect(breaker.state, CircuitState.open);
    expect(breaker.allowsRequest, isFalse);
  });

  test('un éxito reinicia el contador', () {
    breaker
      ..recordFailure()
      ..recordFailure()
      ..recordSuccess()
      ..recordFailure();
    expect(breaker.state, CircuitState.closed);
  });

  test('pasa a half-open tras el cool-down y se cierra con un éxito', () {
    for (var i = 0; i < 3; i++) {
      breaker.recordFailure();
    }
    now = now.add(const Duration(seconds: 10));
    expect(breaker.state, CircuitState.halfOpen);
    expect(breaker.allowsRequest, isTrue);
    breaker.recordSuccess();
    expect(breaker.state, CircuitState.closed);
  });

  test('en half-open un fallo lo vuelve a abrir', () {
    for (var i = 0; i < 3; i++) {
      breaker.recordFailure();
    }
    now = now.add(const Duration(seconds: 11));
    expect(breaker.state, CircuitState.halfOpen);
    breaker.recordFailure();
    expect(breaker.state, CircuitState.open);
  });
}
