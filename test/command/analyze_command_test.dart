import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:asset_opt/command/analyze_command.dart';
import 'package:asset_opt/service/file_service.dart';
import 'package:asset_opt/service/image_service.dart';
import 'package:asset_opt/state/analysis_state.dart';
import 'package:asset_opt/model/asset_issue.dart';
import 'package:asset_opt/utils/exceptions.dart';
import 'package:asset_opt/state/base_state.dart';

void main() {
  late Directory tempDir;
  late AnalyzeCommand analyzeCommand;
  late FileService fileService;
  late ImageService imageService;
  late AnalysisState analysisState;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('asset_opt_analyze_test_');
    fileService = FileService();
    imageService = ImageService();
    analysisState = AnalysisState();
    analyzeCommand = AnalyzeCommand(fileService, imageService, analysisState);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> createProject({
    List<String> assetDirs = const ['assets/images/'],
    Map<String, List<int>>? files,
  }) async {
    final pubspec = File(path.join(tempDir.path, 'pubspec.yaml'));
    final assetsYaml = assetDirs.map((d) => '    - $d').join('\n');
    await pubspec.writeAsString('''
name: test_project
version: 1.0.0
flutter:
  assets:
$assetsYaml
''');

    for (final dir in assetDirs) {
      await Directory(path.join(tempDir.path, dir)).create(recursive: true);
    }

    if (files != null) {
      for (final entry in files.entries) {
        final file = File(path.join(tempDir.path, entry.key));
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
    }
  }

  Future<File> createTestImage({
    required String relativePath,
    int width = 100,
    int height = 100,
    bool withAlpha = false,
  }) async {
    final image = img.Image(width: width, height: height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final a = withAlpha ? 128 : 255;
        image.setPixelRgba(x, y, x % 256, y % 256, 100, a);
      }
    }

    final filePath = path.join(tempDir.path, relativePath);
    final file = File(filePath);
    await file.parent.create(recursive: true);

    if (relativePath.endsWith('.png')) {
      await file.writeAsBytes(img.encodePng(image));
    } else {
      await file.writeAsBytes(img.encodeJpg(image, quality: 95));
    }

    return file;
  }

  group('execute', () {
    test('analyzes project and returns results', () async {
      await createProject();
      await createTestImage(relativePath: 'assets/images/logo.png');
      await createTestImage(relativePath: 'assets/images/icon.jpg');

      final result = await analyzeCommand.execute(tempDir.path);

      expect(result.assets, hasLength(2));
      expect(result.projectRoot, equals(tempDir.path));
      expect(result.scanErrors, isEmpty);
    });

    test('throws when no asset directories found', () async {
      final pubspec = File(path.join(tempDir.path, 'pubspec.yaml'));
      await pubspec.writeAsString('''
name: test_project
version: 1.0.0
''');

      expect(
        () => analyzeCommand.execute(tempDir.path),
        throwsA(isA<AssetOptException>().having(
          (e) => e.message,
          'message',
          contains('No asset directories'),
        )),
      );
    });

    test('detects large file issue (>1MB)', () async {
      await createProject();

      final image = img.Image(width: 2000, height: 2000);
      for (var y = 0; y < 2000; y++) {
        for (var x = 0; x < 2000; x++) {
          image.setPixelRgba(x, y, x % 256, y % 256, 128, 255);
        }
      }
      final largeFile = File(path.join(tempDir.path, 'assets/images/large.png'));
      await largeFile.writeAsBytes(img.encodePng(image, level: 0));

      final fileSize = await largeFile.length();
      if (fileSize <= 1024 * 1024) {
        print('Warning: Generated file is not large enough for this test');
        return;
      }

      final result = await analyzeCommand.execute(tempDir.path);

      final largeFileAsset = result.assets.firstWhere(
        (a) => a.info.name == 'large.png',
      );
      expect(
        largeFileAsset.issues.any((i) => i.type == IssueType.largeFile),
        isTrue,
      );
    });

    test('detects large dimensions issue (>2000px)', () async {
      await createProject();
      await createTestImage(
        relativePath: 'assets/images/huge.jpg',
        width: 2500,
        height: 1500,
      );

      final result = await analyzeCommand.execute(tempDir.path);

      final hugeAsset = result.assets.firstWhere(
        (a) => a.info.name == 'huge.jpg',
      );
      expect(
        hugeAsset.issues.any((i) => i.type == IssueType.largeDimensions),
        isTrue,
      );
    });

    test('detects inefficient format (PNG without alpha)', () async {
      await createProject();
      await createTestImage(
        relativePath: 'assets/images/photo.png',
        width: 200,
        height: 200,
        withAlpha: false,
      );

      final result = await analyzeCommand.execute(tempDir.path);

      final pngAsset = result.assets.firstWhere(
        (a) => a.info.name == 'photo.png',
      );
      expect(
        pngAsset.issues.any((i) => i.type == IssueType.inefficientFormat),
        isTrue,
      );
    });

    test('does not flag PNG with alpha as inefficient', () async {
      await createProject();

      final transparentImage = img.Image(width: 200, height: 200, numChannels: 4);
      for (var y = 0; y < 200; y++) {
        for (var x = 0; x < 200; x++) {
          transparentImage.setPixelRgba(x, y, 100, 100, 100, 128);
        }
      }
      final filePath = path.join(tempDir.path, 'assets/images/transparent.png');
      final file = File(filePath);
      await file.writeAsBytes(img.encodePng(transparentImage));

      final result = await analyzeCommand.execute(tempDir.path);

      final pngAsset = result.assets.firstWhere(
        (a) => a.info.name == 'transparent.png',
      );
      expect(
        pngAsset.issues.any((i) => i.type == IssueType.inefficientFormat),
        isFalse,
      );
    });

    test('updates analysis state during execution', () async {
      await createProject();
      await createTestImage(relativePath: 'assets/images/test.png');

      var stateChanges = 0;
      analysisState.addListener(_TestListener(() => stateChanges++));

      await analyzeCommand.execute(tempDir.path);

      expect(stateChanges, greaterThan(0));
      expect(analysisState.isAnalyzing, isFalse);
      expect(analysisState.lastAnalysis, isNotNull);
    });

    test('handles multiple asset directories', () async {
      await createProject(assetDirs: ['assets/images/', 'assets/icons/']);
      await createTestImage(relativePath: 'assets/images/photo.jpg');
      await createTestImage(relativePath: 'assets/icons/icon.png');

      final result = await analyzeCommand.execute(tempDir.path);

      expect(result.assets, hasLength(2));
    });

    test('records scan errors for missing directories', () async {
      final pubspec = File(path.join(tempDir.path, 'pubspec.yaml'));
      await pubspec.writeAsString('''
name: test_project
flutter:
  assets:
    - assets/images/
    - assets/missing/
''');
      await Directory(path.join(tempDir.path, 'assets/images'))
          .create(recursive: true);
      await createTestImage(relativePath: 'assets/images/test.png');

      final result = await analyzeCommand.execute(tempDir.path);

      expect(result.scanErrors, isNotEmpty);
      expect(
        result.scanErrors.keys.any((k) => k.contains('missing')),
        isTrue,
      );
    });
  });
}

class _TestListener implements StateListener {
  final void Function() callback;
  _TestListener(this.callback);

  @override
  void onStateChanged() => callback();
}
