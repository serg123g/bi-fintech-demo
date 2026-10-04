import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/cache/cache_store.dart';
import '../../../core/chaos/chaos_config.dart';
import '../../../core/network/circuit_breaker.dart';
import '../../../core/network/resilient_executor.dart';
import '../../../design_system/app_theme.dart';

/// Panel de diagnóstico para demostrar resiliencia en vivo.
/// Solo accesible en debug o con ENABLE_CHAOS_PANEL=true.
class ChaosPage extends StatelessWidget {
  const ChaosPage({
    required this.controller,
    required this.cache,
    this.executor,
    super.key,
  });

  final ChaosController controller;
  final CacheStore cache;

  /// Executor base, para mostrar y reiniciar los circuit breakers.
  final DefaultResilientExecutor? executor;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel chaos'),
          actions: [
            TextButton(
              key: const Key('chaos_reset'),
              onPressed: () {
                controller.reset();
                executor?.resetCircuits();
              },
              child: const Text('Restablecer'),
            ),
          ],
        ),
        body: BlocBuilder<ChaosController, ChaosConfig>(
          builder: (context, c) => ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _Status(active: c.isActive),
              const SizedBox(height: AppSpacing.md),
              const _SectionTitle('Escenarios'),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _preset(context, 'Red lenta (3 s)', ChaosPresets.slow),
                  _preset(context, '3 s + 50 % fallas', ChaosPresets.unstable),
                  _preset(context, 'Home caído', ChaosPresets.homeDown),
                  _preset(context, 'Cuentas caídas', ChaosPresets.accountsDown),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle('Latencia: ${c.latency.inMilliseconds} ms'),
              Slider(
                key: const Key('chaos_latency'),
                value: c.latency.inMilliseconds.toDouble(),
                max: 5000,
                divisions: 10,
                label: '${c.latency.inMilliseconds} ms',
                onChanged: (v) =>
                    controller.setLatency(Duration(milliseconds: v.round())),
              ),
              _SectionTitle(
                'Tasa de fallo: ${(c.failureRate * 100).round()} %',
              ),
              Slider(
                key: const Key('chaos_failure_rate'),
                value: c.failureRate,
                divisions: 10,
                label: '${(c.failureRate * 100).round()} %',
                onChanged: controller.setFailureRate,
              ),
              const SizedBox(height: AppSpacing.md),
              const _SectionTitle('Servicios'),
              _serviceSwitch(
                c,
                ChaosServices.homeLayout,
                'Caer home-layout (SDUI)',
              ),
              _serviceSwitch(c, ChaosServices.accounts, 'Caer cuentas'),
              _serviceSwitch(c, ChaosServices.microapp, 'Caer micro-app'),
              if (executor case final ex?) ...[
                const SizedBox(height: AppSpacing.md),
                const _SectionTitle('Circuit breakers'),
                _Breakers(states: ex.circuitStates),
              ],
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                key: const Key('chaos_clear_cache'),
                onPressed: () async {
                  await cache.clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache local borrada')),
                    );
                  }
                },
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Borrar cache local (probar fallback)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preset(BuildContext context, String label, ChaosConfig preset) =>
      ActionChip(
        key: Key('chaos_preset_$label'),
        label: Text(label),
        onPressed: () => controller.apply(preset),
      );

  Widget _serviceSwitch(ChaosConfig c, String service, String label) =>
      SwitchListTile(
        key: Key('chaos_down_$service'),
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: c.isDown(service),
        onChanged: (down) => controller.setServiceDown(service, down: down),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleSmall);
}

class _Status extends StatelessWidget {
  const _Status({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: active ? scheme.errorContainer : scheme.surfaceContainerHighest,
      child: ListTile(
        leading: Icon(active ? Icons.bolt : Icons.check_circle_outline),
        title: Text(active ? 'Chaos activo' : 'Sin fallas inyectadas'),
        subtitle: const Text(
          'Las fallas se inyectan dentro de cada intento: reintentos, '
          'circuit breaker, cache y fallback reaccionan como en producción.',
        ),
      ),
    );
  }
}

class _Breakers extends StatelessWidget {
  const _Breakers({required this.states});

  final Map<String, CircuitState> states;

  @override
  Widget build(BuildContext context) {
    if (states.isEmpty) return const Text('Sin llamadas todavía.');
    return Column(
      children: [
        for (final e in states.entries)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(e.key),
            trailing: Text(switch (e.value) {
              CircuitState.closed => 'cerrado',
              CircuitState.open => 'ABIERTO',
              CircuitState.halfOpen => 'semi-abierto',
            }),
          ),
      ],
    );
  }
}
