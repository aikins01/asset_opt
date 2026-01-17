import 'dart:io';

import 'package:asset_opt/model/analysis_result.dart';
import 'package:asset_opt/model/optimization_config.dart';
import 'package:asset_opt/model/optimization_result.dart';
import 'package:asset_opt/service/cache_service.dart';
import 'package:asset_opt/service/file_service.dart';
import 'package:asset_opt/service/image_service.dart';
import 'package:asset_opt/state/optimization_state.dart';
import 'package:asset_opt/utils/exceptions.dart';

/// Optimizes project assets based on analysis results.
class OptimizeCommand {
  final FileService _fileService;
  final ImageService _imageService;
  final CacheService _cacheService;
  final OptimizationState _state;

  /// Creates an optimize command with required services.
  OptimizeCommand(
    this._fileService,
    this._imageService,
    this._cacheService,
    this._state,
  );

  /// Optimizes assets identified in the analysis.
  ///
  /// Creates backups before modifying files and restores on failure.
  Future<List<OptimizationResult>> execute(
    AnalysisResult analysis,
    OptimizationConfig config,
  ) async {
    try {
      _state.startOptimization();
      final results = <OptimizationResult>[];
      final total = analysis.assets.length;

      if (total == 0) {
        _state.updateProgress(1.0);
        _state.completeOptimization();
        return results;
      }

      var processed = 0;

      for (final asset in analysis.assets) {
        _state.updateProgress(processed / total);

        if (!_cacheService.shouldOptimize(
          asset.info.path,
          asset.info.size,
          asset.info.lastModified,
        )) {
          processed++;
          continue;
        }

        try {
          final file = File(asset.info.path);
          await _fileService.backupFile(file);

          final optimizedFile = await _imageService.optimizeImage(
            file,
            config,
            hasAlpha: asset.imageInfo?.hasAlpha,
          );

          if (optimizedFile != null) {
            final optimizedSize = await optimizedFile.length();
            final savedBytes = asset.info.size - optimizedSize;

            if (savedBytes > 0) {
              await optimizedFile.copy(asset.info.path);

              final result = OptimizationResult(
                originalAsset: asset.info,
                optimizedSize: optimizedSize,
                savedBytes: savedBytes,
                optimizedAt: DateTime.now(),
              );

              results.add(result);
              _cacheService.updateEntry(
                asset.info.path,
                optimizedSize,
                DateTime.now(),
              );

              _state.addResult(result);
            }

            await optimizedFile.delete();
          }

          await _fileService.cleanupBackups([asset.info.path]);
        } on OptimizationSkippedException catch (e) {
          await _fileService.cleanupBackups([asset.info.path]);
          _state.addError(asset.info.path, e.message);
        } catch (e) {
          await _fileService.restoreBackup(asset.info.path);
          _state.addError(asset.info.path, e.toString());
        }

        processed++;
      }

      await _cacheService.save();
      _state.completeOptimization();

      return results;
    } catch (e) {
      _state.failOptimization(e.toString());
      rethrow;
    }
  }
}
