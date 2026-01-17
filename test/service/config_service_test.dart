import 'dart:io';
import 'package:test/test.dart';
import 'package:asset_opt/service/config_service.dart';
import 'package:path/path.dart' as p;

void main() {
  group('ConfigService', () {
    late Directory tempDir;
    late ConfigService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('asset_opt_test_');
      service = ConfigService();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('loadConfig returns notFound when no config file exists', () async {
      final result = await service.loadConfig(tempDir.path);
      expect(result.hasConfig, isFalse);
      expect(result.hasError, isFalse);
    });

    test('createDefaultConfig creates config file', () async {
      final created = await service.createDefaultConfig(tempDir.path);
      expect(created, isTrue);
      final configFile = File(p.join(tempDir.path, 'asset_opt.yaml'));
      expect(await configFile.exists(), isTrue);
    });

    test('createDefaultConfig does not overwrite existing file', () async {
      final configFile = File(p.join(tempDir.path, 'asset_opt.yaml'));
      await configFile.writeAsString('existing content');
      final created = await service.createDefaultConfig(tempDir.path);
      expect(created, isFalse);
      expect(await configFile.readAsString(), equals('existing content'));
    });

    test('createDefaultConfig with force overwrites existing file', () async {
      final configFile = File(p.join(tempDir.path, 'asset_opt.yaml'));
      await configFile.writeAsString('existing content');
      final created = await service.createDefaultConfig(tempDir.path, force: true);
      expect(created, isTrue);
      expect(await configFile.readAsString(), isNot(equals('existing content')));
    });

    test('loadConfig parses valid config file', () async {
      final configFile = File(p.join(tempDir.path, 'asset_opt.yaml'));
      await configFile.writeAsString('''
optimization:
  jpeg_quality: 90
  webp_quality: 85
  strip_metadata: false
  convert_png_to_webp: false

limits:
  max_file_size: 2MB
  max_dimensions: 3000

presets:
  thumbnails:
    max_dimensions: 100
    jpeg_quality: 70

exclude:
  - '**/test/*'
''');

      final result = await service.loadConfig(tempDir.path);
      expect(result.hasConfig, isTrue);
      expect(result.hasError, isFalse);
      
      final config = result.config!;
      expect(config.optimization.jpegQuality, equals(90));
      expect(config.optimization.webpQuality, equals(85));
      expect(config.optimization.stripMetadata, isFalse);
      expect(config.optimization.convertPngToWebp, isFalse);
      expect(config.limits.maxFileSize, equals(2 * 1024 * 1024));
      expect(config.limits.maxDimensions, equals(3000));
      expect(config.presets['thumbnails']?.maxDimensions, equals(100));
      expect(config.presets['thumbnails']?.jpegQuality, equals(70));
      expect(config.exclude, contains('**/test/*'));
    });

    test('loadConfig uses defaults for missing values', () async {
      final configFile = File(p.join(tempDir.path, 'asset_opt.yaml'));
      await configFile.writeAsString('''
optimization:
  jpeg_quality: 75
''');

      final result = await service.loadConfig(tempDir.path);
      expect(result.hasConfig, isTrue);
      
      final config = result.config!;
      expect(config.optimization.jpegQuality, equals(75));
      expect(config.optimization.webpQuality, equals(80));
      expect(config.optimization.stripMetadata, isTrue);
      expect(config.limits.maxFileSize, equals(1024 * 1024));
    });

    test('loadConfig returns error for invalid YAML', () async {
      final configFile = File(p.join(tempDir.path, 'asset_opt.yaml'));
      await configFile.writeAsString('invalid: yaml: content: [');
      
      final result = await service.loadConfig(tempDir.path);
      expect(result.hasConfig, isFalse);
      expect(result.hasError, isTrue);
      expect(result.error, contains('Failed to parse'));
    });

    test('toOptimizationConfig converts to OptimizationConfig', () async {
      final configFile = File(p.join(tempDir.path, 'asset_opt.yaml'));
      await configFile.writeAsString('''
optimization:
  jpeg_quality: 90
  webp_quality: 85
  convert_png_to_webp: true
''');

      final result = await service.loadConfig(tempDir.path);
      final optConfig = result.config!.toOptimizationConfig();

      expect(optConfig.jpegQuality, equals(90));
      expect(optConfig.webpQuality, equals(85));
      expect(optConfig.convertToWebp, isTrue);
    });

    test('toOptimizationConfig applies preset values', () async {
      final configFile = File(p.join(tempDir.path, 'asset_opt.yaml'));
      await configFile.writeAsString('''
optimization:
  jpeg_quality: 90
  webp_quality: 85

presets:
  thumbnails:
    max_dimensions: 200
    jpeg_quality: 70
''');

      final result = await service.loadConfig(tempDir.path);
      final optConfig = result.config!.toOptimizationConfig(presetName: 'thumbnails');

      expect(optConfig.jpegQuality, equals(70));
      expect(optConfig.resize?.width, equals(200));
    });
  });

  group('LimitSettings size parsing', () {
    late Directory tempDir;
    late ConfigService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('limit_test_');
      service = ConfigService();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('parseSize handles KB', () async {
      final configFile = File(p.join(tempDir.path, 'asset_opt.yaml'));
      await configFile.writeAsString('limits:\n  max_file_size: 500KB');
      final result = await service.loadConfig(tempDir.path);
      expect(result.config!.limits.maxFileSize, equals(500 * 1024));
    });

    test('parseSize handles MB', () async {
      final configFile = File(p.join(tempDir.path, 'asset_opt.yaml'));
      await configFile.writeAsString('limits:\n  max_file_size: 5MB');
      final result = await service.loadConfig(tempDir.path);
      expect(result.config!.limits.maxFileSize, equals(5 * 1024 * 1024));
    });

    test('parseSize handles int', () async {
      final configFile = File(p.join(tempDir.path, 'asset_opt.yaml'));
      await configFile.writeAsString('limits:\n  max_file_size: 1000');
      final result = await service.loadConfig(tempDir.path);
      expect(result.config!.limits.maxFileSize, equals(1000));
    });
  });
}
