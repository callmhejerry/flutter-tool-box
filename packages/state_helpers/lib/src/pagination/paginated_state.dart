// lib/src/pagination/paginated_state.dart

import 'package:equatable/equatable.dart';
import '../state_status/state_status.dart';

/// The state model for all pagination variants.
class PaginatedState<T> extends Equatable {
  final List<T> items;
  final StateStatus status;
  final StateStatus
  loadMoreStatus; // tracks the "fetch next page" operation separately
  final bool hasMore;
  final Object? error;
  final Object? loadMoreError;

  // Page-based
  final int currentPage;

  // Cursor-based
  final String? nextCursor;

  const PaginatedState({
    this.items = const [],
    this.status = StateStatus.initial,
    this.loadMoreStatus = StateStatus.initial,
    this.hasMore = true,
    this.error,
    this.loadMoreError,
    this.currentPage = 0,
    this.nextCursor,
  });

  bool get isFirstLoad => status.isLoading && items.isEmpty;
  bool get isLoadingMore => loadMoreStatus.isLoading;
  bool get hasError => status.isError;
  bool get hasLoadMoreError => loadMoreStatus.isError;
  bool get isEmpty => status.isEmpty;

  PaginatedState<T> copyWith({
    List<T>? items,
    StateStatus? status,
    StateStatus? loadMoreStatus,
    bool? hasMore,
    Object? error,
    Object? loadMoreError,
    int? currentPage,
    String? nextCursor,
  }) => PaginatedState<T>(
    items: items ?? this.items,
    status: status ?? this.status,
    loadMoreStatus: loadMoreStatus ?? this.loadMoreStatus,
    hasMore: hasMore ?? this.hasMore,
    error: error,
    loadMoreError: loadMoreError,
    currentPage: currentPage ?? this.currentPage,
    nextCursor: nextCursor ?? this.nextCursor,
  );

  @override
  List<Object?> get props => [
    items,
    status,
    loadMoreStatus,
    hasMore,
    error,
    loadMoreError,
    currentPage,
    nextCursor,
  ];
}
