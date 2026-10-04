/// Segmentos de cliente. Determinan la experiencia personalizada (SDUI).
/// Debe coincidir con el check constraint de `profiles.segment`.
enum CustomerSegment {
  joven('Joven', 'Estudiantes y primeros empleos'),
  pyme('Pyme', 'Negocios y emprendedores'),
  premium('Premium', 'Patrimonio e inversiones');

  const CustomerSegment(this.label, this.description);

  final String label;
  final String description;

  static CustomerSegment fromName(String? value) => CustomerSegment.values
      .firstWhere((s) => s.name == value, orElse: () => CustomerSegment.joven);
}
