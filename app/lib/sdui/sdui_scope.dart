import 'package:flutter/widgets.dart';

import '../features/accounts/domain/repositories/accounts_repository.dart';
import 'sdui_action_handler.dart';

/// Dependencias que los componentes SDUI necesitan del host.
class SduiEnvironment {
  const SduiEnvironment({
    required this.firstName,
    required this.accounts,
    required this.actions,
  });

  final String firstName;
  final AccountsRepository accounts;
  final SduiActionHandler actions;

  /// Plantillas simples en textos del backend/fallback: {first_name}.
  String interpolate(String text) => text
      .replaceAll('{first_name}', firstName)
      .replaceAll(RegExp(r',\s*$'), '');
}

class SduiScope extends InheritedWidget {
  const SduiScope({required this.environment, required super.child, super.key});

  final SduiEnvironment environment;

  static SduiEnvironment of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SduiScope>();
    assert(scope != null, 'SduiScope no encontrado');
    return scope!.environment;
  }

  @override
  bool updateShouldNotify(SduiScope oldWidget) =>
      environment != oldWidget.environment;
}
