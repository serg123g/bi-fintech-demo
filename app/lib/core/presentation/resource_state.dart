import 'package:equatable/equatable.dart';

import '../errors/failures.dart';

enum ResourceStatus { initial, loading, success, failure }

/// Estado genérico para pantallas que muestran datos remotos con cache.
///
/// Combinaciones relevantes para la UX:
/// * loading sin data            -> skeleton
/// * success + fromCache         -> datos + "actualizado hace X"
/// * success + refreshFailure    -> datos guardados + aviso de error
/// * failure sin data            -> pantalla de error con reintentar
class ResourceState<T> extends Equatable {
  const ResourceState({
    this.status = ResourceStatus.initial,
    this.data,
    this.updatedAt,
    this.fromCache = false,
    this.isRefreshing = false,
    this.failure,
  });

  final ResourceStatus status;
  final T? data;
  final DateTime? updatedAt;
  final bool fromCache;
  final bool isRefreshing;

  /// Error de la última operación (con o sin datos previos).
  final AppFailure? failure;

  bool get hasData => data != null;

  ResourceState<T> copyWith({
    ResourceStatus? status,
    T? data,
    DateTime? updatedAt,
    bool? fromCache,
    bool? isRefreshing,
    AppFailure? failure,
    bool clearFailure = false,
  }) => ResourceState<T>(
    status: status ?? this.status,
    data: data ?? this.data,
    updatedAt: updatedAt ?? this.updatedAt,
    fromCache: fromCache ?? this.fromCache,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => [
    status,
    data,
    updatedAt,
    fromCache,
    isRefreshing,
    failure,
  ];
}
