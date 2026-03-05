// lib/src/validators/basic_validators.dart

import 'validator.dart';

/// Factory class for all built-in synchronous validators.
///
/// ```dart
/// FormFieldController<String>(
///   validators: [
///     Validators.required(),
///     Validators.email(),
///     Validators.minLength(3),
///   ],
/// )
/// ```
abstract final class Validators {
  Validators._();

  // ── Required ───────────────────────────────────────────────────────────────

  static Validator<T> required<T>({
    String message = 'This field is required.',
  }) => FnValidator<T>((value) {
    if (value == null) return message;
    if (value is String && value.trim().isEmpty) return message;
    if (value is List && value.isEmpty) return message;
    return null;
  });

  // ── String length ──────────────────────────────────────────────────────────

  static Validator<String> minLength(int min, {String? message}) =>
      FnValidator<String>((value) {
        if (value == null || value.isEmpty) return null;
        if (value.length < min) {
          return message ?? 'Must be at least $min characters.';
        }
        return null;
      });

  static Validator<String> maxLength(int max, {String? message}) =>
      FnValidator<String>((value) {
        if (value == null || value.isEmpty) return null;
        if (value.length > max) {
          return message ?? 'Must be no more than $max characters.';
        }
        return null;
      });

  static Validator<String> exactLength(int length, {String? message}) =>
      FnValidator<String>((value) {
        if (value == null || value.isEmpty) return null;
        if (value.length != length) {
          return message ?? 'Must be exactly $length characters.';
        }
        return null;
      });

  // ── Email ──────────────────────────────────────────────────────────────────

  static Validator<String> email({
    String message = 'Please enter a valid email address.',
  }) => FnValidator<String>((value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) return message;
    return null;
  });

  // ── Phone ──────────────────────────────────────────────────────────────────

  /// Validates international phone numbers.
  /// Accepts formats: +2348012345678, 08012345678, +1-800-555-0199
  static Validator<String> phone({
    String message = 'Please enter a valid phone number.',
  }) => FnValidator<String>((value) {
    if (value == null || value.isEmpty) return null;
    // Strip spaces, dashes, parentheses for validation
    final cleaned = value.replaceAll(RegExp(r'[\s\-()]'), '');
    final regex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!regex.hasMatch(cleaned)) return message;
    return null;
  });

  // ── Pattern ────────────────────────────────────────────────────────────────

  static Validator<String> pattern(
    RegExp regex, {
    String message = 'Invalid format.',
  }) => FnValidator<String>((value) {
    if (value == null || value.isEmpty) return null;
    if (!regex.hasMatch(value)) return message;
    return null;
  });

  // ── URL ────────────────────────────────────────────────────────────────────

  static Validator<String> url({
    String message = 'Please enter a valid URL.',
  }) => FnValidator<String>((value) {
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return message;
    }
    return null;
  });

  // ── Numeric ────────────────────────────────────────────────────────────────

  static Validator<String> numeric({
    String message = 'Please enter a valid number.',
  }) => FnValidator<String>((value) {
    if (value == null || value.isEmpty) return null;
    if (num.tryParse(value) == null) return message;
    return null;
  });

  static Validator<String> min(num min, {String? message}) =>
      FnValidator<String>((value) {
        if (value == null || value.isEmpty) return null;
        final number = num.tryParse(value);
        if (number == null) return 'Please enter a valid number.';
        if (number < min) return message ?? 'Must be at least $min.';
        return null;
      });

  static Validator<String> max(num max, {String? message}) =>
      FnValidator<String>((value) {
        if (value == null || value.isEmpty) return null;
        final number = num.tryParse(value);
        if (number == null) return 'Please enter a valid number.';
        if (number > max) return message ?? 'Must be no more than $max.';
        return null;
      });

  // ── Equality ───────────────────────────────────────────────────────────────

  /// Validates that this field matches another field's value.
  /// Pass a getter so it always reads the current value.
  ///
  /// ```dart
  /// confirmPasswordField = FormFieldController<String>(
  ///   validators: [
  ///     Validators.mustMatch(
  ///       () => passwordField.state.value,
  ///       message: 'Passwords do not match.',
  ///     ),
  ///   ],
  /// )
  /// ```
  static Validator<T> mustMatch<T>(
    T Function() otherValue, {
    String message = 'Values do not match.',
  }) => FnValidator<T>((value) {
    if (value != otherValue()) return message;
    return null;
  });
}
