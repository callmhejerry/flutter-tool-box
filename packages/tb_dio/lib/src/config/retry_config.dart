// lib/src/config/retry_config.dart

/// Controls exponential backoff retry behaviour.
///
/// ```dart
/// RetryConfig(
///   maxAttempts: 3,
///   initialDelay: Duration(milliseconds: 500),
///   multiplier: 2.0,
///   useJitter: true,
///   retryOn: {408, 429, 500, 502, 503, 504},
/// )
/// ```
class RetryConfig {
  /// Maximum number of retry attempts (not counting the original request)
  final int maxAttempts;

  /// Initial delay before the first retry
  final Duration initialDelay;

  /// Maximum delay cap — backoff will never exceed this
  final Duration maxDelay;

  /// Each retry delay = previous delay * multiplier
  final double multiplier;

  /// Adds random jitter to avoid thundering herd problem.
  /// Final delay = calculated delay * (0.5 + random(0, 1.0))
  final bool useJitter;

  /// HTTP status codes that should trigger a retry.
  /// Defaults to common transient failure codes.
  final Set<int> retryOnStatusCodes;

  /// If true, retry on connection/timeout errors (no response received)
  final bool retryOnConnectionError;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 30),
    this.multiplier = 2.0,
    this.useJitter = true,
    this.retryOnStatusCodes = const {408, 429, 500, 502, 503, 504},
    this.retryOnConnectionError = true,
  });

  /// No retries
  static const RetryConfig none = RetryConfig(maxAttempts: 0);

  /// Aggressive retry for critical operations
  static const RetryConfig aggressive = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(milliseconds: 300),
    maxDelay: Duration(seconds: 60),
    multiplier: 2.0,
    useJitter: true,
  );

  /// Compute the delay for a given attempt (0-indexed)
  Duration delayForAttempt(int attempt) {
    if (attempt <= 0) return initialDelay;

    final exponential = initialDelay.inMilliseconds * _pow(multiplier, attempt);
    final capped = exponential.clamp(0, maxDelay.inMilliseconds).toInt();

    if (!useJitter) return Duration(milliseconds: capped);

    // Full jitter: random value between 0 and capped delay
    final jitter = (capped * (0.5 + _random() * 0.5)).toInt();
    return Duration(milliseconds: jitter);
  }

  // Pure Dart pow to avoid dart:math import at package level
  double _pow(double base, int exp) {
    double result = 1.0;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }

  double _random() {
    // Using DateTime as a simple seed — avoids dart:math dependency
    return (DateTime.now().microsecondsSinceEpoch % 1000) / 1000.0;
  }
}
