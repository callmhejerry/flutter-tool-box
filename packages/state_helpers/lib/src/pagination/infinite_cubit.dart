// lib/src/pagination/infinite_cubit.dart

import 'base_pagination_cubit.dart';

/// Extend this for infinite scroll (offset-based).
/// Offset is calculated automatically from items.length.
///
/// ```dart
/// class NotificationsCubit extends InfiniteCubit<AppNotification> {
///   final NotificationsRepo _repo;
///   NotificationsCubit(this._repo) : super(pageSize: 15);
///
///   @override
///   Future<List<AppNotification>> fetchOffset(int offset, int limit) =>
///       _repo.getNotifications(offset: offset, limit: limit);
/// }
/// ```
abstract class InfiniteCubit<T> extends BasePaginationCubit<T> {
  InfiniteCubit({super.pageSize});

  Future<List<T>> fetchOffset(int offset, int limit);

  @override
  Future<void> fetchFirstPage() async {
    if (isClosed) return;
    emitFirstPageLoading();
    try {
      final items = await fetchOffset(0, pageSize);
      if (!isClosed) {
        emitFirstPageSuccess(items, hasMore: items.length >= pageSize);
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
      final items = await fetchOffset(state.items.length, pageSize);
      if (!isClosed) emitLoadMoreSuccess(items);
    } catch (e) {
      if (!isClosed) emitLoadMoreError(e);
    }
  }
}
