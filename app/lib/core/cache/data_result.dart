import 'package:equatable/equatable.dart';

enum DataSource {
  cache,
  network,

  /// Contenido empaquetado en la app (último recurso sin red ni cache).
  fallback,
}

/// Datos + procedencia + antigüedad, para que la UI pueda decir
/// "actualizado hace X min" o "datos guardados".
class DataResult<T> extends Equatable {
  const DataResult(this.data, this.source, this.updatedAt);

  final T data;
  final DataSource source;
  final DateTime updatedAt;

  /// Cualquier dato que no viene fresco de la red.
  bool get isFromCache => source != DataSource.network;

  @override
  List<Object?> get props => [data, source, updatedAt];
}
