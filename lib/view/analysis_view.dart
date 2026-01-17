import 'package:asset_opt/model/analysis_result.dart';
import 'package:asset_opt/model/asset_detail.dart';
import 'package:asset_opt/model/asset_issue.dart';
import 'package:asset_opt/view/terminal_colors.dart';
import 'package:path/path.dart' as p;

class AnalysisView {
  static const _terminalWidth = 80;

  String formatAnalysisResult(AnalysisResult result) {
    final buffer = StringBuffer();

    _writeHeader(buffer);
    _writeOverview(buffer, result);
    _writeTypeBreakdown(buffer, result);
    _writeDirectoryBreakdown(buffer, result);
    _writeLargestAssets(buffer, result);

    if (result.hasUnusedAssets()) {
      _writeUnusedAssets(buffer, result);
    }

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

    if (typeStats.isEmpty) {
      buffer.writeln(Color.dim('No assets found.'));
      return;
    }

    final totalSize = result.getTotalSize();
    if (totalSize == 0) {
      buffer.writeln(Color.dim('Total asset size is 0 bytes.'));
      return;
    }

    final maxSize =
        typeStats.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    buffer.writeln('${'Type'.padRight(8)} '
        '${'Size'.padRight(10)} '
        '${'Files'.padRight(7)} '
        'Distribution');
    buffer.writeln(Color.dim('─' * _terminalWidth));

    for (final entry in typeStats) {
      final percentage = (entry.value / totalSize * 100).toStringAsFixed(1);
      final count = result.getCountByType()[entry.key] ?? 0;
      final barLength = (entry.value / maxSize * 30).round();

      final typeColor = _getTypeColor(entry.key);
      final barColor = _getBarColor(entry.key);
      final typeStr = typeColor(entry.key.toUpperCase().padRight(8));
      final sizeColor = _getSizeColor(entry.value / totalSize * 100);
      final sizeStr = sizeColor(_formatSize(entry.value).padRight(10));
      final countStr = Color.dim(count.toString().padRight(7));
      final bar =
          '│${barColor('█' * barLength)}${Color.dim(' ' * (30 - barLength))}│';

      buffer.writeln('$typeStr '
          '$sizeStr '
          '$countStr '
          '$bar ${Color.yellow('${percentage.padLeft(5)}%')}');
    }
  }

  void _writeDirectoryBreakdown(StringBuffer buffer, AnalysisResult result) {
    final dirStats = _getDirectoryStats(result);
    if (dirStats.isEmpty) return;

    buffer.writeln(Color.bold('\n📁 Directory Structure'));
    buffer.writeln(Color.dim('─' * _terminalWidth));
    buffer.writeln(Color.dim('Project: ') + Color.blue(result.projectRoot));
    buffer.writeln(Color.dim('─' * _terminalWidth));

    final sortedDirs = dirStats.entries.toList()
      ..sort((a, b) => b.value.totalSize.compareTo(a.value.totalSize));

    final Map<String, List<MapEntry<String, DirStats>>> dirsByParent = {};
    for (final entry in sortedDirs) {
      final parentPath = p.dirname(entry.key);
      final normalizedParent =
          (parentPath == entry.key || parentPath == '.') ? '' : parentPath;
      dirsByParent.putIfAbsent(normalizedParent, () => []).add(entry);
    }

    _printDirectoryTree(buffer, dirsByParent, '', 0);
  }

  void _printDirectoryTree(
    StringBuffer buffer,
    Map<String, List<MapEntry<String, DirStats>>> dirsByParent,
    String currentPath,
    int level,
  ) {
    final dirs = dirsByParent[currentPath] ?? [];
    for (var i = 0; i < dirs.length; i++) {
      final entry = dirs[i];
      final isLast = i == dirs.length - 1;
      final prefix = '  ' * level + (isLast ? '└─' : '├─');
      final name = p.basename(entry.key);
      final stats = entry.value;

      buffer.writeln('$prefix ${Color.blue(name)} '
          '${Color.dim('(${stats.fileCount} files, ${_formatSize(stats.totalSize)})')}');

      _printDirectoryTree(
        buffer,
        dirsByParent,
        entry.key,
        level + 1,
      );
    }
  }

  void _writeLargestAssets(StringBuffer buffer, AnalysisResult result) {
    buffer.writeln(Color.bold('\n📦 Largest Assets'));
    buffer.writeln(Color.dim('─' * _terminalWidth));

    final largestAssets = result.getLargestAssets(10);
    if (largestAssets.isEmpty) {
      buffer.writeln(Color.dim('No assets found.'));
      return;
    }

    final totalSize = result.getTotalSize();

    for (final asset in largestAssets) {
      final percentage = totalSize > 0
          ? (asset.info.size / totalSize * 100).toStringAsFixed(1)
          : '0.0';
      final sizeStr = _formatSize(asset.info.size);

      final dimensions = asset.imageInfo != null
          ? Color.dim(' (${asset.imageInfo!.width}x${asset.imageInfo!.height})')
          : '';

      buffer.writeln('${sizeStr.padRight(10)} '
          '${Color.yellow('$percentage%'.padLeft(7))} │ '
          '${asset.info.name}$dimensions');
    }
  }

  void _writeUnusedAssets(StringBuffer buffer, AnalysisResult result) {
    buffer.writeln(Color.bold('\n🗑️  Unused Assets'));
    buffer.writeln(Color.dim('─' * _terminalWidth));

    final unusedCount = result.unusedAssets.length;
    final unusedSize = result.getUnusedTotalBytes();
    final totalSize = result.getTotalSize();
    final percentage = totalSize > 0
        ? (unusedSize / totalSize * 100).toStringAsFixed(1)
        : '0.0';

    buffer.writeln(
        'Found ${Color.yellow(unusedCount.toString())} potentially unused assets');
    buffer.writeln(
        'Total size: ${Color.yellow(_formatSize(unusedSize))} ($percentage% of all assets)');
    buffer.writeln('');

    final sortedUnused = List.from(result.unusedAssets)
      ..sort((a, b) => b.info.size.compareTo(a.info.size));

    final displayCount = sortedUnused.length > 15 ? 15 : sortedUnused.length;
    for (var i = 0; i < displayCount; i++) {
      final asset = sortedUnused[i];
      final sizeStr = _formatSize(asset.info.size);
      final relativePath = _getRelativePath(asset.info.path, result.projectRoot);
      buffer.writeln('${Color.dim(sizeStr.padRight(10))} ${Color.red(relativePath)}');
    }

    if (sortedUnused.length > 15) {
      buffer.writeln(
          Color.dim('  ... and ${sortedUnused.length - 15} more unused assets'));
    }

    buffer.writeln('');
    buffer.writeln(Color.dim(
        'Note: Review these files before deletion. Some may be referenced dynamically.'));
  }

  String _getRelativePath(String absolutePath, String projectRoot) {
    return p.relative(absolutePath, from: projectRoot);
  }

  void _writeIssues(StringBuffer buffer, AnalysisResult result) {
    buffer.writeln(Color.bold('\n⚠️  Optimization Opportunities'));
    buffer.writeln(Color.dim('─' * _terminalWidth));

    for (final asset in result.assets) {
      if (asset.issues.isEmpty) continue;

      for (final issue in asset.issues) {
        final icon = _getSeverityIcon(issue.severity);
        final colorize = _getSeverityColor(issue.severity);

        buffer.writeln(colorize('$icon ${asset.info.name}'));
        buffer.writeln(colorize('   Current: ${_formatSize(asset.info.size)}'));

        final recommendation = _getRecommendation(asset, issue);
        buffer.writeln(colorize('   $recommendation'));
        buffer.writeln('');
      }
    }
  }

  String _getRecommendation(AssetDetail asset, AssetIssue issue) {
    switch (issue.type) {
      case IssueType.largeFile:
        return _getFileSizeRecommendation(asset);
      case IssueType.largeDimensions:
        return _getDimensionsRecommendation(asset);
      case IssueType.inefficientFormat:
        return _getFormatRecommendation(asset);
      case IssueType.duplicateContent:
        return _getDuplicateRecommendation(asset);
      case IssueType.highResolution:
        return _getResolutionRecommendation(asset);
      case IssueType.metadataPresent:
        return _getMetadataRecommendation(asset);
      case IssueType.uncompressedFormat:
        return _getCompressionRecommendation(asset);
      default:
        return issue.message;
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
    final root = p.normalize(p.absolute(result.projectRoot));

    for (final asset in result.assets) {
      final assetDirAbs = p.normalize(p.absolute(asset.info.directory));
      var dir = p.relative(assetDirAbs, from: root);

      if (dir == '.' || dir.startsWith('..')) continue;

      while (dir.isNotEmpty && dir != '.') {
        stats.putIfAbsent(dir, () => DirStats()).addAsset(asset);
        final parent = p.dirname(dir);
        if (parent == dir || parent == '.') break;
        dir = parent;
      }
    }

    return stats;
  }
}

String _getFileSizeRecommendation(AssetDetail asset) {
  final currentSize = asset.info.size / (1024 * 1024); // Convert to MB
  final targetSize =
      asset.info.type == 'png' ? 0.5 : 0.2; // 500KB for PNG, 200KB for others
  final reduction =
      ((currentSize - targetSize) / currentSize * 100).toStringAsFixed(0);

  return '''
   Recommended: < ${targetSize * 1000} KB (reduce by $reduction%)
   → ${_getSizeOptimizationSteps(asset)}''';
}

String _getDimensionsRecommendation(AssetDetail asset) {
  if (asset.imageInfo == null) return '';

  final maxDimension = _getRecommendedDimension(asset);
  return '''
   Current: ${asset.imageInfo!.width}x${asset.imageInfo!.height}
   Recommended: ${maxDimension}x$maxDimension
   → Resize image based on actual usage
   → Consider creating different sizes for different devices''';
}

String _getFormatRecommendation(AssetDetail asset) {
  final currentFormat = asset.info.type.toUpperCase();
  final recommendedFormat = _getRecommendedFormat(asset);
  final savings = _getEstimatedSavings(asset);

  return '''
   Current format: $currentFormat
   Recommended: $recommendedFormat
   → Estimated savings: $savings%
   → ${_getFormatConversionSteps(asset)}''';
}

String _getDuplicateRecommendation(AssetDetail asset) {
  return '''
   Consider consolidating duplicate assets
   → Check for similar files in the project
   → Use a single shared asset where possible''';
}

String _getResolutionRecommendation(AssetDetail asset) {
  return '''
   High resolution may not be needed
   → Consider target device requirements
   → Optimize for actual display size''';
}

String _getMetadataRecommendation(AssetDetail asset) {
  return '''
   Contains unnecessary metadata
   → Use tools like ExifTool to strip metadata
   → Keep only essential information''';
}

String _getCompressionRecommendation(AssetDetail asset) {
  return '''
   File is not optimally compressed
   → Use appropriate compression tools
   → Consider converting to more efficient format''';
}

String _getSizeOptimizationSteps(AssetDetail asset) {
  if (asset.info.type == 'png') {
    return 'Use pngquant or tinypng for lossless compression';
  } else if (asset.info.type == 'jpg' || asset.info.type == 'jpeg') {
    return 'Use mozjpeg with quality 80-85';
  }
  return 'Convert to WebP for better compression';
}

int _getRecommendedDimension(AssetDetail asset) {
  final path = asset.info.path.toLowerCase();
  if (path.contains('background') || path.contains('hero')) {
    return 1920;
  } else if (path.contains('thumbnail') || path.contains('avatar')) {
    return 200;
  }
  return 1024;
}

String _getRecommendedFormat(AssetDetail asset) {
  if (asset.imageInfo?.hasAlpha == true) {
    return 'WebP (supports transparency)';
  }
  if (asset.info.size < 50 * 1024) {
    // Less than 50KB
    return 'Keep current format';
  }
  return 'JPEG (85% quality)';
}

int _getEstimatedSavings(AssetDetail asset) {
  if (asset.info.type == 'png' && asset.imageInfo?.hasAlpha == false) {
    return 60;
  } else if (asset.info.type == 'jpg' || asset.info.type == 'jpeg') {
    return 30;
  }
  return 40;
}

String _getFormatConversionSteps(AssetDetail asset) {
  final ext = p.extension(asset.info.name);
  final webpName = asset.info.name.replaceAll(ext, '.webp');
  return 'Convert to WebP: cwebp -q 85 ${asset.info.name} -o $webpName';
}

Function _getTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'png':
      return Color.brightBlue; // PNG - Often used for transparency
    case 'jpg':
    case 'jpeg':
      return Color.brightGreen; // JPEG - Standard photos
    case 'webp':
      return Color.brightCyan; // WebP - Modern format
    case 'svg':
      return Color.brightMagenta; // SVG - Vector graphics
    case 'gif':
      return Color.brightYellow; // GIF - Animations
    default:
      return Color.white;
  }
}

Function _getBarColor(String type) {
  switch (type.toLowerCase()) {
    case 'png':
      return Color.blue;
    case 'jpg':
    case 'jpeg':
      return Color.green;
    case 'webp':
      return Color.cyan;
    case 'svg':
      return Color.magenta;
    case 'gif':
      return Color.yellow;
    default:
      return Color.dim;
  }
}

Function _getSizeColor(double percentage) {
  if (percentage > 50) {
    return Color.brightRed; // Very large portion
  } else if (percentage > 25) {
    return Color.brightYellow; // Significant portion
  } else if (percentage > 10) {
    return Color.brightGreen; // Moderate portion
  } else {
    return Color.dim; // Small portion
  }
}
