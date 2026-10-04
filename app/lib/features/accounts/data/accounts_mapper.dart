import 'dart:convert';

import '../domain/entities/account.dart';
import '../domain/entities/movement.dart';

/// Conversión fila Postgres <-> entidad <-> JSON de cache.
abstract final class AccountsMapper {
  static int _cents(Object? v) => ((v as num? ?? 0) * 100).round();

  static Account accountFromRow(Map<String, dynamic> r) => Account(
    id: r['id'] as String,
    type: AccountType.fromName(r['type'] as String?),
    numberMasked: r['number_masked'] as String? ?? '****',
    balanceCents: r.containsKey('balance_cents')
        ? (r['balance_cents'] as num).toInt()
        : _cents(r['balance']),
    currency: (r['currency'] as String? ?? 'USD').trim(),
  );

  static Map<String, Object?> accountToJson(Account a) => {
    'id': a.id,
    'type': a.type.name,
    'number_masked': a.numberMasked,
    'balance_cents': a.balanceCents,
    'currency': a.currency,
  };

  static Movement movementFromRow(Map<String, dynamic> r) => Movement(
    id: r['id'] as String,
    accountId: r['account_id'] as String,
    amountCents: r.containsKey('amount_cents')
        ? (r['amount_cents'] as num).toInt()
        : _cents(r['amount']),
    description: r['description'] as String? ?? '',
    category: MovementCategory.fromName(r['category'] as String?),
    createdAt: DateTime.parse(r['created_at'] as String),
  );

  static Map<String, Object?> movementToJson(Movement m) => {
    'id': m.id,
    'account_id': m.accountId,
    'amount_cents': m.amountCents,
    'description': m.description,
    'category': m.category.name,
    'created_at': m.createdAt.toIso8601String(),
  };

  static String encodeAccounts(List<Account> v) =>
      jsonEncode(v.map(accountToJson).toList());

  static List<Account> decodeAccounts(String s) =>
      (jsonDecode(s) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(accountFromRow)
          .toList();

  static String encodeMovements(List<Movement> v) =>
      jsonEncode(v.map(movementToJson).toList());

  static List<Movement> decodeMovements(String s) =>
      (jsonDecode(s) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(movementFromRow)
          .toList();
}
