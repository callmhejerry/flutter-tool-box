// lib/src/result.dart

import 'failure.dart';

/// A sealed class representing either a [Success] or [Err] outcome.
///
/// Use this as the return type of repository and data-source methods
/// instead of throwing exceptions.
///
/// ```dart
/// // In your repository:
/// Future<Result<User>> getUser(String id) async {
///   try {
///     final user = await api.getUser(id);
///     return Result.success(user);
///   } catch (e, st) {
///     return Result.failure(Failure.network(originalError: e, stackTrace: st));
///   }
/// }
///
/// // In your cubit:
/// final result = await repo.getUser(id);
/// result.when(
///   success: (user) => emit(UserLoaded(user)),
///   failure: (failure) => emit(UserError(failure.message)),
/// );
/// ```
sealed class Result<T> {
  const Result();

  // ── Factories ──────────────────────────────────────────────────────────────

  /// Wrap a successful value
  const factory Result.success(T data) = Success<T>;

  /// Wrap a [Failure]
  const factory Result.failure(Failure failure) = Err<T>;

  /// Wrap a plain error message as a [Failure]
  factory Result.failureMessage(String message) =>
      Err(Failure(code: 'ERROR', message: message));

  /// Run [operation] and automatically catch exceptions into [Failure].
  ///
  /// ```dart
  /// final result = await Result.fromAsync(
  ///   () => api.getUser(id),
  ///   onError: (e, st) => Failure.network(originalError: e, stackTrace: st),
  /// );
  /// ```
  static Future<Result<T>> fromAsync<T>(
    Future<T> Function() operation, {
    Failure Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    try {
      final data = await operation();
      return Result.success(data);
    } catch (e, st) {
      return Result.failure(
        onError?.call(e, st) ??
            Failure.unexpected(originalError: e, stackTrace: st),
      );
    }
  }

  /// Sync version of [fromAsync]
  static Result<T> guard<T>(
    T Function() operation, {
    Failure Function(Object error, StackTrace stackTrace)? onError,
  }) {
    try {
      return Result.success(operation());
    } catch (e, st) {
      return Result.failure(
        onError?.call(e, st) ??
            Failure.unexpected(originalError: e, stackTrace: st),
      );
    }
  }

  // ── State checks ───────────────────────────────────────────────────────────

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Err<T>;

  /// Returns data if [Success], null otherwise
  T? get dataOrNull => switch (this) {
    Success<T>(data: final d) => d,
    _ => null,
  };

  /// Returns [Failure] if [Err], null otherwise
  Failure? get failureOrNull => switch (this) {
    Err<T>(failure: final f) => f,
    _ => null,
  };

  /// Throws if not [Success] — use only when you are certain of the result
  T get dataOrThrow => switch (this) {
    Success<T>(data: final d) => d,
    Err<T>(failure: final f) => throw Exception(f.message),
  };

  // ── Pattern matching ───────────────────────────────────────────────────────

  /// Handle both states — both callbacks required
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) => switch (this) {
    Success<T>(data: final d) => success(d),
    Err<T>(failure: final f) => failure(f),
  };

  /// Handle only the states you care about
  R? maybeWhen<R>({
    R Function(T data)? success,
    R Function(Failure failure)? failure,
  }) => switch (this) {
    Success<T>(data: final d) => success?.call(d),
    Err<T>(failure: final f) => failure?.call(f),
  };

  // ── Transformations ────────────────────────────────────────────────────────

  /// Transform the success value without unwrapping
  ///
  /// ```dart
  /// final result = await repo.getUser(id);           // Result<User>
  /// final nameResult = result.map((user) => user.name); // Result<String>
  /// ```
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
    Success<T>(data: final d) => Result.success(transform(d)),
    Err<T>(failure: final f) => Result.failure(f),
  };

  /// Like [map] but the transform itself returns a [Result]
  Result<R> flatMap<R>(Result<R> Function(T data) transform) => switch (this) {
    Success<T>(data: final d) => transform(d),
    Err<T>(failure: final f) => Result.failure(f),
  };

  /// Async version of [map]
  Future<Result<R>> mapAsync<R>(Future<R> Function(T data) transform) async =>
      switch (this) {
        Success<T>(data: final d) => Result.success(await transform(d)),
        Err<T>(failure: final f) => Result.failure(f),
      };

  /// Return a fallback value if this is a failure
  T getOrElse(T Function(Failure failure) fallback) => switch (this) {
    Success<T>(data: final d) => d,
    Err<T>(failure: final f) => fallback(f),
  };

  /// Execute a side effect on success, pass through the result unchanged
  Result<T> onSuccess(void Function(T data) action) {
    if (this case Success<T>(data: final d)) action(d);
    return this;
  }

  /// Execute a side effect on failure, pass through the result unchanged
  Result<T> onFailure(void Function(Failure failure) action) {
    if (this case Err<T>(failure: final f)) action(f);
    return this;
  }

  @override
  String toString() => switch (this) {
    Success<T>(data: final d) => 'Result.success($d)',
    Err<T>(failure: final f) => 'Result.failure($f)',
  };
}

/// The success variant
final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// The failure variant — named [Err] to avoid clashing with dart:core [Error]
final class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}
