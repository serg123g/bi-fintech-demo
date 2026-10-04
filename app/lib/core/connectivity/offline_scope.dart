import 'package:flutter/widgets.dart';

/// Expone "estoy offline" a cualquier widget sin acoplarlo a un Bloc.
/// Lo publica [OfflineBanner]; si no hay scope (tests), se asume online.
class OfflineScope extends InheritedWidget {
  const OfflineScope({
    required this.isOffline,
    required super.child,
    super.key,
  });

  final bool isOffline;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OfflineScope>()?.isOffline ??
      false;

  @override
  bool updateShouldNotify(OfflineScope oldWidget) =>
      isOffline != oldWidget.isOffline;
}
