import 'package:equatable/equatable.dart';

import '../../../sdui/sdui_models.dart';

/// Origen de la respuesta: LLM o reglas determinísticas (fallback).
enum AnswerSource { llm, rules }

class AssistantAnswer extends Equatable {
  const AssistantAnswer({
    required this.answer,
    required this.source,
    required this.layout,
  });

  final String answer;
  final AnswerSource source;

  /// Tarjetas generadas dinámicamente, en el mismo contrato SDUI v1 del home.
  final SduiLayout layout;

  @override
  List<Object?> get props => [answer, source, layout];
}

/// El servidor responde sobre AGREGADOS de los movimientos (nunca crudos).
abstract interface class AssistantRepository {
  Future<AssistantAnswer> ask(String question);
}
