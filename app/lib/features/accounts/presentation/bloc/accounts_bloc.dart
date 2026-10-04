import '../../../../core/cache/data_result.dart';
import '../../../../core/presentation/swr_bloc.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/accounts_repository.dart';

class AccountsBloc extends SwrBloc<List<Account>> {
  AccountsBloc(this._repository);

  final AccountsRepository _repository;

  @override
  Stream<DataResult<List<Account>>> load() => _repository.watchAccounts();
}
