// lib/src/pagination/page_cubit.dart

import 'base_pagination_cubit.dart';

/// Extend this for page-number based pagination.
///
/// ```dart
/// class ProductsCubit extends PageCubit<Product> {
///   final ProductRepo _repo;
///   ProductsCubit(this._repo) : super(pageSize: 20);
///
///   @override
///   Future<List<Product>> fetchPage(int page, int pageSize) =>
///       _repo.getProducts(page: page, pageSize: pageSize);
/// }
/// ```
abstract class PageCubit<T> extends BasePaginationCubit<T> {
  PageCubit({super.pageSize});

  /// App provides this — fetch a specific page
  Future<List<T>> fetchPage(int page, int pageSize);

  @override
  Future<void> fetchFirstPage() async {
    if (isClosed) return;
    emitFirstPageLoading();
    try {
      final items = await fetchPage(1, pageSize);
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
      final nextPage = state.currentPage + 1;
      final items = await fetchPage(nextPage, pageSize);
      if (!isClosed) emitLoadMoreSuccess(items);
    } catch (e) {
      if (!isClosed) emitLoadMoreError(e);
    }
  }
}
