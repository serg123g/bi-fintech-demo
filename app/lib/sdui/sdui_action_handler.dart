import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/logging/app_logger.dart';
import '../core/router/app_routes.dart';
import 'sdui_models.dart';

/// Ejecuta acciones SDUI validándolas contra listas blancas: el backend
/// expresa intención, la app decide si es segura.
class SduiActionHandler {
  const SduiActionHandler({required this.logger, this.microapps = const {}});

  final AppLogger logger;

  /// Micro-apps registradas -> ruta interna que las aloja. Una micro-app
  /// no registrada muestra "Disponible próximamente" en lugar de romper.
  final Map<String, String> microapps;

  static const _allowedRoutePrefixes = [AppRoutes.home, AppRoutes.accounts];

  static bool isAllowedRoute(String path) =>
      path.startsWith('/') &&
      !path.startsWith('//') &&
      _allowedRoutePrefixes.any(
        (p) => p == AppRoutes.home ? path == p : path.startsWith(p),
      );

  Future<void> handle(BuildContext context, SduiAction action) async {
    logger.info('sdui_action', action.toJson());
    switch (action) {
      case RouteAction(:final path) when isAllowedRoute(path):
        await context.push(path);
      case MicroappAction(:final id) when microapps.containsKey(id):
        await context.push(microapps[id]!);
      case UrlAction(:final url) when url.startsWith('https://'):
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      case MicroappAction():
        _soon(context);
      default:
        logger.warning('sdui_action_rejected', action.toJson());
        _soon(context);
    }
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Disponible próximamente')));
  }
}
