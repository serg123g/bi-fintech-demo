import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cache/data_result.dart';
import '../errors/failures.dart';
import 'resource_state.dart';

final class ResourceRequested extends Equatable {
  const ResourceRequested();

  @override
  List<Object?> get props => [];
}

/// Bloc base para lecturas stale-while-revalidate.
///
/// Las peticiones se procesan en secuencia (un pull-to-refresh repetido no
/// dispara llamadas en paralelo).
abstract class SwrBloc<T> extends Bloc<ResourceRequested, ResourceState<T>> {
  SwrBloc() : super(ResourceState<T>()) {
    on<ResourceRequested>(
      _onRequested,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }

  /// Fuente de datos: emite cache y luego red; error = AppFailure.
  Stream<DataResult<T>> load();

  Future<void> _onRequested(
    ResourceRequested event,
    Emitter<ResourceState<T>> emit,
  ) async {
    emit(
      state.hasData
          ? state.copyWith(isRefreshing: true, clearFailure: true)
          : state.copyWith(status: ResourceStatus.loading, clearFailure: true),
    );

    await emit.onEach<DataResult<T>>(
      load(),
      onData: (r) => emit(
        state.copyWith(
          status: ResourceStatus.success,
          data: r.data,
          updatedAt: r.updatedAt,
          fromCache: r.isFromCache,
          // Si vino de cache, la red sigue en curso.
          isRefreshing: r.isFromCache,
        ),
      ),
      onError: (error, _) {
        final failure = error is AppFailure ? error : const UnexpectedFailure();
        emit(
          state.copyWith(
            status: state.hasData
                ? ResourceStatus.success
                : ResourceStatus.failure,
            isRefreshing: false,
            failure: failure,
          ),
        );
      },
    );
  }
}
