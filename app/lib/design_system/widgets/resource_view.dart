import 'package:flutter/material.dart';

import '../../core/connectivity/offline_scope.dart';
import '../../core/presentation/resource_state.dart';
import 'error_view.dart';
import 'freshness_bar.dart';
import 'skeleton.dart';

/// Renderiza un [ResourceState] con todos sus estados degradados:
/// skeleton, error con reintento, datos (frescos o guardados) + frescura.
///
/// Al recuperar la conexión, si lo que se muestra no está al día (vino de
/// cache o falló el último refresh), se refresca solo.
class ResourceView<T> extends StatefulWidget {
  const ResourceView({
    required this.state,
    required this.onRetry,
    required this.builder,
    super.key,
    this.skeletonItems = 4,
  });

  final ResourceState<T> state;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, T data) builder;
  final int skeletonItems;

  @override
  State<ResourceView<T>> createState() => _ResourceViewState<T>();
}

class _ResourceViewState<T> extends State<ResourceView<T>> {
  bool _offline = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final offline = OfflineScope.of(context);
    final reconnected = _offline && !offline;
    _offline = offline;
    final s = widget.state;
    final stale = s.fromCache || s.failure != null;
    if (reconnected && stale && !s.isRefreshing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onRetry();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final data = state.data;
    if (data == null) {
      final failure = state.failure;
      if (state.status == ResourceStatus.failure && failure != null) {
        return ErrorView(message: failure.message, onRetry: widget.onRetry);
      }
      return SkeletonList(items: widget.skeletonItems);
    }
    return Column(
      children: [
        FreshnessBar(
          updatedAt: state.updatedAt,
          fromCache: state.fromCache,
          isRefreshing: state.isRefreshing,
          isOffline: _offline,
          failure: state.failure,
          onRetry: widget.onRetry,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => widget.onRetry(),
            child: widget.builder(context, data),
          ),
        ),
      ],
    );
  }
}
