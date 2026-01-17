import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:asset_opt/service/image_service.dart';
import 'package:asset_opt/model/optimization_config.dart';
import 'package:asset_opt/utils/exceptions.dart';

void main() {
  late Directory tempDir;
  late ImageService imageService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('asset_opt_image_test_');
    imageService = ImageService();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> createTestPng({
    int width = 100,
    int height = 100,
    bool withAlpha = false,
  }) async {
    final image = img.Image(width: width, height: height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final a = withAlpha ? ((x + y) % 256) : 255;
        image.setPixelRgba(x, y, (x * 2) % 256, (y * 2) % 256, 128, a);
      }
    }

    final filePath = path.join(tempDir.path, 'test_${width}x$height.png');
    final file = File(filePath);
    await file.writeAsBytes(img.encodePng(image));
    return file;
  }

  Future<File> createTestJpeg({int width = 100, int height = 100}) async {
    final image = img.Image(width: width, height: height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        image.setPixelRgba(x, y, (x * 3) % 256, (y * 3) % 256, 100, 255);
      }
    }

    final filePath = path.join(tempDir.path, 'test_${width}x$height.jpg');
    final file = File(filePath);
    await file.writeAsBytes(img.encodeJpg(image, quality: 95));
    return file;
  }

  group('getImageInfo', () {
    test('returns correct dimensions for valid PNG', () async {
      final testFile = await createTestPng(width: 200, height: 150);

      final result = await imageService.getImageInfo(testFile);

      expect(result, isNotNull);
      expect(result!.width, equals(200));
      expect(result.height, equals(150));
    });

    test('returns correct dimensions for valid JPEG', () async {
      final testFile = await createTestJpeg(width: 300, height: 200);

      final result = await imageService.getImageInfo(testFile);

      expect(result, isNotNull);
      expect(result!.width, equals(300));
      expect(result.height, equals(200));
    });

    test('detects alpha channel in PNG', () async {
      final withAlphaImage = img.Image(width: 50, height: 50, numChannels: 4);
      for (var y = 0; y < 50; y++) {
        for (var x = 0; x < 50; x++) {
          withAlphaImage.setPixelRgba(x, y, 100, 100, 100, 128);
        }
      }
      final withAlphaFile = File(path.join(tempDir.path, 'with_alpha.png'));
      await withAlphaFile.writeAsBytes(img.encodePng(withAlphaImage));

      final withoutAlphaImage = img.Image(width: 50, height: 50, numChannels: 3);
      for (var y = 0; y < 50; y++) {
        for (var x = 0; x < 50; x++) {
          withoutAlphaImage.setPixelRgb(x, y, 100, 100, 100);
        }
      }
      final withoutAlphaFile = File(path.join(tempDir.path, 'no_alpha.png'));
      await withoutAlphaFile.writeAsBytes(img.encodePng(withoutAlphaImage));

      final resultWithAlpha = await imageService.getImageInfo(withAlphaFile);
      final resultWithoutAlpha = await imageService.getImageInfo(withoutAlphaFile);

      expect(resultWithAlpha!.hasAlpha, isTrue);
      expect(resultWithoutAlpha!.hasAlpha, isFalse);
    });

    test('returns null for invalid image file', () async {
      final invalidFile = File(path.join(tempDir.path, 'invalid.png'));
      await invalidFile.writeAsBytes([0, 1, 2, 3, 4, 5]);

      final result = await imageService.getImageInfo(invalidFile);
      expect(result, isNull);
    });

    test('throws for empty file', () async {
      final emptyFile = File(path.join(tempDir.path, 'empty.png'));
      await emptyFile.writeAsBytes([]);

      expect(
        () => imageService.getImageInfo(emptyFile),
        throwsA(isA<AssetOptException>()),
      );
    });
  });

  group('optimizeImage', () {
    test('compresses JPEG with specified quality', () async {
      final testFile = await createTestJpeg(width: 200, height: 200);
      final originalSize = await testFile.length();

      final config = OptimizationConfig(jpegQuality: 60);
      final optimized = await imageService.optimizeImage(testFile, config);

      expect(optimized, isNotNull);
      expect(await optimized!.exists(), isTrue);

      final optimizedSize = await optimized.length();
      expect(optimizedSize, lessThan(originalSize));

      await optimized.delete();
    });

    test('compresses PNG', () async {
      final testFile = await createTestPng(width: 200, height: 200);

      final config = OptimizationConfig();
      final optimized = await imageService.optimizeImage(testFile, config);

      expect(optimized, isNotNull);
      expect(await optimized!.exists(), isTrue);

      await optimized.delete();
    });

    test('respects resize configuration', () async {
      final testFile = await createTestJpeg(width: 400, height: 300);

      final config = OptimizationConfig(
        resize: ImageResize(width: 200, height: 150),
      );
      final optimized = await imageService.optimizeImage(testFile, config);

      expect(optimized, isNotNull);

      final optimizedImage = img.decodeImage(await optimized!.readAsBytes());
      expect(optimizedImage!.width, equals(200));
      expect(optimizedImage.height, equals(150));

      await optimized.delete();
    });

    test('creates optimized file with .optimized extension', () async {
      final testFile = await createTestPng();

      final config = OptimizationConfig();
      final optimized = await imageService.optimizeImage(testFile, config);

      expect(optimized!.path, equals('${testFile.path}.optimized'));

      await optimized.delete();
    });

    test('returns null for unsupported image type', () async {
      final svgFile = File(path.join(tempDir.path, 'test.svg'));
      await svgFile.writeAsString('<svg></svg>');

      final config = OptimizationConfig();
      final result = await imageService.optimizeImage(svgFile, config);

      expect(result, isNull);
    });

    test('different JPEG qualities produce different file sizes', () async {
      final testFile = await createTestJpeg(width: 300, height: 300);

      final configLow = OptimizationConfig(jpegQuality: 10);
      final configHigh = OptimizationConfig(jpegQuality: 100);

      final optimizedLow = await imageService.optimizeImage(testFile, configLow);
      final sizeLow = await optimizedLow!.length();
      await optimizedLow.delete();

      final highFile = await createTestJpeg(width: 300, height: 300);
      final optimizedHigh = await imageService.optimizeImage(highFile, configHigh);
      final sizeHigh = await optimizedHigh!.length();

      expect(sizeLow, lessThanOrEqualTo(sizeHigh));
    });
  });
}
