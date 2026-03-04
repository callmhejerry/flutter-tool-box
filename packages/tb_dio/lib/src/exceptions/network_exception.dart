// lib/src/exceptions/network_exception.dart

/// Base class for all network exceptions thrown by [DioClient].
sealed class NetworkException implements Exception {
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  const NetworkException({
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => '$runtimeType: $message';
}

/// Device has no internet connection
final class NoInternetException extends NetworkException {
  const NoInternetException({
    super.message = 'No internet connection.',
    super.originalError,
    super.stackTrace,
  });
}

/// Request timed out
final class TimeoutException extends NetworkException {
  const TimeoutException({
    super.message = 'The request timed out.',
    super.originalError,
    super.stackTrace,
  });
}

/// Server returned 401
final class UnauthorizedException extends NetworkException {
  const UnauthorizedException({
    super.message = 'Unauthorized. Please log in again.',
    super.originalError,
    super.stackTrace,
  });
}

/// Server returned 403
final class ForbiddenException extends NetworkException {
  const ForbiddenException({
    super.message = 'You do not have permission to perform this action.',
    super.originalError,
    super.stackTrace,
  });
}

/// Server returned 404
final class NotFoundException extends NetworkException {
  const NotFoundException({
    super.message = 'The requested resource was not found.',
    super.originalError,
    super.stackTrace,
  });
}

/// Server returned 409
final class ConflictException extends NetworkException {
  const ConflictException({
    super.message =
        'A conflict occurred with the current state of the resource.',
    super.originalError,
    super.stackTrace,
  });
}

/// Server returned 422
final class UnprocessableException extends NetworkException {
  const UnprocessableException({
    super.message = 'The request was well-formed but contains semantic errors.',
    super.originalError,
    super.stackTrace,
  });
}

/// Server returned 429
final class TooManyRequestsException extends NetworkException {
  /// Seconds to wait before retrying, if server provides Retry-After header
  final int? retryAfterSeconds;

  const TooManyRequestsException({
    super.message = 'Too many requests. Please slow down.',
    this.retryAfterSeconds,
    super.originalError,
    super.stackTrace,
  });
}

/// Server returned 5xx
final class ServerException extends NetworkException {
  final int statusCode;

  const ServerException({
    required this.statusCode,
    super.message = 'A server error occurred.',
    super.originalError,
    super.stackTrace,
  });
}

/// SSL / certificate pinning failure
final class CertificateException extends NetworkException {
  const CertificateException({
    super.message = 'Certificate verification failed.',
    super.originalError,
    super.stackTrace,
  });
}

/// Request was cancelled via CancelToken
final class RequestCancelledException extends NetworkException {
  const RequestCancelledException({
    super.message = 'Request was cancelled.',
    super.originalError,
    super.stackTrace,
  });
}

/// Catch-all for anything not covered above
final class UnexpectedException extends NetworkException {
  const UnexpectedException({
    super.message = 'An unexpected error occurred.',
    super.originalError,
    super.stackTrace,
  });
}
