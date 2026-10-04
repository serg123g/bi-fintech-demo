import 'package:equatable/equatable.dart';

enum DataSource { cache, network }

/// Datos + procedencia + antigüedad, para que la UI pueda decir
/// "actualizado hace X min" o "datos guardados".
class DataResult<T> extends Equatable {
  const DataResult(this.data, this.source, this.updatedAt);

  final T data;
  final DataSource source;
  final DateTime updatedAt;

  bool get isFromCache => source == DataSource.cache;

  @override
  List<Object?> get props => [data, source, updatedAt];
}
