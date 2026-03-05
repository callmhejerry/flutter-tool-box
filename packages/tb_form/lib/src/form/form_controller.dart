// lib/src/form/form_controller.dart

import 'package:flutter/foundation.dart';
import '../fields/form_field_controller.dart';
import 'form_status.dart';

/// Manages multiple [FormFieldController]s and overall form state.
///
/// ```dart
/// class LoginForm extends FormController {
///   final email = FormFieldController<String>(
///     initialValue: '',
///     validators: [Validators.required(), Validators.email()],
///   );
///
///   final password = FormFieldController<String>(
///     initialValue: '',
///     validators: [
///       Validators.required(),
///       PasswordValidators.minLength(min: 8),
///     ],
///   );
///
///   @override
///   List<FormFieldController> get fields => [email, password];
///
///   @override
///   Future<void> onSubmit() async {
///     await authService.login(
///       email: email.value,
///       password: password.value,
///     );
///   }
/// }
/// ```
abstract class FormController extends ChangeNotifier {
  FormStatus _status = FormStatus.pure;
  Object? _submissionError;

  FormController() {
    // Listen to all fields and update form status on any change
    for (final field in fields) {
      field.addListener(_onFieldChanged);
    }
  }

  // ── Abstract ───────────────────────────────────────────────────────────────

  /// All fields this form manages — override in subclass
  List<FormFieldController> get fields;

  /// Business logic to run on valid submission — override in subclass
  Future<void> onSubmit();

  // ── State ──────────────────────────────────────────────────────────────────

  FormStatus get status => _status;
  Object? get submissionError => _submissionError;

  bool get isPure => _status.isPure;
  bool get isValid => _status.isValid;
  bool get isInvalid => _status.isInvalid;
  bool get isSubmitting => _status.isSubmitting;
  bool get isSubmitted => _status.isSubmitted;
  bool get isFailed => _status.isFailed;
  bool get canSubmit => _allFieldsValid && !_status.isBusy;

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Validate all fields and submit if valid.
  Future<void> submit() async {
    // Touch and validate all fields to show errors
    final validationResults = await Future.wait(
      fields.map((f) => f.validate()),
    );

    final allValid = validationResults.every((v) => v);

    if (!allValid) {
      _setStatus(FormStatus.invalid);
      return;
    }

    _setStatus(FormStatus.submitting);
    _submissionError = null;

    try {
      await onSubmit();
      _setStatus(FormStatus.submitted);
    } catch (e) {
      _submissionError = e;
      _setStatus(FormStatus.failed);
    }
  }

  /// Reset all fields and form status
  void reset() {
    for (final field in fields) {
      field.reset();
    }
    _submissionError = null;
    _setStatus(FormStatus.pure);
  }

  /// Set a server-side error on a specific field
  void setFieldError(FormFieldController field, String error) {
    field.setError(error);
    _setStatus(FormStatus.invalid);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  void _onFieldChanged() {
    // Don't override submitting status
    if (_status.isSubmitting) return;

    if (_allFieldsValid) {
      _setStatus(FormStatus.valid);
    } else if (_anyFieldTouched) {
      _setStatus(FormStatus.invalid);
    } else {
      _setStatus(FormStatus.pure);
    }
  }

  void _setStatus(FormStatus status) {
    if (_status == status) return;
    _status = status;
    notifyListeners();
  }

  bool get _allFieldsValid => fields.every((f) => f.isValid);
  bool get _anyFieldTouched => fields.any((f) => f.isTouched);

  @override
  void dispose() {
    for (final field in fields) {
      field.removeListener(_onFieldChanged);
      field.dispose();
    }
    super.dispose();
  }
}
