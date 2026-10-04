import 'package:flutter/material.dart';

/// Placeholder de Fase 1. En la Fase 5 el contenido se renderiza vía SDUI.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      body: const Center(
        child: Text(
          'Plataforma financiera digital',
          key: Key('home_placeholder'),
        ),
      ),
    );
  }
}
