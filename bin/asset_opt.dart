import 'dart:io';
import 'package:args/args.dart';
import 'package:asset_opt/asset_opt.dart';
import 'package:asset_opt/view/analysis_progress_listener.dart';
import 'package:asset_opt/view/progress_view.dart';
import 'package:asset_opt/view/terminal_colors.dart';
import 'package:path/path.dart' as p;

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
    ..addOption('preset', help: 'Use optimization preset from config file')
    ..addFlag('init', help: 'Create default asset_opt.yaml config', negatable: false)
    ..addFlag('verbose',
        abbr: 'v', help: 'Show detailed output', defaultsTo: false)
    ..addFlag('no-color', help: 'Disable colored output', negatable: false);

  ArgResults? parsedArgs;

  try {
    parsedArgs = parser.parse(arguments);

    if (parsedArgs['help']) {
      print('Flutter Asset Optimizer\n');
      print('A tool to analyze and optimize Flutter project assets\n');
      print('Usage: asset_opt [options]\n');
      print(parser.usage);
      return;
    }

    if (parsedArgs['no-color']) {
      Color.enabled = false;
    }

    final projectPath = parsedArgs['path'] as String;
    final configService = ConfigService();

    if (parsedArgs['init']) {
      final created = await configService.createDefaultConfig(projectPath);
      if (created) {
        print('Created asset_opt.yaml in $projectPath');
      } else {
        print('asset_opt.yaml already exists. Delete it first to regenerate.');
      }
      return;
    }

    final configResult = await configService.loadConfig(projectPath);
    if (configResult.hasError) {
      print('Warning: ${configResult.error}; using defaults');
    }
    final config = configResult.config;
    if (parsedArgs['verbose'] && config != null) {
      print('Loaded config from asset_opt.yaml');
    }

    await NativeOptimizer.initialize();
    if (parsedArgs['verbose']) {
      print('Native tools: ${NativeOptimizer.availableTools}');
    }

    final fileService = FileService();
    final imageService = ImageService();
    final cacheService = CacheService(
      cachePath: p.join('.dart_tool', 'asset_opt', 'cache.json'),
    );
    final reportService = ReportService();

    final analysisState = AnalysisState();
    final optimizationState = OptimizationState();
    final reportState = ReportState();

    final analysisView = AnalysisView();
    final optimizationView = OptimizationView();

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

    if (parsedArgs['verbose']) {
      optimizationState.addListener(ProgressReporter(optimizationState));
    }

    final progressView = ProgressView();
    analysisState
        .addListener(AnalysisProgressListener(analysisState, progressView));

    final analysis = await analyzeCommand.execute(projectPath);
    stdout.write('\n');
    print(analysisView.formatAnalysisResult(analysis));

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await reportCommand.execute(
      analysis,
      [],
      parsedArgs['report-dir'],
      timestamp,
    );

    if (parsedArgs['optimize']) {
      if (!analysis.hasIssues()) {
        print('\nNo optimization issues found.');
        return;
      }

      final presetName = parsedArgs['preset'] as String?;
      final optimizationConfig = config?.toOptimizationConfig(presetName: presetName) ??
          OptimizationConfig(
            jpegQuality: int.parse(parsedArgs['quality']),
            webpQuality: 80,
            stripMetadata: true,
          );

      print('\nOptimizing assets...\n');
      final optimizationResults = await optimizeCommand.execute(
        analysis,
        optimizationConfig,
      );

      print(optimizationView.formatOptimizationResult(optimizationResults));

      await reportCommand.execute(
        analysis,
        optimizationResults,
        parsedArgs['report-dir'],
        timestamp,
      );
    }
  } catch (e, stackTrace) {
    if (parsedArgs?['verbose'] == true) {
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
    if (state.isOptimizing && stdout.hasTerminal) {
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
