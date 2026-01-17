import 'asset_detail.dart';
import 'asset_issue.dart';

/// Contains the results of an asset analysis operation.
///
/// Provides access to all analyzed assets, detected issues, unused assets,
/// and aggregate statistics like total size and size by type.
class AnalysisResult {
  /// All assets found and analyzed in the project.
  final List<AssetDetail> assets;

  /// Errors encountered during scanning (path -> error message).
  final Map<String, String> scanErrors;

  /// When the analysis was performed.
  final DateTime analyzedAt;

  /// Root path of the analyzed project.
  final String projectRoot;

  /// Assets detected as potentially unused (not referenced in Dart code).
  final List<AssetDetail> unusedAssets;

  /// Creates an analysis result.
  AnalysisResult({
    required this.assets,
    required this.scanErrors,
    required this.analyzedAt,
    required this.projectRoot,
    List<AssetDetail>? unusedAssets,
  }) : unusedAssets = unusedAssets ?? [];

  /// Returns the total size of all assets in bytes.
  int getTotalSize() => assets.fold(0, (sum, asset) => sum + asset.info.size);

  /// Returns a map of asset type to total size in bytes.
  Map<String, int> getSizeByType() {
    final sizes = <String, int>{};
    for (final asset in assets) {
      final type = asset.info.type;
      sizes[type] = (sizes[type] ?? 0) + asset.info.size;
    }
    return sizes;
  }

  /// Returns a map of asset type to file count.
  Map<String, int> getCountByType() {
    final counts = <String, int>{};
    for (final asset in assets) {
      final type = asset.info.type;
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  /// Returns the largest assets, sorted by size descending.
  List<AssetDetail> getLargestAssets(int limit) {
    final sorted = List<AssetDetail>.from(assets)
      ..sort((a, b) => b.info.size.compareTo(a.info.size));
    return sorted.take(limit).toList();
  }

  /// Returns true if any assets have optimization issues.
  bool hasIssues() => assets.any((asset) => asset.issues.isNotEmpty);

  /// Returns the total count of all issues across all assets.
  int getTotalIssues() =>
      assets.fold(0, (sum, asset) => sum + asset.issues.length);

  /// Groups assets by their issue types.
  Map<IssueType, List<AssetDetail>> getIssuesByType() {
    final issues = <IssueType, List<AssetDetail>>{};
    for (final asset in assets) {
      for (final issue in asset.issues) {
        issues.putIfAbsent(issue.type, () => []).add(asset);
      }
    }
    return issues;
  }

  /// Returns total bytes of unused assets.
  int getUnusedTotalBytes() =>
      unusedAssets.fold(0, (sum, asset) => sum + asset.info.size);

  /// Returns true if any unused assets were detected.
  bool hasUnusedAssets() => unusedAssets.isNotEmpty;
}
