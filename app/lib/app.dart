import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'design_system/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

class FintechApp extends StatefulWidget {
  const FintechApp({required this.authBloc, super.key, this.router});

  final AuthBloc authBloc;

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
      ),
    );
  }
}
