import 'package:test/test.dart';
import 'package:asset_opt/model/asset_info.dart';
import 'package:asset_opt/model/image_info.dart';

void main() {
  group('AssetInfo', () {
    test('creates instance with required fields', () {
      final now = DateTime.now();
      final asset = AssetInfo(
        name: 'test.png',
        path: '/path/to/test.png',
        size: 1024,
        type: 'png',
        lastModified: now,
      );

      expect(asset.name, equals('test.png'));
      expect(asset.path, equals('/path/to/test.png'));
      expect(asset.size, equals(1024));
      expect(asset.type, equals('png'));
      expect(asset.lastModified, equals(now));
      expect(asset.imageInfo, isNull);
    });

    test('creates instance with optional imageInfo', () {
      final asset = AssetInfo(
        name: 'test.png',
        path: '/path/to/test.png',
        size: 2048,
        type: 'png',
        lastModified: DateTime.now(),
        imageInfo: ImageInfo(
          width: 100,
          height: 200,
          format: 'png',
          hasAlpha: true,
        ),
      );

      expect(asset.imageInfo, isNotNull);
      expect(asset.imageInfo!.width, equals(100));
    });

    test('directory returns parent directory path', () {
      final asset = AssetInfo(
        name: 'test.png',
        path: '/path/to/assets/test.png',
        size: 1024,
        type: 'png',
        lastModified: DateTime.now(),
      );

      expect(asset.directory, equals('/path/to/assets'));
    });

    test('extension returns file extension', () {
      final asset = AssetInfo(
        name: 'test.png',
        path: '/path/to/test.png',
        size: 1024,
        type: 'png',
        lastModified: DateTime.now(),
      );

      expect(asset.extension, equals('.png'));
    });

    group('toJson', () {
      test('serializes basic fields correctly', () {
        final date = DateTime(2024, 6, 15, 10, 30);
        final asset = AssetInfo(
          name: 'logo.jpg',
          path: '/assets/logo.jpg',
          size: 5000,
          type: 'jpeg',
          lastModified: date,
        );

        final json = asset.toJson();

        expect(json['name'], equals('logo.jpg'));
        expect(json['path'], equals('/assets/logo.jpg'));
        expect(json['size'], equals(5000));
        expect(json['type'], equals('jpeg'));
        expect(json['lastModified'], equals(date.toIso8601String()));
        expect(json['imageInfo'], isNull);
      });

      test('serializes imageInfo when present', () {
        final asset = AssetInfo(
          name: 'test.png',
          path: '/test.png',
          size: 1000,
          type: 'png',
          lastModified: DateTime.now(),
          imageInfo: ImageInfo(
            width: 800,
            height: 600,
            format: 'png',
            hasAlpha: false,
          ),
        );

        final json = asset.toJson();

        expect(json['imageInfo'], isNotNull);
        expect(json['imageInfo']['width'], equals(800));
        expect(json['imageInfo']['height'], equals(600));
        expect(json['imageInfo']['format'], equals('png'));
        expect(json['imageInfo']['hasAlpha'], equals(false));
      });
    });

    group('fromJson', () {
      test('deserializes basic fields correctly', () {
        final json = {
          'name': 'icon.png',
          'path': '/icons/icon.png',
          'size': 2500,
          'type': 'png',
          'lastModified': '2024-03-20T14:00:00.000',
          'imageInfo': null,
        };

        final asset = AssetInfo.fromJson(json);

        expect(asset.name, equals('icon.png'));
        expect(asset.path, equals('/icons/icon.png'));
        expect(asset.size, equals(2500));
        expect(asset.type, equals('png'));
        expect(asset.lastModified.year, equals(2024));
        expect(asset.imageInfo, isNull);
      });

      test('deserializes imageInfo when present', () {
        final json = {
          'name': 'photo.jpg',
          'path': '/photos/photo.jpg',
          'size': 10000,
          'type': 'jpeg',
          'lastModified': '2024-01-01T00:00:00.000',
          'imageInfo': {
            'width': 1920,
            'height': 1080,
            'format': 'jpeg',
            'hasAlpha': false,
          },
        };

        final asset = AssetInfo.fromJson(json);

        expect(asset.imageInfo, isNotNull);
        expect(asset.imageInfo!.width, equals(1920));
        expect(asset.imageInfo!.height, equals(1080));
      });

      test('round-trips correctly through toJson/fromJson', () {
        final original = AssetInfo(
          name: 'roundtrip.png',
          path: '/test/roundtrip.png',
          size: 12345,
          type: 'png',
          lastModified: DateTime(2024, 5, 10, 8, 30),
          imageInfo: ImageInfo(
            width: 500,
            height: 400,
            format: 'png',
            hasAlpha: true,
          ),
        );

        final json = original.toJson();
        final restored = AssetInfo.fromJson(json);

        expect(restored.name, equals(original.name));
        expect(restored.path, equals(original.path));
        expect(restored.size, equals(original.size));
        expect(restored.type, equals(original.type));
        expect(restored.imageInfo!.width, equals(original.imageInfo!.width));
        expect(restored.imageInfo!.hasAlpha, equals(original.imageInfo!.hasAlpha));
      });
    });
  });
}
