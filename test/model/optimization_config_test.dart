import 'package:test/test.dart';
import 'package:asset_opt/model/optimization_config.dart';

void main() {
  group('OptimizationConfig', () {
    test('creates instance with default values', () {
      final config = OptimizationConfig();

      expect(config.jpegQuality, equals(85));
      expect(config.webpQuality, equals(80));
      expect(config.resize, isNull);
      expect(config.convertToWebp, isFalse);
      expect(config.stripMetadata, isTrue);
    });

    test('creates instance with custom values', () {
      final config = OptimizationConfig(
        jpegQuality: 75,
        webpQuality: 90,
        resize: ImageResize(width: 800, height: 600),
        convertToWebp: true,
        stripMetadata: false,
      );

      expect(config.jpegQuality, equals(75));
      expect(config.webpQuality, equals(90));
      expect(config.resize, isNotNull);
      expect(config.resize!.width, equals(800));
      expect(config.resize!.height, equals(600));
      expect(config.convertToWebp, isTrue);
      expect(config.stripMetadata, isFalse);
    });

    test('allows partial custom values', () {
      final config = OptimizationConfig(
        jpegQuality: 60,
      );

      expect(config.jpegQuality, equals(60));
      expect(config.webpQuality, equals(80));
      expect(config.stripMetadata, isTrue);
    });
  });

  group('ImageResize', () {
    test('creates instance with required dimensions', () {
      final resize = ImageResize(width: 1920, height: 1080);

      expect(resize.width, equals(1920));
      expect(resize.height, equals(1080));
    });

    test('allows zero dimensions', () {
      final resize = ImageResize(width: 0, height: 0);

      expect(resize.width, equals(0));
      expect(resize.height, equals(0));
    });

    test('allows different aspect ratios', () {
      final square = ImageResize(width: 500, height: 500);
      final wide = ImageResize(width: 1920, height: 1080);
      final tall = ImageResize(width: 1080, height: 1920);

      expect(square.width, equals(square.height));
      expect(wide.width, greaterThan(wide.height));
      expect(tall.height, greaterThan(tall.width));
    });
  });
}
