import 'dart:convert';

import 'package:fintech_platform/features/marketplace/domain/microapp_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String msg(Object? type, [Map<String, Object?>? payload, int v = 1]) =>
      jsonEncode({'v': v, 'type': type, 'payload': ?payload});

  test('init lleva solo contexto mínimo (sin token)', () {
    final json =
        jsonDecode(
              MicroappProtocol.init(
                name: 'Carlos',
                segment: 'pyme',
                section: 'cobros',
              ),
            )
            as Map<String, dynamic>;
    expect(json['v'], 1);
    expect(json['type'], 'init');
    expect(json['payload'], {
      'name': 'Carlos',
      'segment': 'pyme',
      'section': 'cobros',
    });
  });

  test('mensajes válidos de la web', () {
    expect(MicroappProtocol.parse(msg('ready')), const ReadyMessage());
    expect(MicroappProtocol.parse(msg('close')), const CloseMessage());
    expect(
      MicroappProtocol.parse(
        msg('benefit_selected', {'id': 'food-20', 'title': '20 % en comida'}),
      ),
      const BenefitSelectedMessage(id: 'food-20', title: '20 % en comida'),
    );
  });

  test('entradas inválidas se ignoran sin lanzar', () {
    expect(MicroappProtocol.parse('no json'), isA<InvalidMessage>());
    expect(MicroappProtocol.parse('[1,2]'), isA<InvalidMessage>());
    expect(
      MicroappProtocol.parse(msg('ready', null, 2)),
      isA<InvalidMessage>(),
    );
    expect(MicroappProtocol.parse(msg('steal_token')), isA<InvalidMessage>());
    expect(
      MicroappProtocol.parse(msg('benefit_selected', {'id': 'x'})),
      isA<InvalidMessage>(),
    );
  });

  test('títulos largos se acotan', () {
    final m =
        MicroappProtocol.parse(
              msg('benefit_selected', {'id': 'x', 'title': 'a' * 500}),
            )
            as BenefitSelectedMessage;
    expect(m.title.length, 80);
  });
}
