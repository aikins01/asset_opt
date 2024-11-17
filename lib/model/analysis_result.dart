import 'asset_info.dart';

class AnalysisResult {
  final List<AssetInfo> assets;
  final Map<String, int> sizeByType;
  final int totalSize;
  final DateTime analyzedAt;

  AnalysisResult({
    required this.assets,
    required this.sizeByType,
    required this.totalSize,
    required this.analyzedAt,
  });

  List<AssetInfo> get largestAssets {
    final sorted = List<AssetInfo>.from(assets);
    sorted.sort((a, b) => b.size.compareTo(a.size));
    return sorted.take(10).toList();
  }
}
