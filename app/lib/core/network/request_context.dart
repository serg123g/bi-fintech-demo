import 'dart:math';

/// Contexto de una petición lógica (incluye todos sus reintentos).
/// El `correlationId` se loguea y se envía como header `x-correlation-id`
/// a las Edge Functions para trazar una operación de punta a punta.
class RequestContext {
  const RequestContext({
    required this.service,
    required this.correlationId,
    required this.attempt,
  });

  final String service;
  final String correlationId;

  /// 1 = primer intento.
  final int attempt;

  Map<String, String> get headers => {'x-correlation-id': correlationId};
}

/// UUID v4 sin dependencias externas.
String newCorrelationId([Random? random]) {
  final r = random ?? Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}
