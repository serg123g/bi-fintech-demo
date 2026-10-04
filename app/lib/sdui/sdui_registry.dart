import 'package:flutter/widgets.dart';

import 'components/accounts_summary_section.dart';
import 'components/banner_section.dart';
import 'components/greeting_section.dart';
import 'components/insight_section.dart';
import 'components/offer_card_section.dart';
import 'components/quick_actions_section.dart';
import 'sdui_models.dart';

/// Construye el widget de una sección. Debe lanzar si las props son
/// inválidas: el renderer omite esa sección y sigue con las demás.
typedef SduiWidgetBuilder =
    Widget Function(BuildContext context, SduiSection section);

/// Catálogo de componentes que esta versión de la app sabe renderizar.
/// Agregar un componente nuevo = registrar un builder aquí; el backend puede
/// empezar a enviarlo sin romper versiones viejas (que lo ignoran).
class SduiRegistry {
  const SduiRegistry(this._builders);

  factory SduiRegistry.defaults() => const SduiRegistry({
    'greeting': buildGreeting,
    'accounts_summary': buildAccountsSummary,
    'banner': buildBanner,
    'quick_actions': buildQuickActions,
    'offer_card': buildOfferCard,
    'insight': buildInsight,
  });

  final Map<String, SduiWidgetBuilder> _builders;

  SduiWidgetBuilder? operator [](String type) => _builders[type];

  Set<String> get types => _builders.keys.toSet();

  SduiRegistry extend(Map<String, SduiWidgetBuilder> more) =>
      SduiRegistry({..._builders, ...more});
}
