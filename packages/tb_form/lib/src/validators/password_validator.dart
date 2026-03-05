// lib/src/validators/password_validators.dart

import 'validator.dart';

/// Password strength level
enum PasswordStrength {
  weak,
  fair,
  strong,
  veryStrong;

  bool get isWeak => this == PasswordStrength.weak;
  bool get isFair => this == PasswordStrength.fair;
  bool get isStrong => this == PasswordStrength.strong;
  bool get isVeryStrong => this == PasswordStrength.veryStrong;

  /// Minimum strength required for the field to be considered valid
  bool isAtLeast(PasswordStrength minimum) => index >= minimum.index;
}

/// Password-specific validators and utilities.
abstract final class PasswordValidators {
  PasswordValidators._();

  // ── Validators ─────────────────────────────────────────────────────────────

  static Validator<String> minLength({int min = 8, String? message}) =>
      FnValidator<String>((value) {
        if (value == null || value.isEmpty) return null;
        if (value.length < min) {
          return message ?? 'Password must be at least $min characters.';
        }
        return null;
      });

  static Validator<String> hasUppercase({
    String message = 'Password must contain at least one uppercase letter.',
  }) => FnValidator<String>((value) {
    if (value == null || value.isEmpty) return null;
    if (!value.contains(RegExp(r'[A-Z]'))) return message;
    return null;
  });

  static Validator<String> hasLowercase({
    String message = 'Password must contain at least one lowercase letter.',
  }) => FnValidator<String>((value) {
    if (value == null || value.isEmpty) return null;
    if (!value.contains(RegExp(r'[a-z]'))) return message;
    return null;
  });

  static Validator<String> hasNumber({
    String message = 'Password must contain at least one number.',
  }) => FnValidator<String>((value) {
    if (value == null || value.isEmpty) return null;
    if (!value.contains(RegExp(r'[0-9]'))) return message;
    return null;
  });

  static Validator<String> hasSpecialChar({
    String message = 'Password must contain at least one special character.',
  }) => FnValidator<String>((value) {
    if (value == null || value.isEmpty) return null;
    if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return message;
    }
    return null;
  });

  static Validator<String> noSpaces({
    String message = 'Password must not contain spaces.',
  }) => FnValidator<String>((value) {
    if (value == null || value.isEmpty) return null;
    if (value.contains(' ')) return message;
    return null;
  });

  /// Validates minimum strength level
  ///
  /// ```dart
  /// PasswordValidators.minStrength(PasswordStrength.strong)
  /// ```
  static Validator<String> minStrength(
    PasswordStrength minimum, {
    String? message,
  }) => FnValidator<String>((value) {
    if (value == null || value.isEmpty) return null;
    final strength = getStrength(value);
    if (!strength.isAtLeast(minimum)) {
      return message ??
          'Password is too weak. '
              'Minimum required: ${minimum.name}.';
    }
    return null;
  });

  // ── Strength Calculator ────────────────────────────────────────────────────

  /// Calculates password strength score and returns [PasswordStrength].
  ///
  /// ```dart
  /// final strength = PasswordValidators.getStrength('MyPass1!');
  /// // → PasswordStrength.strong
  /// ```
  static PasswordStrength getStrength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;

    int score = 0;

    // Length scoring
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;

    // Character variety
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;

    // Penalise common patterns
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) score--; // repeated chars
    if (RegExp(
      r'(012|123|234|345|456|567|678|789|890|abc|qwerty)',
      caseSensitive: false,
    ).hasMatch(password))
      score--; // sequences

    return switch (score) {
      <= 2 => PasswordStrength.weak,
      <= 4 => PasswordStrength.fair,
      <= 6 => PasswordStrength.strong,
      _ => PasswordStrength.veryStrong,
    };
  }

  /// Returns a score from 0.0 to 1.0 for use in a strength indicator bar.
  static double getStrengthScore(String password) {
    return switch (getStrength(password)) {
      PasswordStrength.weak => 0.25,
      PasswordStrength.fair => 0.5,
      PasswordStrength.strong => 0.75,
      PasswordStrength.veryStrong => 1.0,
    };
  }

  /// Human readable label for the strength level
  static String getStrengthLabel(String password) {
    return switch (getStrength(password)) {
      PasswordStrength.weak => 'Weak',
      PasswordStrength.fair => 'Fair',
      PasswordStrength.strong => 'Strong',
      PasswordStrength.veryStrong => 'Very Strong',
    };
  }

  /// Color hex string for each strength level
  /// — use in your PasswordStrengthIndicator widget
  static String getStrengthColorHex(String password) {
    return switch (getStrength(password)) {
      PasswordStrength.weak => '#EF4444', // red
      PasswordStrength.fair => '#F97316', // orange
      PasswordStrength.strong => '#22C55E', // green
      PasswordStrength.veryStrong => '#16A34A', // dark green
    };
  }
}
