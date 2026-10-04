import 'package:equatable/equatable.dart';

enum AccountType {
  ahorros('Cuenta de ahorros'),
  corriente('Cuenta corriente');

  const AccountType(this.label);

  final String label;

  static AccountType fromName(String? v) => AccountType.values.firstWhere(
    (t) => t.name == v,
    orElse: () => AccountType.ahorros,
  );
}

class Account extends Equatable {
  const Account({
    required this.id,
    required this.type,
    required this.numberMasked,
    required this.balanceCents,
    this.currency = 'USD',
  });

  final String id;
  final AccountType type;
  final String numberMasked;

  /// Dinero en centavos (entero) para no arrastrar errores de punto flotante.
  final int balanceCents;
  final String currency;

  @override
  List<Object?> get props => [id, type, numberMasked, balanceCents, currency];
}
