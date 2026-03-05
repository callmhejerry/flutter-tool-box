// lib/src/form/form_status.dart

/// Represents the overall status of a [FormController].
enum FormStatus {
  /// No fields have been touched yet
  pure,

  /// All fields are valid and form is ready to submit
  valid,

  /// One or more fields have validation errors
  invalid,

  /// Form has been submitted and is awaiting response
  submitting,

  /// Form submission succeeded
  submitted,

  /// Form submission failed
  failed;

  bool get isPure => this == FormStatus.pure;
  bool get isValid => this == FormStatus.valid;
  bool get isInvalid => this == FormStatus.invalid;
  bool get isSubmitting => this == FormStatus.submitting;
  bool get isSubmitted => this == FormStatus.submitted;
  bool get isFailed => this == FormStatus.failed;

  /// True when form cannot be interacted with
  bool get isBusy => isSubmitting;

  /// True when form can be submitted
  bool get canSubmit => isValid && !isBusy;
}
