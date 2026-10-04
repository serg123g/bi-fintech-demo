import 'package:fintech_platform/features/accounts/presentation/pages/movement_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_accounts_repository.dart';

void main() {
  testWidgets('abre el detalle solo con el id (deep link)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MovementDetailPage(
          movementId: 'm2',
          repository: FakeAccountsRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('movement_detail_m2')), findsOneWidget);
    expect(find.text(r'+$250.00'), findsOneWidget);
    expect(find.text('Pago freelance diseño web'), findsOneWidget);
    expect(find.text('Crédito'), findsOneWidget);
  });

  testWidgets('movimiento inexistente: error con reintentar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MovementDetailPage(
          movementId: 'otro-usuario',
          repository: FakeAccountsRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No encontramos este movimiento.'), findsOneWidget);
    expect(find.byKey(const Key('retry_button')), findsOneWidget);
  });
}
