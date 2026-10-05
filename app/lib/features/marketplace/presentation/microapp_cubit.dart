import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/microapp_protocol.dart';

enum MicroappStatus { loading, ready, error }

class MicroappState extends Equatable {
  const MicroappState({this.status = MicroappStatus.loading, this.error});

  final MicroappStatus status;
  final String? error;

  @override
  List<Object?> get props => [status, error];
}

/// Ciclo de vida de una micro-app, independiente del WebView (testeable):
///
/// loading --(ready)--> ready
///    |  \--(timeout sin `ready`)--> error
///    \--(error de carga / servicio caído)--> error --(retry)--> loading
class MicroappCubit extends Cubit<MicroappState> {
  MicroappCubit({
    required this.initMessage,
    required this.send,
    required this.onBenefitSelected,
    required this.onClose,
    this.isDown = _never,
    this.readyTimeout = const Duration(seconds: 10),
  }) : super(const MicroappState());

  /// Mensaje `init` (contexto del cliente) que se envía al recibir `ready`.
  final String initMessage;
  final void Function(String json) send;
  final void Function(BenefitSelectedMessage) onBenefitSelected;
  final void Function() onClose;
  final bool Function() isDown;
  final Duration readyTimeout;

  Timer? _timer;

  static bool _never() => false;

  /// Devuelve `false` si no hay que cargar la web (servicio caído).
  bool start() {
    _timer?.cancel();
    if (isDown()) {
      emit(
        const MicroappState(
          status: MicroappStatus.error,
          error: 'Este servicio no está disponible en este momento.',
        ),
      );
      return false;
    }
    emit(const MicroappState());
    _timer = Timer(readyTimeout, () {
      if (!isClosed && state.status == MicroappStatus.loading) {
        emit(
          const MicroappState(
            status: MicroappStatus.error,
            error: 'La página tardó demasiado en responder.',
          ),
        );
      }
    });
    return true;
  }

  void onLoadError(String description) {
    _timer?.cancel();
    emit(
      const MicroappState(
        status: MicroappStatus.error,
        error: 'No pudimos cargar esta sección. Revisa tu conexión.',
      ),
    );
  }

  void onRawMessage(String raw) {
    switch (MicroappProtocol.parse(raw)) {
      case ReadyMessage():
        _timer?.cancel();
        send(initMessage);
        emit(const MicroappState(status: MicroappStatus.ready));
      case final BenefitSelectedMessage m:
        onBenefitSelected(m);
      case CloseMessage():
        onClose();
      case InvalidMessage():
        break; // se ignora: la web no puede romper la app
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
