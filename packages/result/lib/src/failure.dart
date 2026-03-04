// lib/src/failure.dart

/// A typed error model that wraps any failure in your app.
///
/// Instead of throwing raw exceptions, return a [Failure] on the error path.
///
/// ```dart
/// Failure(
///   code: 'USER_NOT_FOUND',
///   message: 'No user exists with that ID.',
///   originalError: e,
///   stackTrace: st,
/// )
/// ```
class Failure {
  final String code;
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  const Failure({
    required this.code,
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  // ── Common factory constructors ────────────────────────────────────────────

  /// Network / HTTP failures
  factory Failure.network({
    String message = 'A network error occurred.',
    Object? originalError,
    StackTrace? stackTrace,
  }) => Failure(
    code: 'NETWORK_ERROR',
    message: message,
    originalError: originalError,
    stackTrace: stackTrace,
  );

  /// Server returned a non-2xx response
  factory Failure.server({
    String message = 'A server error occurred.',
    int? statusCode,
    Object? originalError,
    StackTrace? stackTrace,
  }) => Failure(
    code: 'SERVER_ERROR${statusCode != null ? '_$statusCode' : ''}',
    message: message,
    originalError: originalError,
    stackTrace: stackTrace,
  );

  /// Input / validation failures
  factory Failure.validation({
    String message = 'Validation failed.',
    Object? originalError,
    StackTrace? stackTrace,
  }) => Failure(
    code: 'VALIDATION_ERROR',
    message: message,
    originalError: originalError,
    stackTrace: stackTrace,
  );

  /// Unexpected / unknown failures — use as a catch-all
  factory Failure.unexpected({
    String message = 'An unexpected error occurred.',
    Object? originalError,
    StackTrace? stackTrace,
  }) => Failure(
    code: 'UNEXPECTED_ERROR',
    message: message,
    originalError: originalError,
    stackTrace: stackTrace,
  );

  /// Cache / local storage failures
  factory Failure.cache({
    String message = 'A local storage error occurred.',
    Object? originalError,
    StackTrace? stackTrace,
  }) => Failure(
    code: 'CACHE_ERROR',
    message: message,
    originalError: originalError,
    stackTrace: stackTrace,
  );

  @override
  String toString() => 'Failure(code: $code, message: $message)';
}
