class AssetOptException implements Exception {
  final String message;

  AssetOptException(this.message);

  @override
  String toString() => 'AssetOptException: $message';
}
