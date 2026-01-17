import 'dart:async';
import 'dart:io';

import 'package:asset_opt/model/analysis_result.dart';
import 'package:asset_opt/model/asset_detail.dart';
import 'package:asset_opt/model/asset_info.dart';
import 'package:asset_opt/model/asset_issue.dart';
import 'package:asset_opt/model/image_info.dart';
import 'package:asset_opt/service/file_service.dart';
import 'package:asset_opt/service/image_service.dart';
import 'package:asset_opt/service/usage_service.dart';
import 'package:asset_opt/state/analysis_state.dart';
import 'package:asset_opt/utils/exceptions.dart';
import 'package:path/path.dart' as path_util;

class _AnalysisAccumulator {
  final List<AssetDetail> assets = [];
  final Map<String, String> errors = {};
}

/// Analyzes Flutter project assets for optimization opportunities.
///
/// Scans asset directories defined in pubspec.yaml, analyzes each file
/// for size, dimensions, format efficiency, and detects unused assets.
///
/// ```dart
/// final command = AnalyzeCommand(fileService, imageService, state);
/// final result = await command.execute('./my_flutter_project');
/// ```
class AnalyzeCommand {
  static const _concurrencyLimit = 8;
  
  final FileService _fileService;
  final ImageService _imageService;
  final AnalysisState _state;
  final UsageService _usageService;

  /// Creates an analyze command with required services.
  AnalyzeCommand(
    this._fileService,
    this._imageService,
    this._state, [
    UsageService? usageService,
  ]) : _usageService = usageService ?? UsageService();

  /// Executes asset analysis on the given [projectPath].
  ///
  /// Returns an [AnalysisResult] containing all analyzed assets,
  /// detected issues, unused assets, and any scan errors.
  ///
  /// Throws [AssetOptException] if no asset directories are found.
  Future<AnalysisResult> execute(String projectPath) async {
    try {
      _state.startAnalysis();

      _state.setTask('Reading project configuration...');
      final assetPaths = await _fileService.findAssetPaths(projectPath);
      if (assetPaths.isEmpty) {
        throw AssetOptException('No asset directories found in pubspec.yaml');
      }

      _state.setTask('Scanning asset directories...');
      final scanResult = await _fileService.scanAssets(assetPaths);
      final totalFiles = scanResult.assets.length;

      _state.setTask('Analyzing assets...');
      final accumulator = await _analyzeAssetsInBatches(
        scanResult.assets,
        totalFiles,
      );

      final allErrors = {...scanResult.errors, ...accumulator.errors};

      _state.setTask('Analyzing asset usage...');
      final usedAssetPaths = await _usageService.findUsedAssetPaths(projectPath);
      final allAssetPaths = accumulator.assets.map((a) => a.info.path).toList();
      final unusedPaths = _usageService.findUnusedAssets(
        allAssetPaths,
        usedAssetPaths,
        projectPath,
      );

      final unusedAssets = accumulator.assets
          .where((a) => unusedPaths.contains(a.info.path))
          .toList();

      _state.setTask('Finalizing analysis...');
      final result = AnalysisResult(
        assets: accumulator.assets,
        scanErrors: allErrors,
        analyzedAt: DateTime.now(),
        projectRoot: projectPath,
        unusedAssets: unusedAssets,
      );

      _state.completeAnalysis(result);
      return result;
    } catch (e) {
      _state.failAnalysis(e.toString());
      rethrow;
    }
  }

  Future<_AnalysisAccumulator> _analyzeAssetsInBatches(
    List<AssetInfo> assets,
    int totalFiles,
  ) async {
    final accumulator = _AnalysisAccumulator();
    var processed = 0;

    for (var i = 0; i < assets.length; i += _concurrencyLimit) {
      final end = (i + _concurrencyLimit < assets.length) ? i + _concurrencyLimit : assets.length;
      final batch = assets.sublist(i, end);
      
      final batchResults = await Future.wait(
        batch.map((asset) => _analyzeAsset(asset)),
      );
      
      for (final result in batchResults) {
        accumulator.assets.add(result.detail);
        if (result.error != null) {
          accumulator.errors[result.detail.info.path] = result.error!;
        }
      }
      
      processed += batch.length;
      
      if (batch.isNotEmpty) {
        _state.updateProgress(
          'Analyzing ${path_util.basename(batch.last.path)}',
          processed,
          totalFiles,
        );
      }
    }

    return accumulator;
  }

  Future<({AssetDetail detail, String? error})> _analyzeAsset(AssetInfo asset) async {
    final file = File(asset.path);
    final result = await _imageService.getImageInfo(file);

    final detail = AssetDetail(
      info: asset,
      imageInfo: result.info,
      issues: _analyzeAssetIssues(asset, result.info),
    );

    return (detail: detail, error: result.error);
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

    if (asset.type == 'png' && imageInfo != null && !imageInfo.hasAlpha) {
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
