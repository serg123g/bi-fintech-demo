import 'package:flutter/material.dart';

/// Lista blanca de íconos que el backend puede pedir por nombre.
/// Un nombre desconocido usa un ícono neutro (nunca rompe la UI).
abstract final class SduiIcons {
  static const _icons = <String, IconData>{
    'send': Icons.send_outlined,
    'request_quote': Icons.request_quote_outlined,
    'account_balance_wallet': Icons.account_balance_wallet_outlined,
    'storefront': Icons.storefront_outlined,
    'savings': Icons.savings_outlined,
    'trending_up': Icons.trending_up,
    'insights': Icons.insights_outlined,
    'info': Icons.info_outline,
    'warning': Icons.warning_amber_outlined,
    'credit_card': Icons.credit_card,
    'qr': Icons.qr_code_2,
    'support': Icons.support_agent,
  };

  static IconData of(String? name) => _icons[name] ?? Icons.circle_outlined;
}
