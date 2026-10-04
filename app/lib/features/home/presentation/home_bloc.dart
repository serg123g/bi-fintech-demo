import '../../../core/cache/data_result.dart';
import '../../../core/presentation/swr_bloc.dart';
import '../../../sdui/sdui_models.dart';
import '../domain/home_layout_repository.dart';

class HomeBloc extends SwrBloc<SduiLayout> {
  HomeBloc(this._repository);

  final HomeLayoutRepository _repository;

  @override
  Stream<DataResult<SduiLayout>> load() => _repository.watchHome();
}
