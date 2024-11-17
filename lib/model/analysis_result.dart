import 'asset_detail.dart';
import 'asset_issue.dart';

class AnalysisResult {
  final List<AssetDetail> assets;
  final Map<String, String> scanErrors;
  final DateTime analyzedAt;
  final String projectRoot;

  AnalysisResult({
    required this.assets,
    required this.scanErrors,
    required this.analyzedAt,
    required this.projectRoot,
  });

  int getTotalSize() => assets.fold(0, (sum, asset) => sum + asset.info.size);

  Map<String, int> getSizeByType() {
    final sizes = <String, int>{};
    for (final asset in assets) {
      final type = asset.info.type;
      sizes[type] = (sizes[type] ?? 0) + asset.info.size;
    }
    return sizes;
  }

  Map<String, int> getCountByType() {
    final counts = <String, int>{};
    for (final asset in assets) {
      final type = asset.info.type;
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  List<AssetDetail> getLargestAssets(int limit) {
    final sorted = List<AssetDetail>.from(assets)
      ..sort((a, b) => b.info.size.compareTo(a.info.size));
    return sorted.take(limit).toList();
  }

  bool hasIssues() => assets.any((asset) => asset.issues.isNotEmpty);

  int getTotalIssues() =>
      assets.fold(0, (sum, asset) => sum + asset.issues.length);

  Map<IssueType, List<AssetDetail>> getIssuesByType() {
    final issues = <IssueType, List<AssetDetail>>{};
    for (final asset in assets) {
      for (final issue in asset.issues) {
        issues.putIfAbsent(issue.type, () => []).add(asset);
      }
    }
    return issues;
  }
}
