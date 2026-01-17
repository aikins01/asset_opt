import 'asset_info.dart';
import 'asset_issue.dart';
import 'image_info.dart';

/// Detailed information about an asset including analysis results.
class AssetDetail {
  /// Basic file information.
  final AssetInfo info;

  /// Image metadata (dimensions, format, alpha), if available.
  final ImageInfo? imageInfo;

  /// Optimization issues detected for this asset.
  final List<AssetIssue> issues;

  /// Creates an asset detail instance.
  AssetDetail({
    required this.info,
    this.imageInfo,
    List<AssetIssue>? issues,
  }) : issues = issues ?? [];
}
