import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../domain/assistant_repository.dart';

sealed class ChatEntry extends Equatable {
  const ChatEntry();
}

final class UserEntry extends ChatEntry {
  const UserEntry(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

final class AnswerEntry extends ChatEntry {
  const AnswerEntry(this.answer);

  final AssistantAnswer answer;

  @override
  List<Object?> get props => [answer];
}

final class ErrorEntry extends ChatEntry {
  const ErrorEntry({required this.message, required this.question});

  final String message;

  /// Pregunta a reintentar.
  final String question;

  @override
  List<Object?> get props => [message, question];
}

class AssistantState extends Equatable {
  const AssistantState({this.entries = const [], this.loading = false});

  final List<ChatEntry> entries;
  final bool loading;

  @override
  List<Object?> get props => [entries, loading];
}

class AssistantCubit extends Cubit<AssistantState> {
  AssistantCubit(this._repository) : super(const AssistantState());

  final AssistantRepository _repository;

  static const maxLength = 300;

  Future<void> ask(String raw) async {
    final question = raw.trim();
    if (question.isEmpty || state.loading) return;
    final q = question.length > maxLength
        ? question.substring(0, maxLength)
        : question;
    emit(
      AssistantState(entries: [...state.entries, UserEntry(q)], loading: true),
    );
    await _send(q);
  }

  /// Reintenta una pregunta fallida sin duplicarla en el historial.
  Future<void> retry(ErrorEntry entry) async {
    if (state.loading) return;
    emit(
      AssistantState(
        entries: state.entries.where((e) => e != entry).toList(),
        loading: true,
      ),
    );
    await _send(entry.question);
  }

  Future<void> _send(String q) async {
    ChatEntry result;
    try {
      result = AnswerEntry(await _repository.ask(q));
    } on AppFailure catch (f) {
      result = ErrorEntry(message: f.message, question: q);
    }
    if (isClosed) return;
    emit(AssistantState(entries: [...state.entries, result]));
  }
}
