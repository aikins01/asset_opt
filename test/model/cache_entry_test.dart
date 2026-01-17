import 'package:test/test.dart';
import 'package:asset_opt/model/cache_entry.dart';

void main() {
  group('CacheEntry', () {
    test('creates instance with required fields', () {
      final modified = DateTime(2024, 3, 15);
      final optimizedAt = DateTime(2024, 3, 16);

      final entry = CacheEntry(
        path: '/path/to/image.png',
        size: 2048,
        modified: modified,
        optimizedAt: optimizedAt,
      );

      expect(entry.path, equals('/path/to/image.png'));
      expect(entry.size, equals(2048));
      expect(entry.modified, equals(modified));
      expect(entry.optimizedAt, equals(optimizedAt));
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final modified = DateTime(2024, 6, 1, 10, 30);
        final optimizedAt = DateTime(2024, 6, 2, 14, 0);

        final entry = CacheEntry(
          path: '/assets/logo.png',
          size: 5000,
          modified: modified,
          optimizedAt: optimizedAt,
        );

        final json = entry.toJson();

        expect(json['path'], equals('/assets/logo.png'));
        expect(json['size'], equals(5000));
        expect(json['modified'], equals(modified.toIso8601String()));
        expect(json['optimizedAt'], equals(optimizedAt.toIso8601String()));
      });
    });

    group('fromJson', () {
      test('deserializes all fields correctly', () {
        final json = {
          'path': '/icons/app.png',
          'size': 1234,
          'modified': '2024-04-10T08:00:00.000',
          'optimizedAt': '2024-04-11T12:30:00.000',
        };

        final entry = CacheEntry.fromJson(json);

        expect(entry.path, equals('/icons/app.png'));
        expect(entry.size, equals(1234));
        expect(entry.modified.year, equals(2024));
        expect(entry.modified.month, equals(4));
        expect(entry.modified.day, equals(10));
        expect(entry.optimizedAt.day, equals(11));
      });

      test('round-trips correctly through toJson/fromJson', () {
        final original = CacheEntry(
          path: '/test/roundtrip.jpg',
          size: 9999,
          modified: DateTime(2024, 5, 20, 16, 45),
          optimizedAt: DateTime(2024, 5, 21, 9, 15),
        );

        final json = original.toJson();
        final restored = CacheEntry.fromJson(json);

        expect(restored.path, equals(original.path));
        expect(restored.size, equals(original.size));
        expect(restored.modified, equals(original.modified));
        expect(restored.optimizedAt, equals(original.optimizedAt));
      });
    });
  });
}
