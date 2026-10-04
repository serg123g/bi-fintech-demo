import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapta un Stream (p. ej. el de AuthBloc) a Listenable para que GoRouter
/// re-evalúe `redirect` en cada cambio.
class StreamListenable extends ChangeNotifier {
  StreamListenable(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    _subscription.cancel().ignore();
    super.dispose();
  }
}
