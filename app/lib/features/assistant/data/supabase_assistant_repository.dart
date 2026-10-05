import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/resilient_executor.dart';
import '../../../sdui/sdui_models.dart';
import '../../../sdui/sdui_parser.dart';
import '../domain/assistant_repository.dart';

class SupabaseAssistantRepository implements AssistantRepository {
  SupabaseAssistantRepository(this._client, this._executor);

  static const service = 'assistant';
  static const _empty = SduiLayout(version: 1, sections: []);

  final SupabaseClient _client;
  final ResilientExecutor _executor;

  @override
  Future<AssistantAnswer> ask(String question) => _executor.run(
    service,
    (ctx) async {
      final Object? data;
      try {
        final res = await _client.functions.invoke(
          service,
          body: {'question': question},
          headers: ctx.headers,
        );
        data = res.data;
      } on FunctionException catch (e) {
        if (e.status == 403) {
          throw const ServerFailure(
            message: 'El asistente no está disponible en este momento.',
            retryable: false,
          );
        }
        rethrow;
      }
      return parseAnswer(data is String ? jsonDecode(data) : data);
    },
    // Cada llamada consume tokens del LLM: no se reintenta automáticamente.
    idempotent: false,
  );

  /// Parser tolerante de la respuesta (público para tests).
  static AssistantAnswer parseAnswer(Object? json) {
    if (json is! Map<String, dynamic> || json['answer'] is! String) {
      throw const ServerFailure(
        message: 'No pudimos entender la respuesta del asistente.',
        retryable: false,
      );
    }
    SduiLayout layout;
    try {
      layout = SduiParser.parse(json['layout']);
    } on FormatException {
      layout = _empty; // la respuesta en texto sigue siendo útil
    }
    return AssistantAnswer(
      answer: json['answer'] as String,
      source: json['source'] == 'llm' ? AnswerSource.llm : AnswerSource.rules,
      layout: layout,
    );
  }
}
