/// Exception thrown by asset_opt operations.
class AssetOptException implements Exception {
  /// The error message.
  final String message;

  /// Creates an exception with the given message.
  AssetOptException(this.message);

  @override
  String toString() => 'AssetOptException: $message';
}

/// Exception when optimization is skipped due to missing tools.
class OptimizationSkippedException implements Exception {
  final String message;

  OptimizationSkippedException(this.message);

  @override
  String toString() => message;
}
