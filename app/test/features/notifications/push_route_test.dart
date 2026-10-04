import 'package:fintech_platform/features/notifications/domain/push_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('payload válido -> detalle del movimiento', () {
    expect(
      routeFromPush({'account_id': 'a-1', 'movement_id': 'm-1'}),
      '/accounts/a-1/movements/m-1',
    );
  });

  test('ignora la ruta enviada por el servidor y reconstruye con ids', () {
    expect(
      routeFromPush({
        'route': '/debug',
        'account_id': 'a-1',
        'movement_id': 'm-1',
      }),
      '/accounts/a-1/movements/m-1',
    );
  });

  test('payload incompleto o con ids inválidos -> null', () {
    expect(routeFromPush({}), isNull);
    expect(routeFromPush({'account_id': 'a-1'}), isNull);
    expect(
      routeFromPush({'account_id': '../debug', 'movement_id': 'm-1'}),
      isNull,
    );
    expect(routeFromPush({'account_id': 1, 'movement_id': 'm-1'}), isNull);
  });
}
