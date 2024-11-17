import 'package:asset_opt/asset_opt.dart';

void main() async {
  // Initialize services
  final fileService = FileService();
  final imageService = ImageService();
  final analysisState = AnalysisState();

  // Create analyzer
  final analyzer = AnalyzeCommand(
    fileService,
    imageService,
    analysisState,
  );

  // Run analysis
  final analysis = await analyzer.execute('./');

  // Check for issues
  if (analysis.hasIssues()) {
    print('Found optimization opportunities:');
    for (final asset in analysis.assets) {
      if (asset.issues.isNotEmpty) {
        print('${asset.info.name}:');
        for (final issue in asset.issues) {
          print('  - ${issue.message}');
        }
      }
    }
  }
}
