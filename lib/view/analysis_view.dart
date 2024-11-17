import 'package:asset_opt/model/analysis_result.dart';
import 'package:asset_opt/model/asset_detail.dart';

class AnalysisView {
  String formatAnalysisResult(AnalysisResult result) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('\nAsset Analysis Report');
    buffer.writeln('===================');

    // Overview
    buffer.writeln('\nOverview:');
    buffer.writeln('Total assets: ${result.assets.length}');
    buffer.writeln('Total size: ${_formatSize(result.getTotalSize())}');

    // Type breakdown
    buffer.writeln('\nAssets by Type:');
    final typeStats = result.getSizeByType();
    for (final entry in typeStats.entries) {
      final count = result.getCountByType()[entry.key] ?? 0;
      buffer
          .writeln('${entry.key}: ${_formatSize(entry.value)} ($count files)');
    }

    // Largest files
    buffer.writeln('\nLargest Assets:');
    for (final asset in result.getLargestAssets(10)) {
      buffer.writeln('${asset.info.name}: ${_formatSize(asset.info.size)}'
          '${_formatDimensions(asset)}');
    }

    // Issues
    if (result.hasIssues()) {
      buffer.writeln('\nOptimization Opportunities:');
      for (final asset in result.assets) {
        if (asset.issues.isNotEmpty) {
          buffer.writeln('${asset.info.name}:');
          for (final issue in asset.issues) {
            buffer.writeln('  - ${issue.message}');
          }
        }
      }
    }

    return buffer.toString();
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  String _formatDimensions(AssetDetail asset) {
    if (asset.imageInfo != null) {
      return ' (${asset.imageInfo!.width}x${asset.imageInfo!.height})';
    }
    return '';
  }
}
