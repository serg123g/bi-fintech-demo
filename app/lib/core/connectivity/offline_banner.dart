import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'connectivity_cubit.dart';
import 'offline_scope.dart';

/// Banner global (se monta en `MaterialApp.builder`) visible sin conexión.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityCubit>().state;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: OfflineScope(isOffline: !online, child: child),
        ),
        if (!online)
          Material(
            key: const Key('offline_banner'),
            color: scheme.inverseSurface,
            child: SafeArea(
              top: false,
              child: Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off, color: scheme.onInverseSurface),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sin conexión. Mostrando la última información '
                          'guardada.',
                          style: TextStyle(color: scheme.onInverseSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
