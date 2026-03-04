// lib/src/delayed_result/delayed_result.dart

import 'package:equatable/equatable.dart';

/// A sealed union representing the result of a single async operation.
///
/// Usage:
/// ```dart
/// DelayedResult<User> result = DelayedSuccess(user);
///
/// result.when(
///   initial: () => ...,
///   loading: () => ...,
///   error: (e, st) => ...,
///   success: (user) => ...,
/// );
/// ```
sealed class DelayedResult<T> extends Equatable {
  const DelayedResult();

  bool get isInitial => this is DelayedInitial<T>;
  bool get isLoading => this is DelayedLoading<T>;
  bool get isError => this is DelayedError<T>;
  bool get isSuccess => this is DelayedSuccess<T>;

  /// Returns data if success, null otherwise
  T? get dataOrNull => switch (this) {
    DelayedSuccess<T>(data: final d) => d,
    _ => null,
  };

  /// Returns error if error, null otherwise
  Object? get errorOrNull => switch (this) {
    DelayedError<T>(error: final e) => e,
    _ => null,
  };

  /// Pattern match over all states
  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(Object error, StackTrace? stackTrace) error,
    required R Function(T data) success,
  }) => switch (this) {
    DelayedInitial<T>() => initial(),
    DelayedLoading<T>() => loading(),
    DelayedError<T>(error: final e, stackTrace: final st) => error(e, st),
    DelayedSuccess<T>(data: final d) => success(d),
  };

  /// Like [when] but only handle states you care about
  R? maybeWhen<R>({
    R Function()? initial,
    R Function()? loading,
    R Function(Object error, StackTrace? stackTrace)? error,
    R Function(T data)? success,
  }) => switch (this) {
    DelayedInitial<T>() => initial?.call(),
    DelayedLoading<T>() => loading?.call(),
    DelayedError<T>(error: final e, stackTrace: final st) => error?.call(e, st),
    DelayedSuccess<T>(data: final d) => success?.call(d),
  };

  @override
  List<Object?> get props => [];
}

final class DelayedInitial<T> extends DelayedResult<T> {
  const DelayedInitial();
}

final class DelayedLoading<T> extends DelayedResult<T> {
  const DelayedLoading();
}

final class DelayedError<T> extends DelayedResult<T> {
  final Object error;
  final StackTrace? stackTrace;

  const DelayedError(this.error, {this.stackTrace});

  @override
  List<Object?> get props => [error, stackTrace];
}

final class DelayedSuccess<T> extends DelayedResult<T> {
  final T data;

  const DelayedSuccess(this.data);

  @override
  List<Object?> get props => [data];
}
