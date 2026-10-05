import 'dart:convert';

import 'package:fintech_platform/features/marketplace/domain/microapp_protocol.dart';
import 'package:fintech_platform/features/marketplace/presentation/microapp_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> sent;
  late List<BenefitSelectedMessage> benefits;
  late int closes;
  var down = false;

  MicroappCubit build({Duration timeout = const Duration(seconds: 10)}) =>
      MicroappCubit(
        initMessage: MicroappProtocol.init(name: 'Ana', segment: 'joven'),
        send: sent.add,
        onBenefitSelected: benefits.add,
        onClose: () => closes++,
        isDown: () => down,
        readyTimeout: timeout,
      );

  String web(String type, [Map<String, Object?> payload = const {}]) =>
      jsonEncode({'v': 1, 'type': type, 'payload': payload});

  setUp(() {
    sent = [];
    benefits = [];
    closes = 0;
    down = false;
  });

  test('ready -> envía init y pasa a ready', () async {
    final c = build()..start();
    expect(c.state.status, MicroappStatus.loading);
    c.onRawMessage(web('ready'));
    expect(c.state.status, MicroappStatus.ready);
    expect(jsonDecode(sent.single), containsPair('type', 'init'));
    await c.close();
  });

  test('benefit_selected y close llegan a la app', () async {
    final c = build()..start();
    c
      ..onRawMessage(web('ready'))
      ..onRawMessage(web('benefit_selected', {'id': 'cine', 'title': 'Cine'}))
      ..onRawMessage(web('close'));
    expect(benefits.single.id, 'cine');
    expect(closes, 1);
    await c.close();
  });

  test(
    'sin ready a tiempo -> error de timeout; reintentar vuelve a cargar',
    () async {
      final c = build(timeout: const Duration(milliseconds: 20))..start();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(c.state.status, MicroappStatus.error);
      expect(c.state.error, contains('tardó'));

      expect(c.start(), isTrue);
      expect(c.state.status, MicroappStatus.loading);
      c.onRawMessage(web('ready'));
      expect(c.state.status, MicroappStatus.ready);
      await c.close();
    },
  );

  test('error de carga -> estado de error', () async {
    final c = build()..start();
    c.onLoadError('net::ERR_INTERNET_DISCONNECTED');
    expect(c.state.status, MicroappStatus.error);
    await c.close();
  });

  test('servicio caído (chaos) -> no carga la web', () async {
    down = true;
    final c = build();
    expect(c.start(), isFalse);
    expect(c.state.status, MicroappStatus.error);
    await c.close();
  });

  test('mensajes inválidos no cambian el estado', () async {
    final c = build()..start();
    c.onRawMessage('<script>');
    expect(c.state.status, MicroappStatus.loading);
    await c.close();
  });
}
