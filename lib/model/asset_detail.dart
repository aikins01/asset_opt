import 'asset_info.dart';
import 'asset_issue.dart';
import 'image_info.dart';

class AssetDetail {
  final AssetInfo info;
  final ImageInfo? imageInfo;
  final List<AssetIssue> issues;

  AssetDetail({
    required this.info,
    this.imageInfo,
    List<AssetIssue>? issues,
  }) : issues = issues ?? [];
}
