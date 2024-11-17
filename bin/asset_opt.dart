import 'dart:io';

import 'package:args/args.dart';
import 'package:asset_opt/asset_opt.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('path',
        abbr: 'p', help: 'Path to Flutter project root', defaultsTo: '.')
    ..addFlag('help', abbr: 'h', help: 'Show help', negatable: false)
    ..addOption('quality',
        abbr: 'q', help: 'JPEG quality (1-100)', defaultsTo: '85')
    ..addFlag('recursive',
        abbr: 'r', help: 'Recursively search subdirectories', defaultsTo: true);

  try {
    final results = parser.parse(arguments);

    if (results['help']) {
      print('Flutter Asset Optimizer\n');
      print('Usage: asset_opt [options]\n');
      print(parser.usage);
      return;
    }

    final optimizer = AssetOptimizer(
      projectPath: results['path'],
      quality: int.parse(results['quality']),
      recursive: results['recursive'],
    );

    final result = await optimizer.optimize();
    print(result.toString());
  } catch (e) {
    print('Error: $e');
    print('\nUse --help to see available options');
    exit(1);
  }
}
