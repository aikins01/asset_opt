import 'package:test/test.dart';
import 'package:asset_opt/model/image_info.dart';

void main() {
  group('ImageInfo', () {
    test('creates instance with required fields', () {
      final info = ImageInfo(
        width: 1920,
        height: 1080,
        format: 'jpeg',
        hasAlpha: false,
      );

      expect(info.width, equals(1920));
      expect(info.height, equals(1080));
      expect(info.format, equals('jpeg'));
      expect(info.hasAlpha, isFalse);
      expect(info.metadata, isNull);
    });

    test('creates instance with optional metadata', () {
      final info = ImageInfo(
        width: 800,
        height: 600,
        format: 'png',
        hasAlpha: true,
        metadata: {'dpi': 72, 'colorSpace': 'sRGB'},
      );

      expect(info.metadata, isNotNull);
      expect(info.metadata!['dpi'], equals(72));
      expect(info.metadata!['colorSpace'], equals('sRGB'));
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final info = ImageInfo(
          width: 500,
          height: 400,
          format: 'webp',
          hasAlpha: true,
          metadata: {'key': 'value'},
        );

        final json = info.toJson();

        expect(json['width'], equals(500));
        expect(json['height'], equals(400));
        expect(json['format'], equals('webp'));
        expect(json['hasAlpha'], isTrue);
        expect(json['metadata']['key'], equals('value'));
      });

      test('serializes null metadata', () {
        final info = ImageInfo(
          width: 100,
          height: 100,
          format: 'gif',
          hasAlpha: false,
        );

        final json = info.toJson();

        expect(json['metadata'], isNull);
      });
    });

    group('fromJson', () {
      test('deserializes all fields correctly', () {
        final json = {
          'width': 1024,
          'height': 768,
          'format': 'png',
          'hasAlpha': true,
          'metadata': {'author': 'test'},
        };

        final info = ImageInfo.fromJson(json);

        expect(info.width, equals(1024));
        expect(info.height, equals(768));
        expect(info.format, equals('png'));
        expect(info.hasAlpha, isTrue);
        expect(info.metadata!['author'], equals('test'));
      });

      test('handles null metadata', () {
        final json = {
          'width': 640,
          'height': 480,
          'format': 'jpeg',
          'hasAlpha': false,
          'metadata': null,
        };

        final info = ImageInfo.fromJson(json);

        expect(info.metadata, isNull);
      });

      test('round-trips correctly through toJson/fromJson', () {
        final original = ImageInfo(
          width: 2560,
          height: 1440,
          format: 'png',
          hasAlpha: true,
          metadata: {'compression': 9, 'interlaced': false},
        );

        final json = original.toJson();
        final restored = ImageInfo.fromJson(json);

        expect(restored.width, equals(original.width));
        expect(restored.height, equals(original.height));
        expect(restored.format, equals(original.format));
        expect(restored.hasAlpha, equals(original.hasAlpha));
        expect(
          restored.metadata!['compression'],
          equals(original.metadata!['compression']),
        );
      });
    });
  });
}
