// lib/src/interceptors/retry_interceptor.dart

import 'package:dio/dio.dart';
import '../config/retry_config.dart';

/// Dio interceptor that automatically retries failed requests
/// with exponential backoff.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final RetryConfig config;

  RetryInterceptor({required this.dio, required this.config});

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = _getAttempt(err.requestOptions);

    final shouldRetry =
        config.maxAttempts > 0 &&
        attempt < config.maxAttempts &&
        _shouldRetry(err);

    if (!shouldRetry) {
      return handler.next(err);
    }

    final delay = config.delayForAttempt(attempt);

    await Future.delayed(delay);

    // Increment attempt count in extra map
    final options = err.requestOptions.copyWith(
      extra: {...err.requestOptions.extra, _attemptKey: attempt + 1},
    );

    try {
      final response = await dio.fetch(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    // Never retry cancellations
    if (err.type == DioExceptionType.cancel) return false;

    // Retry on connection errors if configured
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return config.retryOnConnectionError;
    }

    // Retry on configured status codes
    final statusCode = err.response?.statusCode;
    if (statusCode != null) {
      return config.retryOnStatusCodes.contains(statusCode);
    }

    return false;
  }

  int _getAttempt(RequestOptions options) =>
      (options.extra[_attemptKey] as int?) ?? 0;

  static const _attemptKey = 'tb_dio_retry_attempt';
}
