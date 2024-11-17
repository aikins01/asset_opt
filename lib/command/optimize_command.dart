import 'dart:io';

import 'package:asset_opt/model/analysis_result.dart';
import 'package:asset_opt/model/optimization_config.dart';
import 'package:asset_opt/model/optimization_result.dart';
import 'package:asset_opt/service/cache_service.dart';
import 'package:asset_opt/service/file_service.dart';
import 'package:asset_opt/service/image_service.dart';
import 'package:asset_opt/state/optimization_state.dart';

class OptimizeCommand {
  final FileService _fileService;
  final ImageService _imageService;
  final CacheService _cacheService;
  final OptimizationState _state;

  OptimizeCommand(
    this._fileService,
    this._imageService,
    this._cacheService,
    this._state,
  );

  Future<List<OptimizationResult>> execute(
    AnalysisResult analysis,
    OptimizationConfig config,
  ) async {
    try {
      _state.startOptimization();
      final results = <OptimizationResult>[];
      var processed = 0;

      for (final asset in analysis.assets) {
        // Update progress
        _state.updateProgress(processed / analysis.assets.length);

        // Skip if cached and unchanged
        if (!_cacheService.shouldOptimize(
          asset.info.path,
          asset.info.size,
          asset.info.lastModified,
        )) {
          processed++;
          continue;
        }

        try {
          // Backup original file
          final file = File(asset.info.path);
          await _fileService.backupFile(file);

          // Optimize image
          final optimizedFile = await _imageService.optimizeImage(
            file,
            config,
          );

          if (optimizedFile != null) {
            final optimizedSize = await optimizedFile.length();
            final savedBytes = asset.info.size - optimizedSize;

            // Only keep optimization if it actually saved space
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

          // Cleanup backup
          await _fileService.cleanupBackups([asset.info.path]);
        } catch (e) {
          // Restore from backup on error
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
