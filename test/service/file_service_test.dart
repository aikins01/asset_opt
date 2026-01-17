import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:asset_opt/service/file_service.dart';
import 'package:asset_opt/utils/exceptions.dart';

void main() {
  late Directory tempDir;
  late FileService fileService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('asset_opt_test_');
    fileService = FileService();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('readPubspec', () {
    test('returns YamlMap for valid pubspec', () async {
      final pubspecFile = File(path.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: test_project
version: 1.0.0
flutter:
  assets:
    - assets/images/
''');

      final result = await fileService.readPubspec(tempDir.path);

      expect(result, isNotNull);
      expect(result!['name'], equals('test_project'));
      expect(result['flutter']['assets'], isNotNull);
    });

    test('throws AssetOptException for missing pubspec', () async {
      expect(
        () => fileService.readPubspec(tempDir.path),
        throwsA(isA<AssetOptException>().having(
          (e) => e.message,
          'message',
          contains('pubspec.yaml not found'),
        )),
      );
    });

    test('throws AssetOptException for invalid yaml', () async {
      final pubspecFile = File(path.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('invalid: yaml: content: [');

      expect(
        () => fileService.readPubspec(tempDir.path),
        throwsA(isA<AssetOptException>().having(
          (e) => e.message,
          'message',
          contains('Invalid pubspec.yaml'),
        )),
      );
    });
  });

  group('findAssetPaths', () {
    test('returns normalized absolute paths for valid assets', () async {
      final pubspecFile = File(path.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: test_project
flutter:
  assets:
    - assets/images/
    - assets/icons/
''');

      final result = await fileService.findAssetPaths(tempDir.path);

      expect(result, hasLength(2));
      expect(result[0], equals(path.join(tempDir.path, 'assets/images/')));
      expect(result[1], equals(path.join(tempDir.path, 'assets/icons/')));
    });

    test('returns empty list when flutter section is missing', () async {
      final pubspecFile = File(path.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: test_project
version: 1.0.0
''');

      final result = await fileService.findAssetPaths(tempDir.path);

      expect(result, isEmpty);
    });

    test('returns empty list when assets section is missing', () async {
      final pubspecFile = File(path.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: test_project
flutter:
  uses-material-design: true
''');

      final result = await fileService.findAssetPaths(tempDir.path);

      expect(result, isEmpty);
    });
  });

  group('scanAssets', () {
    test('finds files in asset directories', () async {
      final assetsDir = Directory(path.join(tempDir.path, 'assets'));
      await assetsDir.create();

      final jpgFile = File(path.join(assetsDir.path, 'image.jpg'));
      await jpgFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);

      final pngFile = File(path.join(assetsDir.path, 'icon.png'));
      await pngFile.writeAsBytes([0x89, 0x50, 0x4E, 0x47]);

      final result = await fileService.scanAssets([assetsDir.path]);

      expect(result.assets, hasLength(2));
      expect(result.errors, isEmpty);
      expect(
        result.assets.map((a) => a.name),
        containsAll(['image.jpg', 'icon.png']),
      );
    });

    test('respects extensions filter', () async {
      final assetsDir = Directory(path.join(tempDir.path, 'assets'));
      await assetsDir.create();

      final jpgFile = File(path.join(assetsDir.path, 'image.jpg'));
      await jpgFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);

      final pngFile = File(path.join(assetsDir.path, 'icon.png'));
      await pngFile.writeAsBytes([0x89, 0x50, 0x4E, 0x47]);

      final result = await fileService.scanAssets(
        [assetsDir.path],
        allowedExtensions: {'.jpg'},
      );

      expect(result.assets, hasLength(1));
      expect(result.assets.first.name, equals('image.jpg'));
    });

    test('handles missing directories', () async {
      final missingPath = path.join(tempDir.path, 'nonexistent');

      final result = await fileService.scanAssets([missingPath]);

      expect(result.assets, isEmpty);
      expect(result.errors, hasLength(1));
      expect(result.errors[missingPath], contains('does not exist'));
    });

    test('scans subdirectories when recursive is true', () async {
      final assetsDir = Directory(path.join(tempDir.path, 'assets'));
      final subDir = Directory(path.join(assetsDir.path, 'icons'));
      await subDir.create(recursive: true);

      final rootFile = File(path.join(assetsDir.path, 'root.png'));
      await rootFile.writeAsBytes([0x89, 0x50, 0x4E, 0x47]);

      final subFile = File(path.join(subDir.path, 'sub.png'));
      await subFile.writeAsBytes([0x89, 0x50, 0x4E, 0x47]);

      final result = await fileService.scanAssets(
        [assetsDir.path],
        recursive: true,
      );

      expect(result.assets, hasLength(2));
    });

    test('ignores unsupported file types', () async {
      final assetsDir = Directory(path.join(tempDir.path, 'assets'));
      await assetsDir.create();

      final jpgFile = File(path.join(assetsDir.path, 'image.jpg'));
      await jpgFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);

      final txtFile = File(path.join(assetsDir.path, 'readme.txt'));
      await txtFile.writeAsString('hello');

      final result = await fileService.scanAssets([assetsDir.path]);

      expect(result.assets, hasLength(1));
      expect(result.assets.first.name, equals('image.jpg'));
    });
  });

  group('backupFile and restoreBackup', () {
    test('backup is created with .backup extension', () async {
      final originalFile = File(path.join(tempDir.path, 'test.jpg'));
      await originalFile.writeAsBytes([1, 2, 3, 4, 5]);

      await fileService.backupFile(originalFile);

      final backupFile = File('${originalFile.path}.backup');
      expect(await backupFile.exists(), isTrue);
      expect(await backupFile.readAsBytes(), equals([1, 2, 3, 4, 5]));
    });

    test('restore works and cleans up backup', () async {
      final originalFile = File(path.join(tempDir.path, 'test.jpg'));
      await originalFile.writeAsBytes([1, 2, 3, 4, 5]);
      await fileService.backupFile(originalFile);

      await originalFile.writeAsBytes([9, 9, 9]);

      await fileService.restoreBackup(originalFile.path);

      expect(await originalFile.readAsBytes(), equals([1, 2, 3, 4, 5]));

      final backupFile = File('${originalFile.path}.backup');
      expect(await backupFile.exists(), isFalse);
    });

    test('cleanupBackups removes all backup files', () async {
      final file1 = File(path.join(tempDir.path, 'test1.jpg'));
      final file2 = File(path.join(tempDir.path, 'test2.png'));
      await file1.writeAsBytes([1, 2, 3]);
      await file2.writeAsBytes([4, 5, 6]);

      await fileService.backupFile(file1);
      await fileService.backupFile(file2);

      await fileService.cleanupBackups([file1.path, file2.path]);

      expect(await File('${file1.path}.backup').exists(), isFalse);
      expect(await File('${file2.path}.backup').exists(), isFalse);
    });

    test('restoreBackup does nothing if backup does not exist', () async {
      final originalFile = File(path.join(tempDir.path, 'test.jpg'));
      await originalFile.writeAsBytes([1, 2, 3]);

      await fileService.restoreBackup(originalFile.path);

      expect(await originalFile.readAsBytes(), equals([1, 2, 3]));
    });
  });
}
