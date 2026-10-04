import 'package:fintech_platform/core/cache/data_result.dart';
import 'package:fintech_platform/features/home/domain/home_layout_repository.dart';
import 'package:fintech_platform/sdui/sdui_models.dart';

const testHomeLayout = SduiLayout(
  version: 1,
  layoutId: 'test',
  sections: [
    SduiSection(
      id: 'greeting',
      type: 'greeting',
      data: {'text': 'Hola, {first_name}'},
    ),
    SduiSection(id: 'accounts', type: 'accounts_summary'),
  ],
);

class FakeHomeLayoutRepository implements HomeLayoutRepository {
  FakeHomeLayoutRepository([this.layout = testHomeLayout]);

  final SduiLayout layout;

  @override
  Stream<DataResult<SduiLayout>> watchHome() =>
      Stream.value(DataResult(layout, DataSource.network, DateTime.now()));
}
