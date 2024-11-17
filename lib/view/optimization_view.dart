import 'package:asset_opt/model/optimization_result.dart';

class OptimizationView {
  String formatOptimizationResult(List<OptimizationResult> results) {
    final buffer = StringBuffer();
    final totalSaved = results.fold(
      0,
      (sum, result) => sum + result.savedBytes,
    );

    // Summary
    buffer.writeln('\nOptimization Results');
    buffer.writeln('===================');
    buffer.writeln('Files optimized: ${results.length}');
    buffer.writeln('Total space saved: ${_formatSize(totalSaved)}');

    // Individual results
    buffer.writeln('\nOptimized files:');
    for (final result in results) {
      final savings = (result.savedBytes / result.originalAsset.size * 100)
          .toStringAsFixed(1);

      buffer.writeln(result.originalAsset.name);
      buffer.writeln('  Original: ${_formatSize(result.originalAsset.size)}\n'
          '  Optimized: ${_formatSize(result.optimizedSize)}\n'
          '  Saved: ${_formatSize(result.savedBytes)} ($savings%)');
    }

    return buffer.toString();
  }

  String formatProgress(double progress) {
    final percentage = (progress * 100).toStringAsFixed(1);
    return 'Progress: $percentage%';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
