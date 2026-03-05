// lib/src/fields/form_field_controller.dart

import 'package:flutter/foundation.dart';
import '../validators/validator.dart';
import '../validators/async_validator.dart';
import 'field_state.dart';

/// Manages the state of a single form field.
///
/// Extends [ChangeNotifier] so Flutter widgets can listen
/// with [ListenableBuilder] or [AnimatedBuilder] — no extra packages needed.
///
/// ```dart
/// final emailField = FormFieldController<String>(
///   initialValue: '',
///   validators: [
///     Validators.required(),
///     Validators.email(),
///   ],
/// );
///
/// // In your widget
/// ListenableBuilder(
///   listenable: emailField,
///   builder: (context, _) => TextField(
///     onChanged: emailField.setValue,
///     onEditingComplete: emailField.markTouched,
///     decoration: InputDecoration(
///       errorText: emailField.state.showError
///           ? emailField.state.error
///           : null,
///     ),
///   ),
/// )
/// ```
class FormFieldController<T> extends ChangeNotifier {
  final T _initialValue;
  final List<Validator<T>> validators;
  final List<AsyncValidator<T>> asyncValidators;

  late FieldState<T> _state;

  FormFieldController({
    required T initialValue,
    this.validators = const [],
    this.asyncValidators = const [],
  }) : _initialValue = initialValue,
       _state = FieldState<T>(value: initialValue);

  // ── State ──────────────────────────────────────────────────────────────────

  FieldState<T> get state => _state;
  T get value => _state.value;
  String? get error => _state.error;
  bool get isValid => _state.isValid;
  bool get isInvalid => _state.isInvalid;
  bool get isDirty => _state.isDirty;
  bool get isTouched => _state.isTouched;
  bool get isValidating => _state.isValidating;

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Called on every value change (e.g. TextField.onChanged)
  void setValue(T value) {
    _state = _state.copyWith(value: value, isDirty: value != _initialValue);
    notifyListeners();
    _runValidation(value);
  }

  /// Called when field loses focus (e.g. TextField.onEditingComplete)
  void markTouched() {
    if (_state.isTouched) return;
    _state = _state.copyWith(isTouched: true);
    notifyListeners();
    // Run validation on first touch to show errors immediately
    _runValidation(_state.value);
  }

  /// Manually set an external error (e.g. from server response)
  void setError(String error) {
    _state = _state.copyWith(isTouched: true, error: error);
    notifyListeners();
  }

  /// Clear the current error
  void clearError() {
    _state = _state.copyWith(clearError: true);
    notifyListeners();
  }

  /// Validate and mark as touched — call before form submission
  /// to show all errors at once.
  Future<bool> validate() async {
    _state = _state.copyWith(isTouched: true);
    notifyListeners();
    return _runValidation(_state.value);
  }

  /// Reset field to its initial state
  void reset() {
    _state = FieldState<T>(value: _initialValue);
    notifyListeners();
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<bool> _runValidation(T value) async {
    // Run sync validators first
    for (final validator in validators) {
      final error = validator.validate(value);
      if (error != null) {
        _state = _state.copyWith(
          error: error,
          clearError: false,
          isValidating: false,
        );
        notifyListeners();
        return false;
      }
    }

    // All sync validators passed — clear sync errors
    _state = _state.copyWith(clearError: true);
    notifyListeners();

    // Run async validators if any
    if (asyncValidators.isEmpty) return true;

    _state = _state.copyWith(isValidating: true);
    notifyListeners();

    for (final asyncValidator in asyncValidators) {
      final error = await asyncValidator.validate(value);

      // Value may have changed while we were validating — abort
      if (value != _state.value) return false;

      if (error != null) {
        _state = _state.copyWith(error: error, isValidating: false);
        notifyListeners();
        return false;
      }
    }

    _state = _state.copyWith(clearError: true, isValidating: false);
    notifyListeners();
    return true;
  }
}
