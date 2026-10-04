import '../../../core/cache/data_result.dart';
import '../../../sdui/sdui_models.dart';

/// Layout del home, en orden de preferencia:
/// red (personalizado) -> último layout guardado -> layout empaquetado.
abstract interface class HomeLayoutRepository {
  Stream<DataResult<SduiLayout>> watchHome();
}
