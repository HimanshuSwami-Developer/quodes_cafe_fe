/// Lifecycle of an async operation held in a cubit state.
enum LoadStatus {
  initial,
  loading,
  success,
  failure;

  bool get isLoading => this == LoadStatus.loading;
  bool get isSuccess => this == LoadStatus.success;
  bool get isFailure => this == LoadStatus.failure;
}
