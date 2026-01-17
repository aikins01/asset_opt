import 'asset_info.dart';

/// Result of optimizing a single asset.
class OptimizationResult {
  /// The original asset before optimization.
  final AssetInfo originalAsset;

  /// Size after optimization in bytes.
  final int optimizedSize;

  /// Bytes saved by optimization.
  final int savedBytes;

  /// When the optimization was performed.
  final DateTime optimizedAt;

  /// Creates an optimization result.
  OptimizationResult({
    required this.originalAsset,
    required this.optimizedSize,
    required this.savedBytes,
    required this.optimizedAt,
  });

  /// Percentage of size reduction.
  double get savingsPercentage =>
      (savedBytes / originalAsset.size * 100).toDouble();

  /// File type of the original asset.
  String get assetType => originalAsset.type;

  Map<String, dynamic> toJson() => {
        'originalAsset': originalAsset.toJson(),
        'optimizedSize': optimizedSize,
        'savedBytes': savedBytes,
        'optimizedAt': optimizedAt.toIso8601String(),
        'savingsPercentage': savingsPercentage,
      };

  factory OptimizationResult.fromJson(Map<String, dynamic> json) =>
      OptimizationResult(
        originalAsset: AssetInfo.fromJson(json['originalAsset']),
        optimizedSize: json['optimizedSize'],
        savedBytes: json['savedBytes'],
        optimizedAt: DateTime.parse(json['optimizedAt']),
      );
}
