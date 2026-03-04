// lib/src/client/dio_client.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:result/result.dart';
import '../config/dio_client_config.dart';
import '../exceptions/exception_mapper.dart';
import '../exceptions/network_exception.dart';
import '../interceptors/logging_interceptor.dart';
import '../interceptors/retry_interceptor.dart';

/// Controls how the client handles errors per request.
enum ResultMode {
  /// Throws [NetworkException] on error — caller uses try/catch
  throwOnError,

  /// Returns [Result<T>] — no try/catch needed
  returnResult,
}

/// The core HTTP client.
///
/// Instantiate once and inject via your DI container.
///
/// ```dart
/// final client = DioClient(config: DioClientConfig(
///   baseUrl: 'https://api.myapp.com',
///   dynamicHeaders: () async => {'Authorization': 'Bearer $token'},
///   retryConfig: RetryConfig(maxAttempts: 3),
/// ));
/// ```
class DioClient {
  late final Dio _dio;
  final DioClientConfig config;

  DioClient({required this.config}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.sendTimeout,
        headers: config.defaultHeaders,
        followRedirects: config.followRedirects,
        maxRedirects: config.maxRedirects,
      ),
    );

    _setupInterceptors();
    _setupCertificatePinning();
  }

  // ── Setup ──────────────────────────────────────────────────────────────────

  void _setupInterceptors() {
    // 1. Dynamic headers interceptor (runs first)
    if (config.dynamicHeaders != null) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final headers = await config.dynamicHeaders!();
            options.headers.addAll(headers);
            handler.next(options);
          },
        ),
      );
    }

    // 2. App-provided interceptors (e.g. auth refresh)
    _dio.interceptors.addAll(config.interceptors);

    // 3. Retry interceptor
    if (config.retryConfig.maxAttempts > 0) {
      _dio.interceptors.add(
        RetryInterceptor(dio: _dio, config: config.retryConfig),
      );
    }

    // 4. Logging interceptor (last so it sees final request state)
    if (config.enableLogging) {
      _dio.interceptors.add(const LoggingInterceptor());
    }
  }

  void _setupCertificatePinning() {
    if (config.allowedCertificateFingerprints.isEmpty) return;

    (_dio.httpClientAdapter as dynamic)
        .onHttpClientCreate = (HttpClient client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
            final fingerprint = cert.sha1
                .map((b) => b.toRadixString(16).padLeft(2, '0'))
                .join(':')
                .toUpperCase();

            return config.allowedCertificateFingerprints.contains(fingerprint);
          };
      return client;
    };
  }

  // ── Core request method ────────────────────────────────────────────────────

  Future<dynamic> _request({
    required String method,
    required String path,
    Map<String, dynamic>? queryParameters,
    dynamic data,
    Options? options,
    CancelToken? cancelToken,
    ResultMode mode = ResultMode.throwOnError,
  }) async {
    try {
      final response = await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: (options ?? Options()).copyWith(method: method),
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      final networkException = ExceptionMapper.fromDioException(e);

      if (mode == ResultMode.returnResult) {
        return Result.failure(ExceptionMapper.toFailure(networkException));
      }

      throw networkException;
    } catch (e, st) {
      final unexpected = UnexpectedException(originalError: e, stackTrace: st);

      if (mode == ResultMode.returnResult) {
        return Result.failure(ExceptionMapper.toFailure(unexpected));
      }

      throw unexpected;
    }
  }

  // ── Public HTTP methods ────────────────────────────────────────────────────

  /// GET request
  ///
  /// ```dart
  /// // Throw mode
  /// final data = await client.get('/users', fromJson: User.fromJson);
  ///
  /// // Result mode
  /// final result = await client.get(
  ///   '/users',
  ///   fromJson: User.fromJson,
  ///   mode: ResultMode.returnResult,
  /// );
  /// ```
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ResultMode mode = ResultMode.throwOnError,
    T Function(dynamic json)? fromJson,
  }) async {
    final data = await _request(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      mode: mode,
    );

    return _parse<T>(data, fromJson, mode);
  }

  /// POST request
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ResultMode mode = ResultMode.throwOnError,
    T Function(dynamic json)? fromJson,
  }) async {
    final responseData = await _request(
      method: 'POST',
      path: path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      mode: mode,
    );

    return _parse<T>(responseData, fromJson, mode);
  }

  /// PUT request
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ResultMode mode = ResultMode.throwOnError,
    T Function(dynamic json)? fromJson,
  }) async {
    final responseData = await _request(
      method: 'PUT',
      path: path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      mode: mode,
    );

    return _parse<T>(responseData, fromJson, mode);
  }

  /// PATCH request
  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ResultMode mode = ResultMode.throwOnError,
    T Function(dynamic json)? fromJson,
  }) async {
    final responseData = await _request(
      method: 'PATCH',
      path: path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      mode: mode,
    );

    return _parse<T>(responseData, fromJson, mode);
  }

  /// DELETE request
  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ResultMode mode = ResultMode.throwOnError,
    T Function(dynamic json)? fromJson,
  }) async {
    final responseData = await _request(
      method: 'DELETE',
      path: path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      mode: mode,
    );

    return _parse<T>(responseData, fromJson, mode);
  }

  // ── Parsing ────────────────────────────────────────────────────────────────

  T _parse<T>(
    dynamic data,
    T Function(dynamic json)? fromJson,
    ResultMode mode,
  ) {
    // In Result mode, a failure was already returned upstream
    if (data is Result) return data as T;

    if (fromJson != null) return fromJson(data);

    return data as T;
  }

  /// Expose the underlying [Dio] instance for edge cases
  Dio get dio => _dio;
}
