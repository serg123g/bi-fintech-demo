import 'package:flutter/material.dart';

import '../../core/presentation/resource_state.dart';
import 'error_view.dart';
import 'freshness_bar.dart';
import 'skeleton.dart';

/// Renderiza un [ResourceState] con todos sus estados degradados:
/// skeleton, error con reintento, datos (frescos o de cache) + frescura.
class ResourceView<T> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final data = state.data;
    if (data == null) {
      final failure = state.failure;
      if (state.status == ResourceStatus.failure && failure != null) {
        return ErrorView(message: failure.message, onRetry: onRetry);
      }
      return SkeletonList(items: skeletonItems);
    }
    return Column(
      children: [
        FreshnessBar(
          updatedAt: state.updatedAt,
          fromCache: state.fromCache,
          isRefreshing: state.isRefreshing,
          failure: state.failure,
          onRetry: onRetry,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => onRetry(),
            child: builder(context, data),
          ),
        ),
      ],
    );
  }
}
