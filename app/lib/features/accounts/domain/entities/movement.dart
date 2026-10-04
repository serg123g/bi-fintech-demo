import 'package:equatable/equatable.dart';

enum MovementCategory {
  ingreso('Ingreso'),
  transferencia('Transferencia'),
  comida('Comida'),
  transporte('Transporte'),
  servicios('Servicios'),
  compras('Compras'),
  salud('Salud'),
  entretenimiento('Entretenimiento'),
  otros('Otros');

  const MovementCategory(this.label);

  final String label;

  static MovementCategory fromName(String? v) => MovementCategory.values
      .firstWhere((c) => c.name == v, orElse: () => MovementCategory.otros);
}

class Movement extends Equatable {
  const Movement({
    required this.id,
    required this.accountId,
    required this.amountCents,
    required this.description,
    required this.category,
    required this.createdAt,
  });

  final String id;
  final String accountId;

  /// Positivo = crédito, negativo = débito.
  final int amountCents;
  final String description;
  final MovementCategory category;
  final DateTime createdAt;

  bool get isCredit => amountCents > 0;

  @override
  List<Object?> get props => [
    id,
    accountId,
    amountCents,
    description,
    category,
    createdAt,
  ];
}
