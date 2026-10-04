import '../../../../core/cache/data_result.dart';
import '../../../../core/presentation/swr_bloc.dart';
import '../../domain/entities/movement.dart';
import '../../domain/repositories/accounts_repository.dart';

class MovementDetailBloc extends SwrBloc<Movement> {
  MovementDetailBloc(this._repository, this.movementId);

  final AccountsRepository _repository;
  final String movementId;

  @override
  Stream<DataResult<Movement>> load() => _repository.watchMovement(movementId);
}
