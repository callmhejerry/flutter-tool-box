// lib/src/fields/field_state.dart

/// Immutable snapshot of a single form field's state.
class FieldState<T> {
  /// Current value of the field
  final T value;

  /// Validation error message — null means field is valid
  final String? error;

  /// True if value has changed from its initial value
  final bool isDirty;

  /// True if the field has been focused and then blurred
  final bool isTouched;

  /// True while an async validator is running
  final bool isValidating;

  const FieldState({
    required this.value,
    this.error,
    this.isDirty = false,
    this.isTouched = false,
    this.isValidating = false,
  });

  /// True if field has no error and is not currently validating
  bool get isValid => error == null && !isValidating;

  /// True if field has an error
  bool get isInvalid => error != null;

  /// True if field should show its error
  /// — only show errors after the user has interacted with the field
  bool get showError => isInvalid && isTouched;

  FieldState<T> copyWith({
    T? value,
    String? error,
    bool clearError = false,
    bool? isDirty,
    bool? isTouched,
    bool? isValidating,
  }) => FieldState<T>(
    value: value ?? this.value,
    error: clearError ? null : (error ?? this.error),
    isDirty: isDirty ?? this.isDirty,
    isTouched: isTouched ?? this.isTouched,
    isValidating: isValidating ?? this.isValidating,
  );

  @override
  String toString() =>
      'FieldState(value: $value, error: $error, '
      'isDirty: $isDirty, isTouched: $isTouched)';
}
