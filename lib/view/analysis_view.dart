import 'package:asset_opt/model/analysis_result.dart';
import 'package:asset_opt/model/asset_issue.dart';
import 'package:asset_opt/view/terminal_colors.dart';

class AnalysisView {
  static const _terminalWidth = 80;
  static const _barWidth = 40;

  String formatAnalysisResult(AnalysisResult result) {
    final buffer = StringBuffer();

    // Header
    _writeHeader(buffer);

    // Overview
    _writeOverview(buffer, result);

    // Type breakdown with visual chart
    _writeTypeBreakdown(buffer, result);

    // Directory breakdown
    _writeDirectoryBreakdown(buffer, result);

    // Largest assets
    _writeLargestAssets(buffer, result);

    // Issues and suggestions
    if (result.hasIssues()) {
      _writeIssues(buffer, result);
    }

    return buffer.toString();
  }

  void _writeHeader(StringBuffer buffer) {
    buffer.writeln(Color.cyan('\n📊 Asset Analysis Report'));
    buffer.writeln(Color.dim('=' * _terminalWidth));
  }

  void _writeOverview(StringBuffer buffer, AnalysisResult result) {
    buffer.writeln(Color.bold('\n📈 Overview'));
    buffer.writeln(Color.dim('─' * _terminalWidth));

    final totalSize = result.getTotalSize();
    buffer.writeln(
        'Total assets: ${Color.yellow(result.assets.length.toString())}');
    buffer.writeln('Total size: ${Color.yellow(_formatSize(totalSize))}');

    // Add breakdown percentages
    final sizeByType = result.getSizeByType();
    buffer.writeln('\nBreakdown:');
    for (final entry in sizeByType.entries) {
      final percentage = (entry.value / totalSize * 100).toStringAsFixed(1);
      buffer.writeln('  ${entry.key.padRight(4)}: $percentage%');
    }
  }

  void _writeTypeBreakdown(StringBuffer buffer, AnalysisResult result) {
    buffer.writeln(Color.bold('\n🗂  Assets by Type'));
    buffer.writeln(Color.dim('─' * _terminalWidth));

    final typeStats = result.getSizeByType().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxSize =
        typeStats.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final totalSize = result.getTotalSize();

    for (final entry in typeStats) {
      final percentage = (entry.value / totalSize * 100).toStringAsFixed(1);
      final count = result.getCountByType()[entry.key] ?? 0;
      final barLength = (entry.value / maxSize * _barWidth).round();

      buffer.writeln('${_formatFileType(entry.key).padRight(5)} │ '
          '${_createGradientBar(barLength)} '
          '${Color.dim(_formatSize(entry.value).padRight(10))} '
          '${Color.yellow('$percentage%'.padLeft(7))} '
          '${Color.dim('($count files)')}');
    }
  }

  void _writeDirectoryBreakdown(StringBuffer buffer, AnalysisResult result) {
    final dirStats = _getDirectoryStats(result);
    if (dirStats.isEmpty) return;

    buffer.writeln(Color.bold('\n📁 Directory Structure'));
    buffer.writeln(Color.dim('─' * _terminalWidth));

    for (final entry in dirStats.entries) {
      final size = entry.value.totalSize;
      final count = entry.value.fileCount;
      final depth = entry.key.split('/').length - 1;
      final indent = '  ' * depth;

      buffer.writeln('$indent${Color.blue('├─')} ${entry.key.split('/').last}'
          ' ${Color.dim('($count files, ${_formatSize(size)})')}');
    }
  }

  void _writeLargestAssets(StringBuffer buffer, AnalysisResult result) {
    buffer.writeln(Color.bold('\n📦 Largest Assets'));
    buffer.writeln(Color.dim('─' * _terminalWidth));

    final totalSize = result.getTotalSize();
    final largestAssets = result.getLargestAssets(10);

    for (final asset in largestAssets) {
      final percentage = (asset.info.size / totalSize * 100).toStringAsFixed(1);
      final sizeStr = _formatSize(asset.info.size);

      // Add dimension info if available
      final dimensions = asset.imageInfo != null
          ? Color.dim(' (${asset.imageInfo!.width}x${asset.imageInfo!.height})')
          : '';

      buffer.writeln('${sizeStr.padRight(10)} '
          '${Color.yellow('$percentage%'.padLeft(7))} │ '
          '${asset.info.name}$dimensions');
    }
  }

  void _writeIssues(StringBuffer buffer, AnalysisResult result) {
    buffer.writeln(Color.bold('\n⚠️  Optimization Opportunities'));
    buffer.writeln(Color.dim('─' * _terminalWidth));

    final issuesByType = result.getIssuesByType();

    for (final entry in issuesByType.entries) {
      final severity = entry.key.severity;
      final icon = _getSeverityIcon(severity);
      final colorize = _getSeverityColor(severity);

      buffer.writeln(colorize('$icon ${entry.key.message}:'));

      for (final asset in entry.value) {
        final size = _formatSize(asset.info.size);
        buffer.writeln(colorize('  • ${asset.info.name} '
            '${Color.dim('($size)')}'));
      }
      buffer.writeln('');
    }
  }

  String _createGradientBar(int length) {
    if (length == 0) return ' ' * _barWidth;

    final fullBlocks = '█' * length;
    final emptyBlocks = ' ' * (_barWidth - length);
    return Color.gradient(fullBlocks) + Color.dim(emptyBlocks);
  }

  String _formatFileType(String type) {
    switch (type.toLowerCase()) {
      case 'png':
        return Color.green('PNG');
      case 'jpg':
      case 'jpeg':
        return Color.yellow('JPG');
      case 'webp':
        return Color.blue('WEBP');
      case 'svg':
        return Color.magenta('SVG');
      default:
        return Color.white(type.toUpperCase());
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }

  String _getSeverityIcon(IssueSeverity severity) {
    switch (severity) {
      case IssueSeverity.error:
        return '❌';
      case IssueSeverity.warning:
        return '⚠️';
      case IssueSeverity.suggestion:
        return '💡';
    }
  }

  Function _getSeverityColor(IssueSeverity severity) {
    switch (severity) {
      case IssueSeverity.error:
        return Color.red;
      case IssueSeverity.warning:
        return Color.yellow;
      case IssueSeverity.suggestion:
        return Color.cyan;
    }
  }

  Map<String, DirStats> _getDirectoryStats(AnalysisResult result) {
    final stats = <String, DirStats>{};

    for (final asset in result.assets) {
      var dir = asset.info.directory;
      while (dir.isNotEmpty && dir != '.') {
        stats.putIfAbsent(dir, () => DirStats()).addAsset(asset);
        dir = dir.substring(0, dir.lastIndexOf('/'));
      }
    }

    return stats;
  }
}
