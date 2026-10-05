import 'package:flutter_test/flutter_test.dart';

import 'critical_flow.dart';

/// E2E en VM (sin emulador): corre en cada push en CI.
/// La misma secuencia corre en dispositivo real desde integration_test/.
void main() {
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
