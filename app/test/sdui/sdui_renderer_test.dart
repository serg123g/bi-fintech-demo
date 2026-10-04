import 'package:fintech_platform/core/errors/failures.dart';
import 'package:fintech_platform/core/logging/app_logger.dart';
import 'package:fintech_platform/sdui/sdui_action_handler.dart';
import 'package:fintech_platform/sdui/sdui_models.dart';
import 'package:fintech_platform/sdui/sdui_registry.dart';
import 'package:fintech_platform/sdui/sdui_renderer.dart';
import 'package:fintech_platform/sdui/sdui_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_accounts_repository.dart';

void main() {
  Widget host(SduiLayout layout, {SduiRegistry? registry}) => MaterialApp(
    home: Scaffold(
      body: SduiScope(
        environment: SduiEnvironment(
          firstName: 'Ana',
          accounts: FakeAccountsRepository(),
          actions: const SduiActionHandler(logger: ConsoleLogger()),
        ),
        child: SduiRenderer(
          layout: layout,
          registry: registry ?? SduiRegistry.defaults(),
        ),
      ),
    ),
  );

  testWidgets('renderiza las secciones conocidas en orden', (tester) async {
    await tester.pumpWidget(
      host(
        const SduiLayout(
          version: 1,
          sections: [
            SduiSection(
              id: 'g',
              type: 'greeting',
              data: {'text': 'Buenas tardes, {first_name}'},
            ),
            SduiSection(id: 'acc', type: 'accounts_summary'),
            SduiSection(
              id: 'fondo',
              type: 'banner',
              data: {'title': 'Arma tu fondo de emergencia'},
            ),
            SduiSection(
              id: 'inv',
              type: 'offer_card',
              data: {'title': 'Inversión', 'body': 'Tasa preferencial'},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Buenas tardes, Ana'), findsOneWidget);
    expect(find.byKey(const Key('sdui_accounts_summary')), findsOneWidget);
    expect(find.text(r'$4,473.21'), findsOneWidget);
    expect(find.byKey(const Key('sdui_banner_fondo')), findsOneWidget);
    expect(find.byKey(const Key('sdui_offer_inv')), findsOneWidget);
  });

  testWidgets('tipo desconocido se ignora sin romper la pantalla', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SduiLayout(
          version: 1,
          sections: [
            SduiSection(id: 'x', type: 'carrusel_3d', data: {'a': 1}),
            SduiSection(
              id: 'g',
              type: 'greeting',
              data: {'text': 'Hola, {first_name}'},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Hola, Ana'), findsOneWidget);
  });

  testWidgets('props inválidas: solo esa sección se omite (fallo parcial)', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SduiLayout(
          version: 1,
          sections: [
            SduiSection(id: 'roto', type: 'banner'), // sin title
            SduiSection(id: 'ok', type: 'banner', data: {'title': 'Sigo aquí'}),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sdui_banner_roto')), findsNothing);
    expect(find.text('Sigo aquí'), findsOneWidget);
  });

  testWidgets('si falla el saldo, solo esa tarjeta muestra error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SduiScope(
            environment: SduiEnvironment(
              firstName: 'Ana',
              accounts: FakeAccountsRepository(
                accountsScripts: [
                  [const NetworkFailure()],
                ],
              ),
              actions: const SduiActionHandler(logger: ConsoleLogger()),
            ),
            child: SduiRenderer(
              layout: const SduiLayout(
                version: 1,
                sections: [
                  SduiSection(id: 'acc', type: 'accounts_summary'),
                  SduiSection(
                    id: 'g',
                    type: 'greeting',
                    data: {'text': 'Hola'},
                  ),
                ],
              ),
              registry: SduiRegistry.defaults(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sdui_accounts_error')), findsOneWidget);
    expect(find.text('Hola'), findsOneWidget);
  });

  test('lista blanca de rutas para acciones SDUI', () {
    expect(SduiActionHandler.isAllowedRoute('/accounts'), isTrue);
    expect(SduiActionHandler.isAllowedRoute('/accounts/a1'), isTrue);
    expect(SduiActionHandler.isAllowedRoute('/debug'), isFalse);
    expect(SduiActionHandler.isAllowedRoute('//evil.com'), isFalse);
    expect(SduiActionHandler.isAllowedRoute('https://evil.com'), isFalse);
  });
}
