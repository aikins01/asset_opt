/// Example usage of asset_opt as a library.
///
/// This example demonstrates how to programmatically analyze
/// Flutter project assets and check for optimization opportunities.
library;

import 'package:asset_opt/asset_opt.dart';

void main() async {
  // Initialize the native optimizer for WebP/PNG compression
  await NativeOptimizer.initialize();

  // Create required services
  final fileService = FileService();
  final imageService = ImageService();
  final analysisState = AnalysisState();

  // Create the analyzer
  final analyzer = AnalyzeCommand(
    fileService,
    imageService,
    analysisState,
  );

  // Run analysis on current directory
  final analysis = await analyzer.execute('./');

  // Print summary
  print('Analyzed ${analysis.assets.length} assets');
  print('Total size: ${_formatBytes(analysis.getTotalSize())}');

  // Check for optimization issues
  if (analysis.hasIssues()) {
    print('\nOptimization opportunities:');
    for (final asset in analysis.assets) {
      for (final issue in asset.issues) {
        print('  ${asset.info.name}: ${issue.message}');
      }
    }
  }

  // Check for unused assets
  if (analysis.hasUnusedAssets()) {
    print('\nPotentially unused assets:');
    for (final asset in analysis.unusedAssets) {
      print('  ${asset.info.name} (${_formatBytes(asset.info.size)})');
    }
  }

  // Check for scan errors (permission issues, corrupted files, etc.)
  if (analysis.scanErrors.isNotEmpty) {
    print('\nScan errors:');
    for (final entry in analysis.scanErrors.entries) {
      print('  ${entry.key}: ${entry.value}');
    }
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}
