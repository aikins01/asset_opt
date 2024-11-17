import 'package:asset_opt/model/optimization_result.dart';

import 'terminal_colors.dart';

class OptimizationView {
  static const _terminalWidth = 80;

  String formatProgress(double progress) {
    final percentage = (progress * 100).toStringAsFixed(1);
    final barWidth = _terminalWidth - 20;
    final completedWidth = (progress * barWidth).round();

    return [
      '[',
      Color.green('=' * completedWidth),
      Color.dim(' ' * (barWidth - completedWidth)),
      '] ',
      Color.yellow('$percentage%'),
    ].join('');
  }

  String formatOptimizationResult(List<OptimizationResult> results) {
    final buffer = StringBuffer();
    final totalSaved = results.fold(0, (sum, r) => sum + r.savedBytes);
    final totalOriginal = results.fold(
      0,
      (sum, r) => sum + r.originalAsset.size,
    );

    // Header
    buffer.writeln(Color.cyan('\n✨ Optimization Results'));
    buffer.writeln(Color.dim('=' * _terminalWidth));

    // Summary
    buffer.writeln(
        '\nOptimized ${Color.yellow(results.length.toString())} files');
    buffer.writeln('Total space saved: ${Color.green(_formatSize(totalSaved))} '
        '${Color.dim('(${(totalSaved / totalOriginal * 100).toStringAsFixed(1)}%)')}');

    // Savings by type
    _writeSavingsByType(buffer, results, totalSaved);

    // Best optimizations
    _writeBestOptimizations(buffer, results);

    // Add recommendations if needed
    _writeRecommendations(buffer, results);

    return buffer.toString();
  }

  void _writeSavingsByType(
    StringBuffer buffer,
    List<OptimizationResult> results,
    int totalSaved,
  ) {
    buffer.writeln(Color.bold('\n📊 Savings by Type'));
    buffer.writeln(Color.dim('─' * _terminalWidth));

    final savingsByType = <String, int>{};
    for (final result in results) {
      final type = result.originalAsset.type;
      savingsByType[type] = (savingsByType[type] ?? 0) + result.savedBytes;
    }

    final sortedTypes = savingsByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedTypes) {
      final percentage = (entry.value / totalSaved * 100).toStringAsFixed(1);
      buffer.writeln('${entry.key.padRight(5)}: '
          '${Color.green(_formatSize(entry.value).padRight(10))} '
          '${Color.yellow('$percentage%'.padLeft(7))}');
    }
  }

  void _writeBestOptimizations(
    StringBuffer buffer,
    List<OptimizationResult> results,
  ) {
    buffer.writeln(Color.bold('\n🏆 Best Optimizations'));
    buffer.writeln(Color.dim('─' * _terminalWidth));

    final sorted = List<OptimizationResult>.from(results)
      ..sort((a, b) => b.savingsPercentage.compareTo(a.savingsPercentage));

    for (final result in sorted.take(5)) {
      buffer.writeln(result.originalAsset.name);
      buffer.writeln(
          '  Before: ${Color.dim(_formatSize(result.originalAsset.size))}\n'
          '  After:  ${Color.green(_formatSize(result.optimizedSize))}\n'
          '  Saved:  ${Color.yellow(_formatSize(result.savedBytes))} '
          '${Color.dim('(${result.savingsPercentage.toStringAsFixed(1)}%)')}\n');
    }
  }

  void _writeRecommendations(
    StringBuffer buffer,
    List<OptimizationResult> results,
  ) {
    final hasLargeFiles = results
        .any((r) => r.optimizedSize > 1024 * 1024 && r.savingsPercentage < 20);

    if (hasLargeFiles) {
      buffer.writeln(Color.bold('\n💡 Recommendations'));
      buffer.writeln(Color.dim('─' * _terminalWidth));
      buffer.writeln(Color.yellow(
          'Some files are still large after optimization. Consider:\n'
          '• Using WebP format for better compression\n'
          '• Reducing image dimensions if possible\n'
          '• Using vector formats (SVG) for icons and logos\n'));
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
