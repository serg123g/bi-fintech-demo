import 'package:equatable/equatable.dart';

/// Acciones tipadas del contrato SDUI. El backend nunca envía código, solo
/// intenciones que la app valida y ejecuta.
sealed class SduiAction extends Equatable {
  const SduiAction();

  static SduiAction? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final value = json['value'];
    if (value is! String || value.isEmpty) return null;
    return switch (json['type']) {
      'route' => RouteAction(value),
      'url' => UrlAction(value),
      'microapp' => MicroappAction(value),
      final Object? other => UnknownAction(other?.toString() ?? '', value),
    };
  }

  Map<String, Object?> toJson();
}

final class RouteAction extends SduiAction {
  const RouteAction(this.path);

  final String path;

  @override
  Map<String, Object?> toJson() => {'type': 'route', 'value': path};

  @override
  List<Object?> get props => [path];
}

final class UrlAction extends SduiAction {
  const UrlAction(this.url);

  final String url;

  @override
  Map<String, Object?> toJson() => {'type': 'url', 'value': url};

  @override
  List<Object?> get props => [url];
}

final class MicroappAction extends SduiAction {
  const MicroappAction(this.id);

  final String id;

  @override
  Map<String, Object?> toJson() => {'type': 'microapp', 'value': id};

  @override
  List<Object?> get props => [id];
}

/// Tipo de acción que esta versión de la app no conoce: se ignora.
final class UnknownAction extends SduiAction {
  const UnknownAction(this.type, this.value);

  final String type;
  final String value;

  @override
  Map<String, Object?> toJson() => {'type': type, 'value': value};

  @override
  List<Object?> get props => [type, value];
}

class SduiSection extends Equatable {
  const SduiSection({
    required this.id,
    required this.type,
    this.data = const {},
  });

  final String id;
  final String type;

  /// `props` del contrato.
  final Map<String, dynamic> data;

  String? string(String key) {
    final v = data[key];
    return v is String && v.isNotEmpty ? v : null;
  }

  SduiAction? action([String key = 'action']) => SduiAction.fromJson(data[key]);

  List<Map<String, dynamic>> list(String key) {
    final v = data[key];
    if (v is! List) return const [];
    return v.whereType<Map<String, dynamic>>().toList();
  }

  Map<String, Object?> toJson() => {'id': id, 'type': type, 'props': data};

  @override
  List<Object?> get props => [id, type, data];
}

class SduiLayout extends Equatable {
  const SduiLayout({
    required this.version,
    required this.sections,
    this.layoutId = 'unknown',
    this.generatedAt,
  });

  /// Versión del contrato que esta app sabe interpretar.
  static const supportedVersion = 1;

  final int version;
  final String layoutId;
  final DateTime? generatedAt;
  final List<SduiSection> sections;

  Map<String, Object?> toJson() => {
    'version': version,
    'layout_id': layoutId,
    if (generatedAt != null) 'generated_at': generatedAt!.toIso8601String(),
    'sections': sections.map((s) => s.toJson()).toList(),
  };

  @override
  List<Object?> get props => [version, layoutId, generatedAt, sections];
}
