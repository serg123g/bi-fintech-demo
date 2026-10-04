import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Servicios que el panel chaos puede "tirar".
abstract final class ChaosServices {
  static const homeLayout = 'home-layout';
  static const accounts = 'accounts';
  static const microapp = 'microapp';
}

class ChaosConfig extends Equatable {
  const ChaosConfig({
    this.latency = Duration.zero,
    this.failureRate = 0,
    this.downServices = const {},
  });

  /// Latencia añadida a cada intento (0–5 s).
  final Duration latency;

  /// Probabilidad de fallo por intento (0.0–1.0).
  final double failureRate;

  /// Servicios completamente caídos.
  final Set<String> downServices;

  bool get isActive =>
      latency > Duration.zero || failureRate > 0 || downServices.isNotEmpty;

  bool isDown(String service) => downServices.contains(service);

  ChaosConfig copyWith({
    Duration? latency,
    double? failureRate,
    Set<String>? downServices,
  }) => ChaosConfig(
    latency: latency ?? this.latency,
    failureRate: failureRate ?? this.failureRate,
    downServices: downServices ?? this.downServices,
  );

  @override
  List<Object?> get props => [latency, failureRate, downServices];
}

/// Estado global del panel chaos (solo memoria: se apaga al reiniciar).
class ChaosController extends Cubit<ChaosConfig> {
  ChaosController() : super(const ChaosConfig());

  void setLatency(Duration value) => emit(state.copyWith(latency: value));

  void setFailureRate(double value) =>
      emit(state.copyWith(failureRate: value.clamp(0, 1).toDouble()));

  void setServiceDown(String service, {required bool down}) => emit(
    state.copyWith(
      downServices: down
          ? {...state.downServices, service}
          : ({...state.downServices}..remove(service)),
    ),
  );

  void apply(ChaosConfig preset) => emit(preset);

  void reset() => emit(const ChaosConfig());
}

/// Escenarios listos para la demo.
abstract final class ChaosPresets {
  static const slow = ChaosConfig(latency: Duration(seconds: 3));
  static const unstable = ChaosConfig(
    latency: Duration(seconds: 3),
    failureRate: 0.5,
  );
  static const homeDown = ChaosConfig(downServices: {ChaosServices.homeLayout});
  static const accountsDown = ChaosConfig(
    downServices: {ChaosServices.accounts},
  );
}
