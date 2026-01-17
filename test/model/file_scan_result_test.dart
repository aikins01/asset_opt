import 'package:test/test.dart';
import 'package:asset_opt/model/file_scan_result.dart';
import 'package:asset_opt/model/asset_info.dart';

void main() {
  group('FileScanResult', () {
    test('creates instance with empty assets and errors', () {
      final result = FileScanResult(
        assets: [],
        errors: {},
      );

      expect(result.assets, isEmpty);
      expect(result.errors, isEmpty);
    });

    test('creates instance with assets', () {
      final assets = [
        AssetInfo(
          name: 'image1.png',
          path: '/assets/image1.png',
          size: 1000,
          type: 'png',
          lastModified: DateTime.now(),
        ),
        AssetInfo(
          name: 'image2.jpg',
          path: '/assets/image2.jpg',
          size: 2000,
          type: 'jpeg',
          lastModified: DateTime.now(),
        ),
      ];

      final result = FileScanResult(
        assets: assets,
        errors: {},
      );

      expect(result.assets, hasLength(2));
      expect(result.assets[0].name, equals('image1.png'));
      expect(result.assets[1].name, equals('image2.jpg'));
    });

    test('creates instance with errors', () {
      final errors = {
        '/missing/dir': 'Directory does not exist',
        '/unreadable/file.png': 'Permission denied',
      };

      final result = FileScanResult(
        assets: [],
        errors: errors,
      );

      expect(result.errors, hasLength(2));
      expect(result.errors['/missing/dir'], contains('does not exist'));
      expect(result.errors['/unreadable/file.png'], contains('Permission'));
    });

    test('creates instance with both assets and errors', () {
      final assets = [
        AssetInfo(
          name: 'valid.png',
          path: '/assets/valid.png',
          size: 500,
          type: 'png',
          lastModified: DateTime.now(),
        ),
      ];
      final errors = {
        '/assets/missing': 'Not found',
      };

      final result = FileScanResult(
        assets: assets,
        errors: errors,
      );

      expect(result.assets, hasLength(1));
      expect(result.errors, hasLength(1));
    });
  });
}
