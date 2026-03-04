// lib/src/exceptions/exception_mapper.dart

import 'package:dio/dio.dart';
import 'network_exception.dart';
import 'package:result/result.dart';

/// Maps [DioException] → [NetworkException] → [Failure]
class ExceptionMapper {
  const ExceptionMapper._();

  /// Convert a raw [DioException] to a typed [NetworkException]
  static NetworkException fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.cancel:
        return RequestCancelledException(
          originalError: e,
          stackTrace: e.stackTrace,
        );

      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return TimeoutException(originalError: e, stackTrace: e.stackTrace);

      case DioExceptionType.connectionError:
        return NoInternetException(originalError: e, stackTrace: e.stackTrace);

      case DioExceptionType.badCertificate:
        return CertificateException(originalError: e, stackTrace: e.stackTrace);

      case DioExceptionType.badResponse:
        return _fromResponse(e);

      case DioExceptionType.unknown:
        // Check if it's a socket/connection error wrapped as unknown
        final error = e.error?.toString() ?? '';
        if (error.contains('SocketException') ||
            error.contains('Connection refused') ||
            error.contains('Network is unreachable')) {
          return NoInternetException(
            originalError: e,
            stackTrace: e.stackTrace,
          );
        }
        return UnexpectedException(
          message: e.message ?? 'An unexpected error occurred.',
          originalError: e,
          stackTrace: e.stackTrace,
        );
    }
  }

  /// Convert a [NetworkException] to a [Failure] for use with tb_result
  static Failure toFailure(NetworkException e) => switch (e) {
    NoInternetException() => Failure.network(
      message: e.message,
      originalError: e,
      stackTrace: e.stackTrace,
    ),
    TimeoutException() => Failure.network(
      message: e.message,
      originalError: e,
      stackTrace: e.stackTrace,
    ),
    UnauthorizedException() => Failure(
      code: 'UNAUTHORIZED',
      message: e.message,
      originalError: e,
      stackTrace: e.stackTrace,
    ),
    ForbiddenException() => Failure(
      code: 'FORBIDDEN',
      message: e.message,
      originalError: e,
      stackTrace: e.stackTrace,
    ),
    NotFoundException() => Failure(
      code: 'NOT_FOUND',
      message: e.message,
      originalError: e,
      stackTrace: e.stackTrace,
    ),
    ConflictException() => Failure(
      code: 'CONFLICT',
      message: e.message,
      originalError: e,
      stackTrace: e.stackTrace,
    ),
    TooManyRequestsException() => Failure(
      code: 'TOO_MANY_REQUESTS',
      message: e.message,
      originalError: e,
      stackTrace: e.stackTrace,
    ),
    ServerException(statusCode: final code) => Failure.server(
      message: e.message,
      statusCode: code,
      originalError: e,
      stackTrace: e.stackTrace,
    ),
    CertificateException() => Failure(
      code: 'CERTIFICATE_ERROR',
      message: e.message,
      originalError: e,
      stackTrace: e.stackTrace,
    ),
    RequestCancelledException() => Failure(
      code: 'REQUEST_CANCELLED',
      message: e.message,
      originalError: e,
      stackTrace: e.stackTrace,
    ),
    UnprocessableException() => Failure.validation(
      message: e.message,
      originalError: e,
      stackTrace: e.stackTrace,
    ),
    UnexpectedException() => Failure.unexpected(
      message: e.message,
      originalError: e,
      stackTrace: e.stackTrace,
    ),
  };

  // ── Private ────────────────────────────────────────────────────────────────

  static NetworkException _fromResponse(DioException e) {
    final statusCode = e.response?.statusCode ?? 0;
    final message =
        _extractMessage(e.response) ?? e.message ?? 'An error occurred.';

    return switch (statusCode) {
      401 => UnauthorizedException(
        message: message,
        originalError: e,
        stackTrace: e.stackTrace,
      ),
      403 => ForbiddenException(
        message: message,
        originalError: e,
        stackTrace: e.stackTrace,
      ),
      404 => NotFoundException(
        message: message,
        originalError: e,
        stackTrace: e.stackTrace,
      ),
      409 => ConflictException(
        message: message,
        originalError: e,
        stackTrace: e.stackTrace,
      ),
      422 => UnprocessableException(
        message: message,
        originalError: e,
        stackTrace: e.stackTrace,
      ),
      429 => TooManyRequestsException(
        message: message,
        retryAfterSeconds: _parseRetryAfter(e.response),
        originalError: e,
        stackTrace: e.stackTrace,
      ),
      >= 500 => ServerException(
        statusCode: statusCode,
        message: message,
        originalError: e,
        stackTrace: e.stackTrace,
      ),
      _ => UnexpectedException(
        message: message,
        originalError: e,
        stackTrace: e.stackTrace,
      ),
    };
  }

  /// Try to extract a human-readable message from common API error shapes:
  /// { "message": "..." } or { "error": "..." } or { "errors": [...] }
  static String? _extractMessage(Response? response) {
    try {
      final data = response?.data;
      if (data is Map<String, dynamic>) {
        return (data['message'] ?? data['error'] ?? data['detail'])?.toString();
      }
    } catch (_) {}
    return null;
  }

  static int? _parseRetryAfter(Response? response) {
    try {
      final header = response?.headers.value('retry-after');
      if (header != null) return int.tryParse(header);
    } catch (_) {}
    return null;
  }
}
