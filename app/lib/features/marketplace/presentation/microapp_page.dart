import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/logging/app_logger.dart';
import '../../../design_system/widgets/error_view.dart';
import '../domain/microapp_protocol.dart';
import 'microapp_cubit.dart';

/// Contenedor de micro-apps web (equipos/terceros independientes).
///
/// * Solo navega dentro del origen de la micro-app.
/// * Comunicación por mensajes tipados (ver [MicroappProtocol]).
/// * Estados de carga, error y timeout con reintento.
class MicroappPage extends StatefulWidget {
  const MicroappPage({
    required this.url,
    required this.firstName,
    required this.segment,
    required this.logger,
    this.section,
    this.isDown,
    super.key,
  });

  final String url;
  final String firstName;
  final String segment;
  final String? section;
  final AppLogger logger;

  /// Panel chaos: simula la caída del servicio de la micro-app.
  final bool Function()? isDown;

  @override
  State<MicroappPage> createState() => _MicroappPageState();
}

class _MicroappPageState extends State<MicroappPage> {
  late final Uri _origin = Uri.parse(widget.url);
  late final WebViewController _web;
  late final MicroappCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = MicroappCubit(
      initMessage: MicroappProtocol.init(
        name: widget.firstName,
        segment: widget.segment,
        section: widget.section,
      ),
      send: _sendToWeb,
      onBenefitSelected: _onBenefit,
      onClose: () {
        if (mounted) Navigator.of(context).maybePop();
      },
      isDown: widget.isDown ?? () => false,
    );
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'HostBridge',
        onMessageReceived: (m) => _cubit.onRawMessage(m.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            final sameOrigin =
                uri != null &&
                uri.scheme == _origin.scheme &&
                uri.host == _origin.host;
            if (!sameOrigin) {
              widget.logger.warning('microapp_navigation_blocked', {
                'url': request.url,
              });
            }
            return sameOrigin
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              widget.logger.warning('microapp_load_error', {
                'code': error.errorCode,
                'type': error.errorType,
              });
              _cubit.onLoadError(error.description);
            }
          },
        ),
      );
    _load();
  }

  void _load() {
    if (widget.url.isEmpty) {
      _cubit.onLoadError('MICROAPP_URL no configurada');
      return;
    }
    if (_cubit.start()) {
      _web.loadRequest(_origin).ignore();
    }
  }

  void _sendToWeb(String json) {
    // jsonEncode de un String produce un literal JS seguro (escapado).
    _web
        .runJavaScript(
          'window.__hostReceive && window.__hostReceive(${jsonEncode(json)});',
        )
        .ignore();
  }

  void _onBenefit(BenefitSelectedMessage m) {
    widget.logger.info('microapp_benefit_selected', {'id': m.id});
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('benefit_snackbar'),
          content: Text('Beneficio activado: ${m.title}'),
        ),
      );
  }

  @override
  void dispose() {
    _cubit.close().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: const Text('Beneficios')),
        body: BlocBuilder<MicroappCubit, MicroappState>(
          builder: (context, state) => switch (state.status) {
            MicroappStatus.error => ErrorView(
              message: state.error ?? 'No disponible',
              onRetry: _load,
            ),
            _ => Stack(
              children: [
                WebViewWidget(controller: _web),
                if (state.status == MicroappStatus.loading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          },
        ),
      ),
    );
  }
}
