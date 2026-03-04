// lib/src/interceptors/logging_interceptor.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Pretty-prints requests and responses to the debug console.
/// Only attach this in non-production builds.
class LoggingInterceptor extends Interceptor {
  final bool logRequestHeaders;
  final bool logResponseBody;
  final bool logRequestBody;

  const LoggingInterceptor({
    this.logRequestHeaders = false, // avoid logging auth tokens by default
    this.logResponseBody = true,
    this.logRequestBody = true,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('┌── REQUEST ────────────────────────────────────');
    debugPrint('│ ${options.method.toUpperCase()} ${options.uri}');
    if (logRequestHeaders) {
      debugPrint('│ Headers: ${options.headers}');
    }
    if (logRequestBody && options.data != null) {
      debugPrint('│ Body: ${options.data}');
    }
    debugPrint('└───────────────────────────────────────────────');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('┌── RESPONSE ───────────────────────────────────');
    debugPrint('│ ${response.statusCode} ${response.requestOptions.uri}');
    if (logResponseBody) {
      debugPrint('│ Body: ${response.data}');
    }
    debugPrint('└───────────────────────────────────────────────');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('┌── ERROR ──────────────────────────────────────');
    debugPrint('│ ${err.type.name.toUpperCase()} ${err.requestOptions.uri}');
    debugPrint('│ Message: ${err.message}');
    if (err.response != null) {
      debugPrint('│ Status: ${err.response?.statusCode}');
      debugPrint('│ Body: ${err.response?.data}');
    }
    debugPrint('└───────────────────────────────────────────────');
    handler.next(err);
  }
}
