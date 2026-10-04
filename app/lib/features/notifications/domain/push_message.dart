import 'package:equatable/equatable.dart';

/// Mensaje push independiente del SDK (Firebase) para poder testear.
class PushMessage extends Equatable {
  const PushMessage({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;
  final Map<String, Object?> data;

  @override
  List<Object?> get props => [title, body, data];
}

final _id = RegExp(r'^[A-Za-z0-9-]{1,64}$');

/// Ruta interna a abrir al tocar la notificación, o `null` si el payload no
/// es válido. Nunca se navega a rutas arbitrarias enviadas por el servidor:
/// se reconstruye a partir de ids validados.
String? routeFromPush(Map<String, Object?> data) {
  final accountId = data['account_id'];
  final movementId = data['movement_id'];
  if (accountId is! String || movementId is! String) return null;
  if (!_id.hasMatch(accountId) || !_id.hasMatch(movementId)) return null;
  return '/accounts/$accountId/movements/$movementId';
}
