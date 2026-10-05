import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../design_system/app_theme.dart';
import '../../../sdui/sdui_registry.dart';
import '../../../sdui/sdui_renderer.dart';
import '../../../sdui/sdui_scope.dart';
import '../domain/assistant_repository.dart';
import 'assistant_cubit.dart';

/// Chat con el asistente. Las respuestas traen tarjetas SDUI generadas por
/// el LLM (saneadas en el servidor) que se dibujan con el mismo registry del
/// home: experiencia generada dinámicamente sin publicar la app.
class AssistantPage extends StatelessWidget {
  const AssistantPage({
    required this.repository,
    required this.environment,
    super.key,
  });

  final AssistantRepository repository;
  final SduiEnvironment environment;

  static const suggestions = [
    '¿Cuánto gasté en comida?',
    '¿En qué gasto más?',
    '¿Cómo puedo ahorrar?',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AssistantCubit(repository),
      child: SduiScope(environment: environment, child: const _AssistantView()),
    );
  }
}

class _AssistantView extends StatefulWidget {
  const _AssistantView();

  @override
  State<_AssistantView> createState() => _AssistantViewState();
}

class _AssistantViewState extends State<_AssistantView> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final q = text ?? _input.text;
    if (q.trim().isEmpty) return;
    _input.clear();
    context.read<AssistantCubit>().ask(q);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Asistente')),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<AssistantCubit, AssistantState>(
              builder: (context, state) {
                if (state.entries.isEmpty && !state.loading) {
                  return _Empty(onSuggestion: _send);
                }
                return ListView(
                  key: const Key('assistant_chat'),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    for (final e in state.entries)
                      switch (e) {
                        UserEntry(:final text) => _UserBubble(text: text),
                        AnswerEntry(:final answer) => _AnswerBubble(answer),
                        final ErrorEntry err => _ErrorBubble(entry: err),
                      },
                    if (state.loading)
                      const Padding(
                        key: Key('assistant_loading'),
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Text('Analizando tus movimientos…'),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'Usa solo totales por categoría de tus últimos 30 días. '
              'No es asesoría financiera.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: BlocBuilder<AssistantCubit, AssistantState>(
                buildWhen: (a, b) => a.loading != b.loading,
                builder: (context, state) => Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('assistant_input'),
                        controller: _input,
                        enabled: !state.loading,
                        maxLength: AssistantCubit.maxLength,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Pregunta sobre tus gastos',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filled(
                      key: const Key('assistant_send'),
                      tooltip: 'Enviar',
                      onPressed: state.loading ? null : _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onSuggestion});

  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Icon(Icons.auto_awesome, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Pregúntame sobre tus gastos',
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final s in AssistantPage.suggestions)
              ActionChip(
                key: Key('assistant_suggestion_$s'),
                label: Text(s),
                onPressed: () => onSuggestion(s),
              ),
          ],
        ),
      ],
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm, left: 48),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Text(text, style: TextStyle(color: scheme.onPrimary)),
      ),
    );
  }
}

class _AnswerBubble extends StatelessWidget {
  const _AnswerBubble(this.answer);

  final AssistantAnswer answer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Text(answer.answer, key: const Key('assistant_answer')),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs, left: 4),
            child: Text(
              answer.source == AnswerSource.llm
                  ? 'Generado con IA'
                  : 'Respuesta automática',
              style: theme.textTheme.labelSmall,
            ),
          ),
          if (answer.layout.sections.isNotEmpty)
            SduiRenderer(
              key: const Key('assistant_cards'),
              layout: answer.layout,
              registry: SduiRegistry.defaults(),
              embedded: true,
            ),
        ],
      ),
    );
  }
}

class _ErrorBubble extends StatelessWidget {
  const _ErrorBubble({required this.entry});

  final ErrorEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('assistant_error'),
      color: scheme.errorContainer,
      child: ListTile(
        leading: Icon(Icons.error_outline, color: scheme.onErrorContainer),
        title: Text(entry.message),
        trailing: TextButton(
          key: const Key('assistant_retry'),
          onPressed: () => context.read<AssistantCubit>().retry(entry),
          child: const Text('Reintentar'),
        ),
      ),
    );
  }
}
