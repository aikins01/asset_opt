/// A Flutter/Dart tool for analyzing and optimizing project assets.
///
/// This library provides APIs for:
/// - Scanning and analyzing asset files in Flutter projects
/// - Detecting optimization opportunities (large files, inefficient formats)
/// - Optimizing images (JPEG, PNG, WebP, SVG)
/// - Detecting unused assets
/// - Generating analysis reports
///
/// ## Quick Start
///
/// ```dart
/// import 'package:asset_opt/asset_opt.dart';
///
/// void main() async {
///   await NativeOptimizer.initialize();
///
///   final analyzer = AnalyzeCommand(
///     FileService(),
///     ImageService(),
///     AnalysisState(),
///   );
///
///   final analysis = await analyzer.execute('./');
///   print('Found ${analysis.assets.length} assets');
/// }
/// ```
library;

export 'model/asset_info.dart';
export 'model/asset_detail.dart';
export 'model/image_info.dart';
export 'model/optimization_config.dart';
export 'model/analysis_result.dart';
export 'model/optimization_result.dart';

export 'service/file_service.dart';
export 'service/image_service.dart';
export 'service/report_service.dart';
export 'service/cache_service.dart';
export 'service/native_optimizer.dart';
export 'service/config_service.dart';
export 'service/usage_service.dart';

export 'command/analyze_command.dart';
export 'command/optimize_command.dart';
export 'command/report_command.dart';

export 'state/base_state.dart';
export 'state/analysis_state.dart';
export 'state/optimization_state.dart';
export 'state/report_state.dart';

export 'view/analysis_view.dart';
export 'view/optimization_view.dart';

export 'utils/exceptions.dart';
