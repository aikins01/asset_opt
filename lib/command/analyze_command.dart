import 'dart:io';

import 'package:asset_opt/model/analysis_result.dart';
import 'package:asset_opt/model/asset_detail.dart';
import 'package:asset_opt/model/asset_info.dart';
import 'package:asset_opt/model/asset_issue.dart';
import 'package:asset_opt/model/image_info.dart';
import 'package:asset_opt/service/file_service.dart';
import 'package:asset_opt/service/image_service.dart';
import 'package:asset_opt/state/analysis_state.dart';
import 'package:asset_opt/utils/exceptions.dart';

class AnalyzeCommand {
  final FileService _fileService;
  final ImageService _imageService;
  final AnalysisState _state;

  AnalyzeCommand(this._fileService, this._imageService, this._state);

  Future<AnalysisResult> execute(String projectPath) async {
    try {
      _state.startAnalysis();

      // Find asset directories
      final assetPaths = await _fileService.findAssetPaths(projectPath);
      if (assetPaths.isEmpty) {
        throw AssetOptException('No asset directories found in pubspec.yaml');
      }

      // Scan for assets
      final scanResult = await _fileService.scanAssets(assetPaths);

      // Get detailed image info for each asset
      final assetDetails = await Future.wait(
        scanResult.assets.map((asset) async {
          final file = File(asset.path);
          final imageInfo = await _imageService.getImageInfo(file);

          return AssetDetail(
            info: asset,
            imageInfo: imageInfo,
            issues: _analyzeAssetIssues(asset, imageInfo),
          );
        }),
      );

      final result = AnalysisResult(
        assets: assetDetails,
        scanErrors: scanResult.errors,
        analyzedAt: DateTime.now(),
      );

      _state.completeAnalysis(result);
      return result;
    } catch (e) {
      _state.failAnalysis(e.toString());
      rethrow;
    }
  }

  List<AssetIssue> _analyzeAssetIssues(AssetInfo asset, ImageInfo? imageInfo) {
    final issues = <AssetIssue>[];

    // Check file size (1MB limit)
    if (asset.size > 1024 * 1024) {
      issues.add(AssetIssue(
        type: IssueType.largeFile,
        details: '${_formatSize(asset.size)} exceeds 1MB limit',
      ));
    }

    // Check image dimensions if available
    if (imageInfo != null) {
      if (imageInfo.width > 2000 || imageInfo.height > 2000) {
        issues.add(AssetIssue(
          type: IssueType.largeDimensions,
          details:
              '${imageInfo.width}x${imageInfo.height} exceeds 2000px limit',
        ));
      }

      // Check for inefficient format usage
      if (asset.type == 'png' && !imageInfo.hasAlpha) {
        issues.add(AssetIssue(
          type: IssueType.inefficientFormat,
          details: 'PNG without transparency could be JPEG',
        ));
      }
    }

    return issues;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
