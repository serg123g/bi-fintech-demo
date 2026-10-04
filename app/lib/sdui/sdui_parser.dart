import 'sdui_models.dart';

/// Parser tolerante del contrato SDUI.
///
/// * Versión no soportada -> [FormatException] (el repositorio usa cache o
///   el layout empaquetado).
/// * Secciones mal formadas se descartan una a una: un error del backend en
///   una sección no tumba el home.
/// * Tipos desconocidos se conservan; el renderer decide ignorarlos.
abstract final class SduiParser {
  static SduiLayout parse(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('SDUI: el layout no es un objeto');
    }
    final version = json['version'];
    if (version is! int || version > SduiLayout.supportedVersion) {
      throw FormatException('SDUI: versión no soportada ($version)');
    }
    final rawSections = json['sections'];
    if (rawSections is! List) {
      throw const FormatException('SDUI: faltan sections');
    }

    final sections = <SduiSection>[];
    final seen = <String>{};
    for (final (i, raw) in rawSections.indexed) {
      if (raw is! Map<String, dynamic>) continue;
      final type = raw['type'];
      if (type is! String || type.isEmpty) continue;
      final props = raw['props'];
      var id = raw['id'] is String ? raw['id'] as String : '$type-$i';
      if (!seen.add(id)) id = '$id-$i';
      sections.add(
        SduiSection(
          id: id,
          type: type,
          data: props is Map<String, dynamic> ? props : const {},
        ),
      );
    }

    final generated = json['generated_at'];
    return SduiLayout(
      version: version,
      layoutId: json['layout_id'] is String
          ? json['layout_id'] as String
          : 'unknown',
      generatedAt: generated is String ? DateTime.tryParse(generated) : null,
      sections: sections,
    );
  }
}
