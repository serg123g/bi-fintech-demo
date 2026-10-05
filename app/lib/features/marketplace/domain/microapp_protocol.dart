import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Protocolo v1 entre la app (host) y micro-apps web.
///
/// web -> app: `{v:1, type: ready | benefit_selected | close, payload}`
/// app -> web: `{v:1, type: init, payload: {name, segment, section}}`
///
/// Reglas de seguridad: la app nunca envía el token de sesión ni datos
/// financieros; todo mensaje entrante se valida y lo desconocido se ignora.
abstract final class MicroappProtocol {
  static const version = 1;

  static String init({
    required String name,
    required String segment,
    String? section,
  }) => jsonEncode({
    'v': version,
    'type': 'init',
    'payload': {'name': name, 'segment': segment, 'section': ?section},
  });

  static MicroappMessage parse(String raw) {
    Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      return const InvalidMessage('json inválido');
    }
    if (json is! Map<String, dynamic>) {
      return const InvalidMessage('no es objeto');
    }
    if (json['v'] != version) return const InvalidMessage('versión');
    final payload = json['payload'];
    final p = payload is Map<String, dynamic>
        ? payload
        : const <String, dynamic>{};
    return switch (json['type']) {
      'ready' => const ReadyMessage(),
      'close' => const CloseMessage(),
      'benefit_selected' => _benefit(p),
      final Object? t => InvalidMessage('tipo desconocido: $t'),
    };
  }

  static MicroappMessage _benefit(Map<String, dynamic> p) {
    final id = p['id'];
    final title = p['title'];
    if (id is! String || title is! String || id.isEmpty || title.isEmpty) {
      return const InvalidMessage('benefit_selected incompleto');
    }
    return BenefitSelectedMessage(
      id: id,
      // Texto que viene de la web: se acota antes de mostrarlo.
      title: title.length > 80 ? title.substring(0, 80) : title,
    );
  }
}

sealed class MicroappMessage extends Equatable {
  const MicroappMessage();

  @override
  List<Object?> get props => [];
}

final class ReadyMessage extends MicroappMessage {
  const ReadyMessage();
}

final class CloseMessage extends MicroappMessage {
  const CloseMessage();
}

final class BenefitSelectedMessage extends MicroappMessage {
  const BenefitSelectedMessage({required this.id, required this.title});

  final String id;
  final String title;

  @override
  List<Object?> get props => [id, title];
}

final class InvalidMessage extends MicroappMessage {
  const InvalidMessage(this.reason);

  final String reason;

  @override
  List<Object?> get props => [reason];
}
