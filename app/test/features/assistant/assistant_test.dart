import 'package:bloc_test/bloc_test.dart';
import 'package:fintech_platform/core/errors/failures.dart';
import 'package:fintech_platform/core/logging/app_logger.dart';
import 'package:fintech_platform/features/assistant/data/supabase_assistant_repository.dart';
import 'package:fintech_platform/features/assistant/domain/assistant_repository.dart';
import 'package:fintech_platform/features/assistant/presentation/assistant_cubit.dart';
import 'package:fintech_platform/features/assistant/presentation/assistant_page.dart';
import 'package:fintech_platform/sdui/sdui_action_handler.dart';
import 'package:fintech_platform/sdui/sdui_models.dart';
import 'package:fintech_platform/sdui/sdui_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_accounts_repository.dart';

const _answer = AssistantAnswer(
  answer: r'En los últimos 30 días gastaste $67.70 en comida.',
  source: AnswerSource.llm,
  layout: SduiLayout(
    version: 1,
    sections: [
      SduiSection(
        id: 'ai_0',
        type: 'insight',
        data: {'icon': 'insights', 'text': 'Comida es tu mayor gasto'},
      ),
      SduiSection(
        id: 'ai_1',
        type: 'banner',
        data: {'title': 'Meta sugerida', 'subtitle': r'Aparta $6.77'},
      ),
    ],
  ),
);

class _FakeAssistant implements AssistantRepository {
  _FakeAssistant(this.results);

  final List<Object> results;
  final asked = <String>[];

  @override
  Future<AssistantAnswer> ask(String question) async {
    asked.add(question);
    final r = results.removeAt(0);
    if (r is AppFailure) throw r;
    return r as AssistantAnswer;
  }
}

void main() {
  group('parseAnswer', () {
    test('respuesta completa con tarjetas SDUI', () {
      final a = SupabaseAssistantRepository.parseAnswer({
        'answer': 'Hola',
        'source': 'llm',
        'layout': {
          'version': 1,
          'sections': [
            {
              'id': 'ai_0',
              'type': 'insight',
              'props': {'text': 'x'},
            },
          ],
        },
      });
      expect(a.source, AnswerSource.llm);
      expect(a.layout.sections.single.type, 'insight');
    });

    test('layout inválido: se conserva el texto sin tarjetas', () {
      final a = SupabaseAssistantRepository.parseAnswer({
        'answer': 'Hola',
        'source': 'rules',
        'layout': 'roto',
      });
      expect(a.source, AnswerSource.rules);
      expect(a.layout.sections, isEmpty);
    });

    test('sin answer -> ServerFailure', () {
      expect(
        () => SupabaseAssistantRepository.parseAnswer({
          'layout': <String, Object?>{},
        }),
        throwsA(isA<ServerFailure>()),
      );
    });
  });

  group('AssistantCubit', () {
    blocTest<AssistantCubit, AssistantState>(
      'pregunta -> loading -> respuesta',
      build: () => AssistantCubit(_FakeAssistant([_answer])),
      act: (c) => c.ask('  ¿Cuánto gasté en comida?  '),
      expect: () => [
        const AssistantState(
          entries: [UserEntry('¿Cuánto gasté en comida?')],
          loading: true,
        ),
        const AssistantState(
          entries: [
            UserEntry('¿Cuánto gasté en comida?'),
            AnswerEntry(_answer),
          ],
        ),
      ],
    );

    blocTest<AssistantCubit, AssistantState>(
      'pregunta vacía se ignora',
      build: () => AssistantCubit(_FakeAssistant([])),
      act: (c) => c.ask('   '),
      expect: () => <AssistantState>[],
    );

    test('error -> reintentar sin duplicar la pregunta', () async {
      final repo = _FakeAssistant([const NetworkFailure(), _answer]);
      final c = AssistantCubit(repo);
      await c.ask('¿En qué gasto más?');
      final err = c.state.entries.last as ErrorEntry;
      expect(err.question, '¿En qué gasto más?');

      await c.retry(err);
      expect(c.state.entries, [
        const UserEntry('¿En qué gasto más?'),
        const AnswerEntry(_answer),
      ]);
      expect(repo.asked, ['¿En qué gasto más?', '¿En qué gasto más?']);
      await c.close();
    });
  });

  testWidgets('sugerencia -> respuesta con tarjetas SDUI generadas', (
    tester,
  ) async {
    final repo = _FakeAssistant([_answer]);
    await tester.pumpWidget(
      MaterialApp(
        home: AssistantPage(
          repository: repo,
          environment: SduiEnvironment(
            firstName: 'Ana',
            accounts: FakeAccountsRepository(),
            actions: const SduiActionHandler(logger: ConsoleLogger()),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const Key('assistant_suggestion_¿Cuánto gasté en comida?')),
    );
    await tester.pumpAndSettle();

    expect(repo.asked, ['¿Cuánto gasté en comida?']);
    expect(find.text(_answer.answer), findsOneWidget);
    expect(find.text('Generado con IA'), findsOneWidget);
    expect(find.text('Comida es tu mayor gasto'), findsOneWidget);
    expect(find.byKey(const Key('sdui_banner_ai_1')), findsOneWidget);
  });
}
