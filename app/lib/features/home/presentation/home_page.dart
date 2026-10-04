import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/presentation/bloc/auth_bloc.dart';

/// Placeholder: en la Fase 5 el contenido se renderiza vía SDUI.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final user = state is AuthAuthenticated ? state.user : null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            key: const Key('logout_button'),
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthSignOutRequested()),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              user == null ? 'Hola' : 'Hola, ${user.firstName}',
              key: const Key('home_greeting'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (user != null) Text('Segmento: ${user.segment.label}'),
          ],
        ),
      ),
    );
  }
}
