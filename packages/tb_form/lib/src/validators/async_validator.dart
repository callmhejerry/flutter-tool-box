// lib/src/validators/async_validator.dart

/// Base interface for async validators.
///
/// Async validators run after all sync validators pass.
///
/// ```dart
/// class UsernameAvailableValidator implements AsyncValidator<String> {
///   final AuthApi _api;
///   UsernameAvailableValidator(this._api);
///
///   @override
///   Future<String?> validate(String? value) async {
///     if (value == null || value.isEmpty) return null;
///     final taken = await _api.isUsernameTaken(value);
///     return taken ? 'Username is already taken.' : null;
///   }
/// }
/// ```
abstract interface class AsyncValidator<T> {
  Future<String?> validate(T? value);
}

/// Convenience typedef for inline async validators
typedef AsyncValidatorFn<T> = Future<String?> Function(T? value);

/// Wraps an [AsyncValidatorFn] as an [AsyncValidator]
class FnAsyncValidator<T> implements AsyncValidator<T> {
  final AsyncValidatorFn<T> fn;
  const FnAsyncValidator(this.fn);

  @override
  Future<String?> validate(T? value) => fn(value);
}

/// Wraps an async validator with debouncing.
/// Useful for validators that call an API — prevents a request on
/// every keystroke.
///
/// ```dart
/// AsyncValidators.debounce(
///   validator: UsernameAvailableValidator(api),
///   duration: Duration(milliseconds: 500),
/// )
/// ```
class DebouncedAsyncValidator<T> implements AsyncValidator<T> {
  final AsyncValidator<T> validator;
  final Duration duration;

  DebouncedAsyncValidator({
    required this.validator,
    this.duration = const Duration(milliseconds: 500),
  });

  DateTime? _lastCallTime;
  // Future<String?>? _pendingFuture;

  @override
  Future<String?> validate(T? value) async {
    _lastCallTime = DateTime.now();
    final callTime = _lastCallTime;

    await Future.delayed(duration);

    // If another call came in during the delay, abort this one
    if (_lastCallTime != callTime) return null;

    return validator.validate(value);
  }
}

/// Factory class for common async validator patterns
abstract final class AsyncValidators {
  AsyncValidators._();

  static AsyncValidator<T> debounce<T>({
    required AsyncValidator<T> validator,
    Duration duration = const Duration(milliseconds: 500),
  }) => DebouncedAsyncValidator(validator: validator, duration: duration);

  static AsyncValidator<T> fromFn<T>(AsyncValidatorFn<T> fn) =>
      FnAsyncValidator(fn);
}
