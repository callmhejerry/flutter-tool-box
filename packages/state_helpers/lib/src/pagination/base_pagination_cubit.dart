// lib/src/pagination/base_pagination_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../state_status/state_status.dart';
import 'paginated_state.dart';

/// Base class for all pagination cubits.
/// Contains shared logic: refresh, error handling, loadMore guards.
abstract class BasePaginationCubit<T> extends Cubit<PaginatedState<T>> {
  final int pageSize;

  BasePaginationCubit({this.pageSize = 20}) : super(const PaginatedState());

  /// Subclasses implement their specific fetch logic
  Future<void> fetchFirstPage();
  Future<void> loadMore();

  /// Refresh — resets to first page
  Future<void> refresh() async {
    emit(const PaginatedState());
    await fetchFirstPage();
  }

  /// Guards against redundant loadMore calls
  bool get canLoadMore =>
      state.hasMore &&
      !state.isLoadingMore &&
      !state.hasLoadMoreError &&
      state.status.isSuccess;

  /// Shared: emit first page loading
  void emitFirstPageLoading() {
    emit(state.copyWith(status: StateStatus.loading));
  }

  /// Shared: emit first page error
  void emitFirstPageError(Object error) {
    emit(state.copyWith(status: StateStatus.error, error: error));
  }

  /// Shared: emit first page success
  void emitFirstPageSuccess(List<T> items, {bool hasMore = true}) {
    emit(
      state.copyWith(
        items: items,
        status: items.isEmpty ? StateStatus.empty : StateStatus.success,
        hasMore: hasMore,
        loadMoreStatus: StateStatus.initial,
        currentPage: 1,
      ),
    );
  }

  /// Shared: emit load more loading
  void emitLoadMoreLoading() {
    emit(state.copyWith(loadMoreStatus: StateStatus.loading));
  }

  /// Shared: emit load more error
  void emitLoadMoreError(Object error) {
    emit(
      state.copyWith(loadMoreStatus: StateStatus.error, loadMoreError: error),
    );
  }

  /// Shared: append next page results
  void emitLoadMoreSuccess(List<T> newItems) {
    final allItems = [...state.items, ...newItems];
    emit(
      state.copyWith(
        items: allItems,
        status: StateStatus.success,
        loadMoreStatus: StateStatus.initial,
        hasMore: newItems.length >= pageSize,
        currentPage: state.currentPage + 1,
      ),
    );
  }
}
