import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'connectivity_service.dart';

/// `true` = online. Arranca optimista para no mostrar el banner en falso.
class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit(this._service) : super(true) {
    _subscription = _service.onlineChanges.listen(_set);
    _service.isOnline().then(_set).ignore();
  }

  final ConnectivityService _service;
  late final StreamSubscription<bool> _subscription;

  void _set(bool online) {
    if (!isClosed) emit(online);
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
