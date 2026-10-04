enum CircuitState { closed, open, halfOpen }

/// Circuit breaker simple por servicio.
///
/// * closed: las llamadas pasan; [failureThreshold] fallos seguidos -> open.
/// * open: se rechazan sin llamar al backend durante [openDuration].
/// * halfOpen: se deja pasar una llamada de prueba; éxito -> closed,
///   fallo -> open de nuevo.
class CircuitBreaker {
  CircuitBreaker({
    this.failureThreshold = 3,
    this.openDuration = const Duration(seconds: 15),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final int failureThreshold;
  final Duration openDuration;
  final DateTime Function() _now;

  CircuitState _state = CircuitState.closed;
  int _consecutiveFailures = 0;
  DateTime? _openedAt;

  CircuitState get state {
    if (_state == CircuitState.open && _cooldownElapsed) {
      _state = CircuitState.halfOpen;
    }
    return _state;
  }

  bool get allowsRequest => state != CircuitState.open;

  Duration get retryAfter {
    final opened = _openedAt;
    if (opened == null) return Duration.zero;
    final left = openDuration - _now().difference(opened);
    return left.isNegative ? Duration.zero : left;
  }

  bool get _cooldownElapsed {
    final opened = _openedAt;
    return opened != null && _now().difference(opened) >= openDuration;
  }

  void recordSuccess() {
    _consecutiveFailures = 0;
    _state = CircuitState.closed;
    _openedAt = null;
  }

  void recordFailure() {
    _consecutiveFailures++;
    if (_state == CircuitState.halfOpen ||
        _consecutiveFailures >= failureThreshold) {
      _state = CircuitState.open;
      _openedAt = _now();
    }
  }
}
