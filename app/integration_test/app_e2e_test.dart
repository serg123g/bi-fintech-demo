import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/e2e/critical_flow.dart';

/// E2E en emulador/dispositivo real (UI, plugins y motor gráfico reales; los
/// bordes de red con fakes deterministas).
///
///   cd app && flutter test integration_test -d `DEVICE_ID`
///
/// Variante contra Supabase real: correr la app con `./scripts/run.sh` y
/// seguir el recorrido manual del README (usuarios de prueba del seed).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E: login -> home -> cuentas -> movimientos -> logout', (
    tester,
  ) async {
    await runCriticalFlow(tester);
  });

  testWidgets('E2E: home-layout caído usa el layout empaquetado', (
    tester,
  ) async {
    await runDegradedHomeFlow(tester);
  });
}
