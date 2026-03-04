// lib/src/delayed_result/delayed_result_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'delayed_result.dart';

/// A generic Cubit that manages a single async operation.
///
/// Extend this in your app and call [execute] inside your methods.
///
/// ```dart
/// class UserCubit extends DelayedResultCubit<User> {
///   final UserRepo _repo;
///   UserCubit(this._repo) : super();
///
///   Future<void> loadUser(String id) =>
///       execute(() => _repo.getUser(id));
/// }
/// ```
abstract class DelayedResultCubit<T> extends Cubit<DelayedResult<T>> {
  DelayedResultCubit() : super(const DelayedInitial());

  /// Runs [operation], automatically emitting loading → success/error.
  ///
  /// [emitLoadingImmediately] controls whether loading is emitted
  /// before the future starts — set false to avoid flicker on fast responses.
  Future<void> execute(
    Future<T> Function() operation, {
    bool emitLoadingImmediately = true,
  }) async {
    if (isClosed) return;

    if (emitLoadingImmediately) emit(const DelayedLoading());

    try {
      final result = await operation();
      if (!isClosed) emit(DelayedSuccess(result));
    } catch (e, st) {
      if (!isClosed) emit(DelayedError(e, stackTrace: st));
    }
  }

  /// Reset back to initial state
  void reset() {
    if (!isClosed) emit(const DelayedInitial());
  }

  // ── Convenience getters ──────────────────────────────────────────────────

  bool get isInitial => state.isInitial;
  bool get isLoading => state.isLoading;
  bool get isError => state.isError;
  bool get isSuccess => state.isSuccess;
  T? get data => state.dataOrNull;
}
