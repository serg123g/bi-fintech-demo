import 'dart:convert';
import 'dart:io';

import 'package:fintech_platform/sdui/sdui_models.dart';
import 'package:fintech_platform/sdui/sdui_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parsea el contrato v1 con acciones tipadas', () {
    final layout = SduiParser.parse({
      'version': 1,
      'layout_id': 'home-joven-v1',
      'generated_at': '2026-10-04T20:00:00.000Z',
      'sections': [
        {
          'id': 'greeting',
          'type': 'greeting',
          'props': {'text': 'Buenas tardes, Ana'},
        },
        {
          'id': 'b',
          'type': 'banner',
          'props': {
            'title': 'x',
            'action': {'type': 'route', 'value': '/accounts'},
          },
        },
        {
          'id': 'm',
          'type': 'banner',
          'props': {
            'title': 'y',
            'action': {'type': 'microapp', 'value': 'marketplace'},
          },
        },
      ],
    });
    expect(layout.layoutId, 'home-joven-v1');
    expect(layout.sections.map((s) => s.type), [
      'greeting',
      'banner',
      'banner',
    ]);
    expect(layout.sections[1].action(), const RouteAction('/accounts'));
    expect(layout.sections[2].action(), const MicroappAction('marketplace'));
  });

  test('descarta secciones mal formadas sin romper el layout', () {
    final layout = SduiParser.parse({
      'version': 1,
      'sections': [
        'no-soy-un-objeto',
        {'props': <String, Object?>{}},
        {'type': ''},
        {'type': 'greeting', 'props': 'props-invalidas'},
        {'type': 'tipo_futuro', 'props': <String, Object?>{}},
      ],
    });
    expect(layout.sections.map((s) => s.type), ['greeting', 'tipo_futuro']);
    expect(layout.sections.first.data, isEmpty);
  });

  test('acción de tipo desconocido queda como UnknownAction', () {
    expect(
      SduiAction.fromJson({'type': 'teleport', 'value': 'x'}),
      const UnknownAction('teleport', 'x'),
    );
    expect(SduiAction.fromJson({'type': 'route'}), isNull);
  });

  test('versión futura del contrato se rechaza', () {
    expect(
      () => SduiParser.parse({'version': 2, 'sections': <Object>[]}),
      throwsFormatException,
    );
  });

  test('ida y vuelta toJson -> parse conserva el layout', () {
    final original = SduiParser.parse({
      'version': 1,
      'layout_id': 'x',
      'sections': [
        {
          'id': 'g',
          'type': 'greeting',
          'props': {'text': 'Hola'},
        },
      ],
    });
    final again = SduiParser.parse(jsonDecode(jsonEncode(original.toJson())));
    expect(again, original);
  });

  test('el layout empaquetado (fallback) es válido', () {
    final raw = File('assets/sdui/home_fallback.json').readAsStringSync();
    final layout = SduiParser.parse(jsonDecode(raw));
    expect(
      layout.sections.map((s) => s.type),
      containsAll(['greeting', 'accounts_summary', 'quick_actions']),
    );
  });
}
