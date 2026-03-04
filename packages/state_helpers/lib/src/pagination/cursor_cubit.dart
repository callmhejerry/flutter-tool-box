// lib/src/pagination/cursor_cubit.dart

import 'base_pagination_cubit.dart';
import '../state_status/state_status.dart';

/// Result model your fetchCursor method must return
class CursorPage<T> {
  final List<T> items;
  final String? nextCursor; // null means no more pages

  const CursorPage({required this.items, this.nextCursor});
}

/// Extend this for cursor/offset based pagination.
///
/// ```dart
/// class FeedCubit extends CursorCubit<Post> {
///   final FeedRepo _repo;
///   FeedCubit(this._repo) : super(pageSize: 20);
///
///   @override
///   Future<CursorPage<Post>> fetchCursor(String? cursor, int pageSize) =>
///       _repo.getFeed(cursor: cursor, limit: pageSize);
/// }
/// ```
abstract class CursorCubit<T> extends BasePaginationCubit<T> {
  CursorCubit({super.pageSize});

  Future<CursorPage<T>> fetchCursor(String? cursor, int pageSize);

  @override
  Future<void> fetchFirstPage() async {
    if (isClosed) return;
    emitFirstPageLoading();
    try {
      final page = await fetchCursor(null, pageSize);
      if (!isClosed) {
        emit(
          state.copyWith(
            items: page.items,
            status: page.items.isEmpty
                ? StateStatus.empty
                : StateStatus.success,
            hasMore: page.nextCursor != null,
            nextCursor: page.nextCursor,
            currentPage: 1,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) emitFirstPageError(e);
    }
  }

  @override
  Future<void> loadMore() async {
    if (isClosed || !canLoadMore) return;
    emitLoadMoreLoading();
    try {
      final page = await fetchCursor(state.nextCursor, pageSize);
      if (!isClosed) {
        final allItems = [...state.items, ...page.items];
        emit(
          state.copyWith(
            items: allItems,
            status: StateStatus.success,
            loadMoreStatus: StateStatus.initial,
            hasMore: page.nextCursor != null,
            nextCursor: page.nextCursor,
            currentPage: state.currentPage + 1,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) emitLoadMoreError(e);
    }
  }
}
