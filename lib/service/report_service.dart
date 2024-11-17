import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path_util;
import 'package:asset_opt/model/analysis_result.dart';
import 'package:asset_opt/model/optimization_result.dart';
import 'package:asset_opt/utils/exceptions.dart';

class ReportService {
  Future<void> saveAnalysisReport(
    AnalysisResult analysis,
    String outputPath,
  ) async {
    try {
      final directory = Directory(path_util.dirname(outputPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = File(outputPath);
      final report = {
        'timestamp': DateTime.now().toIso8601String(),
        'totalAssets': analysis.assets.length,
        'totalSize': analysis.getTotalSize(),
        'sizeByType': analysis.getSizeByType(),
        'assets': analysis.assets
            .map((asset) => {
                  'name': asset.info.name,
                  'path': asset.info.path,
                  'size': asset.info.size,
                  'type': asset.info.type,
                  'lastModified': asset.info.lastModified.toIso8601String(),
                  'imageInfo': asset.imageInfo?.toJson(),
                  'issues': asset.issues
                      .map((issue) => {
                            'type': issue.type.toString(),
                            'message': issue.message,
                            'severity': issue.severity.toString(),
                          })
                      .toList(),
                })
            .toList(),
      };

      await file.writeAsString(
        JsonEncoder.withIndent('  ').convert(report),
      );
    } catch (e) {
      throw AssetOptException('Failed to save analysis report: $e');
    }
  }

  Future<void> saveOptimizationReport(
    List<OptimizationResult> results,
    String outputPath,
  ) async {
    try {
      final directory = Directory(path_util.dirname(outputPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = File(outputPath);
      final totalSaved = results.fold(
        0,
        (sum, result) => sum + result.savedBytes,
      );

      final report = {
        'timestamp': DateTime.now().toIso8601String(),
        'totalOptimized': results.length,
        'totalSaved': totalSaved,
        'savingsPercentage': results.isNotEmpty
            ? (totalSaved /
                    results.fold(0, (sum, r) => sum + r.originalAsset.size) *
                    100)
                .toStringAsFixed(2)
            : '0',
        'results': results
            .map((r) => {
                  'path': r.originalAsset.path,
                  'originalSize': r.originalAsset.size,
                  'optimizedSize': r.optimizedSize,
                  'savedBytes': r.savedBytes,
                  'savingsPercentage': r.savingsPercentage.toStringAsFixed(2),
                  'optimizedAt': r.optimizedAt.toIso8601String(),
                })
            .toList(),
      };

      await file.writeAsString(
        JsonEncoder.withIndent('  ').convert(report),
      );
    } catch (e) {
      throw AssetOptException('Failed to save optimization report: $e');
    }
  }

  Future<void> saveErrorReport(
    Map<String, String> errors,
    String outputPath,
  ) async {
    try {
      final directory = Directory(path_util.dirname(outputPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = File(outputPath);
      final report = {
        'timestamp': DateTime.now().toIso8601String(),
        'totalErrors': errors.length,
        'errors': errors.map((path, error) => MapEntry(path, {
              'path': path,
              'error': error,
            })),
      };

      await file.writeAsString(
        JsonEncoder.withIndent('  ').convert(report),
      );
    } catch (e) {
      throw AssetOptException('Failed to save error report: $e');
    }
  }
}
