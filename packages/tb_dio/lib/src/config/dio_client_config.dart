// lib/src/config/dio_client_config.dart

import 'package:dio/dio.dart';
import 'retry_config.dart';

/// Full configuration for [DioClient].
///
/// Pass this once at app startup — typically inside your DI setup.
///
/// ```dart
/// DioClientConfig(
///   baseUrl: 'https://api.myapp.com/v1',
///   defaultHeaders: {'Content-Type': 'application/json'},
///   dynamicHeaders: () async => {
///     'Authorization': 'Bearer ${await tokenStorage.getToken()}',
///   },
///   retryConfig: RetryConfig(maxAttempts: 3),
///   interceptors: [MyLoggingInterceptor()],
/// )
/// ```
class DioClientConfig {
  /// Base URL for all requests
  final String baseUrl;

  /// Static headers sent with every request (e.g. Content-Type, Accept)
  final Map<String, String> defaultHeaders;

  /// Async callback for headers that change at runtime (e.g. auth token).
  /// Called before every request.
  final Future<Map<String, String>> Function()? dynamicHeaders;

  /// Timeout for establishing a connection
  final Duration connectTimeout;

  /// Timeout for receiving data after connection is established
  final Duration receiveTimeout;

  /// Timeout for sending data (relevant for uploads)
  final Duration sendTimeout;

  /// SHA-256 fingerprints of allowed certificates.
  /// If non-empty, certificate pinning is enforced.
  final List<String> allowedCertificateFingerprints;

  /// Extra Dio interceptors the app wants to inject
  /// (e.g. auth refresh interceptor, analytics interceptor)
  final List<Interceptor> interceptors;

  /// Retry configuration — set to [RetryConfig.none] to disable
  final RetryConfig retryConfig;

  /// If true, pretty-prints all requests and responses to the console.
  /// Should be false in production.
  final bool enableLogging;

  /// Follow redirects automatically
  final bool followRedirects;

  /// Maximum number of redirects to follow
  final int maxRedirects;

  const DioClientConfig({
    required this.baseUrl,
    this.defaultHeaders = const {'Content-Type': 'application/json'},
    this.dynamicHeaders,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
    this.allowedCertificateFingerprints = const [],
    this.interceptors = const [],
    this.retryConfig = const RetryConfig(),
    this.enableLogging = false,
    this.followRedirects = true,
    this.maxRedirects = 5,
  });

  /// Quick config for development
  factory DioClientConfig.dev({required String baseUrl}) => DioClientConfig(
    baseUrl: baseUrl,
    enableLogging: true,
    retryConfig: const RetryConfig(maxAttempts: 1),
  );

  /// Quick config for production
  factory DioClientConfig.prod({
    required String baseUrl,
    required Future<Map<String, String>> Function() dynamicHeaders,
    List<String> certificateFingerprints = const [],
  }) => DioClientConfig(
    baseUrl: baseUrl,
    dynamicHeaders: dynamicHeaders,
    enableLogging: false,
    allowedCertificateFingerprints: certificateFingerprints,
    retryConfig: const RetryConfig(),
  );
}
