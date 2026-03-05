// lib/src/validators/validator.dart

/// Base interface for all synchronous validators.
///
/// Returns an error message string if invalid, null if valid.
///
/// ```dart
/// class NotEmptyValidator implements Validator<String> {
///   @override
///   String? validate(String? value) {
///     if (value == null || value.isEmpty) return 'Required';
///     return null;
///   }
/// }
/// ```
abstract interface class Validator<T> {
  String? validate(T? value);
}

/// Convenience typedef for inline validators
typedef ValidatorFn<T> = String? Function(T? value);

/// Wraps a [ValidatorFn] as a [Validator]
class FnValidator<T> implements Validator<T> {
  final ValidatorFn<T> fn;
  const FnValidator(this.fn);

  @override
  String? validate(T? value) => fn(value);
}
