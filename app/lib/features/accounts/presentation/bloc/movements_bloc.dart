import '../../../../core/cache/data_result.dart';
import '../../../../core/presentation/swr_bloc.dart';
import '../../domain/entities/movement.dart';
import '../../domain/repositories/accounts_repository.dart';

class MovementsBloc extends SwrBloc<List<Movement>> {
  MovementsBloc(this._repository, this.accountId);

  final AccountsRepository _repository;
  final String accountId;

  @override
  Stream<DataResult<List<Movement>>> load() =>
      _repository.watchMovements(accountId);
}
