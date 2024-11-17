import 'asset_info.dart';

class OptimizationResult {
  final AssetInfo originalAsset;
  final AssetInfo optimizedAsset;
  final int savedBytes;
  final DateTime optimizedAt;

  OptimizationResult({
    required this.originalAsset,
    required this.optimizedAsset,
    required this.savedBytes,
    required this.optimizedAt,
  });
}
