// lib/src/pagination/paginated_list_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'base_pagination_cubit.dart';
import 'paginated_state.dart';

/// A Flutter widget that handles all pagination UI automatically.
///
/// ```dart
/// PaginatedListView<ProductsCubit, Product>(
///   itemBuilder: (context, product, index) => ProductCard(product),
///   loadingBuilder: (_) => const ProductsShimmer(),
///   emptyBuilder: (_) => const EmptyProducts(),
///   errorBuilder: (context, error) => ErrorView(error),
/// )
/// ```
class PaginatedListView<C extends BasePaginationCubit<T>, T>
    extends StatefulWidget {
  const PaginatedListView({
    super.key,
    required this.itemBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.loadMoreErrorBuilder,
    this.separatorBuilder,
    this.scrollThreshold = 0.9, // trigger loadMore at 90% scroll
    this.enableRefresh = true,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.scrollController,
  });

  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Widget Function(BuildContext context, Object error)?
  loadMoreErrorBuilder;
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  final double scrollThreshold;
  final bool enableRefresh;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final ScrollController? scrollController;

  @override
  State<PaginatedListView<C, T>> createState() =>
      _PaginatedListViewState<C, T>();
}

class _PaginatedListViewState<C extends BasePaginationCubit<T>, T>
    extends State<PaginatedListView<C, T>> {
  late final ScrollController _scrollController;
  bool _isExternalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
      _isExternalController = true;
    } else {
      _scrollController = ScrollController();
    }
    _scrollController.addListener(_onScroll);

    // Fetch first page on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<C>().fetchFirstPage();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (!_isExternalController) _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (maxScroll > 0 && currentScroll / maxScroll >= widget.scrollThreshold) {
      context.read<C>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<C, PaginatedState<T>>(
      builder: (context, state) {
        // First load
        if (state.isFirstLoad) {
          return widget.loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator.adaptive());
        }

        // Full page error (no items yet)
        if (state.hasError && state.items.isEmpty) {
          return widget.errorBuilder?.call(context, state.error!) ??
              Center(child: Text(state.error.toString()));
        }

        // Empty
        if (state.isEmpty) {
          return widget.emptyBuilder?.call(context) ??
              const Center(child: Text('No items found.'));
        }

        final list = _buildList(context, state);

        return widget.enableRefresh
            ? RefreshIndicator.adaptive(
                onRefresh: () => context.read<C>().refresh(),
                child: list,
              )
            : list;
      },
    );
  }

  Widget _buildList(BuildContext context, PaginatedState<T> state) {
    // +1 for the load more indicator at the bottom
    final itemCount = state.items.length + 1;

    final listView = widget.separatorBuilder != null
        ? ListView.separated(
            controller: _scrollController,
            padding: widget.padding,
            physics: widget.physics,
            shrinkWrap: widget.shrinkWrap,
            itemCount: itemCount,
            separatorBuilder: (ctx, i) => i < state.items.length - 1
                ? widget.separatorBuilder!(ctx, i)
                : const SizedBox.shrink(),
            itemBuilder: (ctx, i) => _itemOrFooter(ctx, state, i),
          )
        : ListView.builder(
            controller: _scrollController,
            padding: widget.padding,
            physics: widget.physics,
            shrinkWrap: widget.shrinkWrap,
            itemCount: itemCount,
            itemBuilder: (ctx, i) => _itemOrFooter(ctx, state, i),
          );

    return listView;
  }

  Widget _itemOrFooter(BuildContext context, PaginatedState<T> state, int i) {
    // Footer slot
    if (i == state.items.length) {
      if (state.isLoadingMore) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator.adaptive()),
        );
      }
      if (state.hasLoadMoreError) {
        return widget.loadMoreErrorBuilder?.call(
              context,
              state.loadMoreError!,
            ) ??
            _DefaultLoadMoreError(
              error: state.loadMoreError!,
              onRetry: () => context.read<C>().loadMore(),
            );
      }
      if (!state.hasMore) {
        return const SizedBox.shrink(); // end of list
      }
      return const SizedBox.shrink();
    }

    return widget.itemBuilder(context, state.items[i], i);
  }
}

class _DefaultLoadMoreError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _DefaultLoadMoreError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text(
          error.toString(),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
