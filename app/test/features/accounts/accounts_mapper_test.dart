import 'package:fintech_platform/features/accounts/data/accounts_mapper.dart';
import 'package:fintech_platform/features/accounts/domain/entities/account.dart';
import 'package:fintech_platform/features/accounts/domain/entities/movement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fila de Postgres -> Account con centavos exactos', () {
    final a = AccountsMapper.accountFromRow({
      'id': 'a1',
      'type': 'corriente',
      'number_masked': '****7310',
      'balance': 4412.4,
      'currency': 'USD',
    });
    expect(a.balanceCents, 441240);
    expect(a.type, AccountType.corriente);
  });

  test('60.81 no pierde precisión (float) al pasar a centavos', () {
    final a = AccountsMapper.accountFromRow({
      'id': 'a1',
      'type': 'ahorros',
      'number_masked': '****4821',
      'balance': 60.81,
    });
    expect(a.balanceCents, 6081);
  });

  test('ida y vuelta por la cache conserva los datos', () {
    final movements = [
      Movement(
        id: 'm1',
        accountId: 'a1',
        amountCents: -4530,
        description: 'Supermercado',
        category: MovementCategory.comida,
        createdAt: DateTime.utc(2026, 9, 20, 15),
      ),
    ];
    final json = AccountsMapper.encodeMovements(movements);
    expect(AccountsMapper.decodeMovements(json), movements);
  });

  test('categoría desconocida cae en otros', () {
    expect(MovementCategory.fromName('cripto'), MovementCategory.otros);
  });
}
