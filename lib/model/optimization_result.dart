import 'asset_info.dart';

class OptimizationResult {
  final AssetInfo originalAsset;
  final int optimizedSize;
  final int savedBytes;
  final DateTime optimizedAt;

  OptimizationResult({
    required this.originalAsset,
    required this.optimizedSize,
    required this.savedBytes,
    required this.optimizedAt,
  });

  double get savingsPercentage =>
      (savedBytes / originalAsset.size * 100).toDouble();

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
