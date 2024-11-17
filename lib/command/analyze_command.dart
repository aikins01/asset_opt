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
      _state.setTask('Reading project configuration...');
      final assetPaths = await _fileService.findAssetPaths(projectPath);
      if (assetPaths.isEmpty) {
        throw AssetOptException('No asset directories found in pubspec.yaml');
      }

      // Scan for assets
      _state.setTask('Scanning asset directories...');
      final scanResult = await _fileService.scanAssets(assetPaths);
      final totalFiles = scanResult.assets.length;

      // Get detailed image info for each asset
      _state.setTask('Analyzing assets...');
      final assetDetails = <AssetDetail>[];
      var processed = 0;

      for (final asset in scanResult.assets) {
        final file = File(asset.path);
        final imageInfo = await _imageService.getImageInfo(file);

        assetDetails.add(AssetDetail(
          info: asset,
          imageInfo: imageInfo,
          issues: _analyzeAssetIssues(asset, imageInfo),
        ));

        processed++;
        _state.updateProgress(
          'Analyzing ${path.basename(asset.path)}',
          processed,
          totalFiles,
        );
      }

      _state.setTask('Finalizing analysis...');
      final result = AnalysisResult(
        assets: assetDetails,
        scanErrors: scanResult.errors,
        analyzedAt: DateTime.now(),
        projectRoot: projectPath,
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

    if (asset.size > 1024 * 1024) {
      issues.add(AssetIssue(
        type: IssueType.largeFile,
        values: {
          'maxSize': '1 MB',
          'currentSize': '${(asset.size / 1024 / 1024).toStringAsFixed(1)} MB',
        },
      ));
    }

    if (imageInfo != null &&
        (imageInfo.width > 2000 || imageInfo.height > 2000)) {
      issues.add(AssetIssue(
        type: IssueType.largeDimensions,
        values: {
          'width': imageInfo.width.toString(),
          'height': imageInfo.height.toString(),
          'maxWidth': '2000',
          'maxHeight': '2000',
        },
      ));
    }

    if (asset.type == 'png' && !imageInfo!.hasAlpha) {
      issues.add(AssetIssue(
        type: IssueType.inefficientFormat,
        values: {
          'format': 'PNG',
          'recommendedFormat': 'JPEG/WebP',
          'savingsPercent': '60',
          'reason': 'Image has no transparency, PNG unnecessary',
        },
      ));
    }

    return issues;
  }
}
