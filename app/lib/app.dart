import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/connectivity/connectivity_cubit.dart';
import 'core/connectivity/offline_banner.dart';
import 'core/router/app_router.dart';
import 'design_system/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

class FintechApp extends StatefulWidget {
  const FintechApp({
    required this.authBloc,
    super.key,
    this.connectivity,
    this.router,
  });

  final AuthBloc authBloc;

  /// Si es null no se muestra el banner offline (tests).
  final ConnectivityCubit? connectivity;

  /// Inyectable para tests/E2E.
  final GoRouter? router;

  @override
  State<FintechApp> createState() => _FintechAppState();
}

class _FintechAppState extends State<FintechApp> {
  late final GoRouter _router =
      widget.router ?? buildRouter(authBloc: widget.authBloc);

  @override
  void dispose() {
    if (widget.router == null) _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.authBloc,
      child: MaterialApp.router(
        title: 'Fintech Platform',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: _router,
        builder: (context, child) {
          final page = child ?? const SizedBox.shrink();
          final connectivity = widget.connectivity;
          if (connectivity == null) return page;
          return BlocProvider.value(
            value: connectivity,
            child: OfflineBanner(child: page),
          );
        },
      ),
    );
  }
}
