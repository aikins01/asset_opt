import 'dart:io';
import 'package:args/args.dart';
import 'package:asset_opt/asset_opt.dart';
import 'package:asset_opt/view/analysis_progress_listener.dart';
import 'package:asset_opt/view/progress_view.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('path',
        abbr: 'p', help: 'Path to Flutter project root', defaultsTo: '.')
    ..addFlag('help', abbr: 'h', help: 'Show help', negatable: false)
    ..addOption('quality',
        abbr: 'q', help: 'JPEG quality (1-100)', defaultsTo: '85')
    ..addFlag('analyze',
        abbr: 'a',
        help: 'Only analyze assets without optimizing',
        defaultsTo: false)
    ..addFlag('optimize',
        abbr: 'o', help: 'Optimize assets after analysis', defaultsTo: false)
    ..addOption('report-dir',
        help: 'Directory to save reports', defaultsTo: 'asset_opt_reports')
    ..addFlag('verbose',
        abbr: 'v', help: 'Show detailed output', defaultsTo: false);

  late final ArgResults parsedArgs;

  try {
    parsedArgs = parser.parse(arguments);

    if (parsedArgs['help']) {
      print('Flutter Asset Optimizer\n');
      print('A tool to analyze and optimize Flutter project assets\n');
      print('Usage: asset_opt [options]\n');
      print(parser.usage);
      return;
    }

    // Initialize services
    final fileService = FileService();
    final imageService = ImageService();
    final cacheService = CacheService(
      cachePath: '.asset_opt_cache',
    );
    final reportService = ReportService();

    // Initialize states
    final analysisState = AnalysisState();
    final optimizationState = OptimizationState();
    final reportState = ReportState();

    // Initialize views
    final analysisView = AnalysisView();
    final optimizationView = OptimizationView();

    // Create commands
    final analyzeCommand = AnalyzeCommand(
      fileService,
      imageService,
      analysisState,
    );

    final optimizeCommand = OptimizeCommand(
      fileService,
      imageService,
      cacheService,
      optimizationState,
    );

    final reportCommand = ReportCommand(
      reportService,
      reportState,
    );

    // Setup progress reporting
    if (parsedArgs['verbose']) {
      optimizationState.addListener(ProgressReporter(optimizationState));
    }

    final progressView = ProgressView();
    analysisState
        .addListener(AnalysisProgressListener(analysisState, progressView));

    // Run analysis
    final analysis = await analyzeCommand.execute(parsedArgs['path']);
    stdout.write('\n'); // Clear progress line
    print(analysisView.formatAnalysisResult(analysis));

    // Save analysis report
    await reportCommand.execute(
      analysis,
      [], // No optimization results yet
      '${parsedArgs['report-dir']}/analysis_${DateTime.now().millisecondsSinceEpoch}.json',
    );

    // Run optimization if requested
    if (parsedArgs['optimize'] && analysis.hasIssues()) {
      final config = OptimizationConfig(
        jpegQuality: int.parse(parsedArgs['quality']),
        webpQuality: 80,
        stripMetadata: true,
      );

      print('\nOptimizing assets...\n');
      final optimizationResults = await optimizeCommand.execute(
        analysis,
        config,
      );

      print(optimizationView.formatOptimizationResult(optimizationResults));

      // Save optimization report
      await reportCommand.execute(
        analysis,
        optimizationResults,
        '${parsedArgs['report-dir']}/optimization_${DateTime.now().millisecondsSinceEpoch}.json',
      );
    }
  } catch (e, stackTrace) {
    if (parsedArgs['verbose']) {
      print('Error: $e\n$stackTrace');
    } else {
      print('Error: $e');
    }
    exit(1);
  }
}

class ProgressReporter implements StateListener {
  final OptimizationState state;

  ProgressReporter(this.state);

  @override
  void onStateChanged() {
    if (state.isOptimizing) {
      stdout.write('\r${_formatProgress(state.progress)}');
    }
  }

  String _formatProgress(double progress) {
    final percentage = (progress * 100).toStringAsFixed(1);
    final width = 40;
    final completed = (progress * width).round();

    return '[${('=' * completed).padRight(width)}] $percentage%';
  }
}
