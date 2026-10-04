import 'package:connectivity_plus/connectivity_plus.dart';

/// Señal de conectividad del dispositivo. Es una pista para la UX (banner
/// offline, no insistir con reintentos): la fuente de verdad sigue siendo
/// el resultado real de cada request.
abstract interface class ConnectivityService {
  Future<bool> isOnline();
  Stream<bool> get onlineChanges;
}

class PlusConnectivityService implements ConnectivityService {
  PlusConnectivityService([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _online(List<ConnectivityResult> r) =>
      r.any((c) => c != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async =>
      _online(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get onlineChanges =>
      _connectivity.onConnectivityChanged.map(_online).distinct();
}
