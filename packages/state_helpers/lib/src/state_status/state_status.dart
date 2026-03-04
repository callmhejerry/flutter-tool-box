// lib/src/state_status/state_status.dart

enum StateStatus {
  initial,
  loading,
  empty,
  error,
  success;

  bool get isInitial => this == StateStatus.initial;
  bool get isLoading => this == StateStatus.loading;
  bool get isEmpty => this == StateStatus.empty;
  bool get isError => this == StateStatus.error;
  bool get isSuccess => this == StateStatus.success;

  /// True when a result is available (success or empty)
  bool get isComplete => isSuccess || isEmpty;

  /// True when no interaction has happened yet or is in flight
  bool get isBusy => isInitial || isLoading;
}
