import 'dart:convert';
import 'dart:io';

import 'package:asset_opt/model/analysis_result.dart';
import 'package:asset_opt/model/optimization_result.dart';

class ReportService {
  Future<void> saveAnalysisReport(
    AnalysisResult analysis,
    String outputPath,
  ) async {
    final file = File(outputPath);
    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'totalAssets': analysis.assets.length,
      'totalSize': analysis.totalSize,
      'sizeByType': analysis.sizeByType,
      'assets': analysis.assets.map((a) => a.toJson()).toList(),
    };

    await file.writeAsString(jsonEncode(report));
  }

  Future<void> saveOptimizationReport(
    List<OptimizationResult> results,
    String outputPath,
  ) async {
    final file = File(outputPath);
    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'totalOptimized': results.length,
      'totalSaved': results.fold(
        0,
        (sum, result) => sum + result.savedBytes,
      ),
      'results': results
          .map((r) => {
                'path': r.originalAsset.path,
                'originalSize': r.originalAsset.size,
                'optimizedSize': r.optimizedAsset.size,
                'savedBytes': r.savedBytes,
                'optimizedAt': r.optimizedAt.toIso8601String(),
              })
          .toList(),
    };

    await file.writeAsString(jsonEncode(report));
  }
}
