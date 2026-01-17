import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:asset_opt/service/cache_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('asset_opt_cache_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('initialize', () {
    test('loads existing cache from file', () async {
      final cachePath = path.join(tempDir.path, '.asset_opt_cache');
      final cacheFile = File(cachePath);
      final testDate = DateTime(2024, 1, 15, 10, 30);

      await cacheFile.writeAsString(jsonEncode({
        '/path/to/image.png': {
          'path': '/path/to/image.png',
          'size': 1024,
          'modified': testDate.toIso8601String(),
          'optimizedAt': testDate.toIso8601String(),
        },
      }));

      final cacheService = CacheService(cachePath: cachePath);
      await cacheService.initialize();

      expect(
        cacheService.shouldOptimize('/path/to/image.png', 1024, testDate),
        isFalse,
      );
    });

    test('handles missing cache file gracefully', () async {
      final cachePath = path.join(tempDir.path, 'nonexistent_cache');

      final cacheService = CacheService(cachePath: cachePath);
      await cacheService.initialize();

      expect(
        cacheService.shouldOptimize('/any/path.png', 100, DateTime.now()),
        isTrue,
      );
    });

    test('handles corrupted cache file gracefully', () async {
      final cachePath = path.join(tempDir.path, '.asset_opt_cache');
      final cacheFile = File(cachePath);
      await cacheFile.writeAsString('not valid json {{{');

      final cacheService = CacheService(cachePath: cachePath);
      await cacheService.initialize();

      expect(
        cacheService.shouldOptimize('/any/path.png', 100, DateTime.now()),
        isTrue,
      );
    });
  });

  group('save', () {
    test('creates parent directories if needed', () async {
      final nestedPath = path.join(tempDir.path, 'nested', 'dir', '.cache');

      final cacheService = CacheService(cachePath: nestedPath);
      cacheService.updateEntry('/test/image.png', 500, DateTime.now());

      await cacheService.save();

      final cacheFile = File(nestedPath);
      expect(await cacheFile.exists(), isTrue);
    });

    test('writes valid json to cache file', () async {
      final cachePath = path.join(tempDir.path, '.asset_opt_cache');
      final testDate = DateTime(2024, 6, 1, 12, 0);

      final cacheService = CacheService(cachePath: cachePath);
      cacheService.updateEntry('/test/image.png', 2048, testDate);
      await cacheService.save();

      final cacheFile = File(cachePath);
      final content = await cacheFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      expect(data['/test/image.png'], isNotNull);
      expect(data['/test/image.png']['size'], equals(2048));
      expect(data['/test/image.png']['path'], equals('/test/image.png'));
    });

    test('persists multiple entries', () async {
      final cachePath = path.join(tempDir.path, '.asset_opt_cache');
      final testDate = DateTime.now();

      final cacheService = CacheService(cachePath: cachePath);
      cacheService.updateEntry('/path/a.png', 100, testDate);
      cacheService.updateEntry('/path/b.jpg', 200, testDate);
      cacheService.updateEntry('/path/c.webp', 300, testDate);
      await cacheService.save();

      final cacheFile = File(cachePath);
      final content = await cacheFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      expect(data.keys, hasLength(3));
    });
  });

  group('shouldOptimize', () {
    test('returns true for new files not in cache', () async {
      final cachePath = path.join(tempDir.path, '.asset_opt_cache');
      final cacheService = CacheService(cachePath: cachePath);
      await cacheService.initialize();

      final result = cacheService.shouldOptimize(
        '/new/image.png',
        1024,
        DateTime.now(),
      );

      expect(result, isTrue);
    });

    test('returns false for cached files with unchanged size and date',
        () async {
      final cachePath = path.join(tempDir.path, '.asset_opt_cache');
      final testDate = DateTime(2024, 3, 15, 8, 0);

      final cacheService = CacheService(cachePath: cachePath);
      cacheService.updateEntry('/cached/image.png', 512, testDate);

      final result = cacheService.shouldOptimize('/cached/image.png', 512, testDate);

      expect(result, isFalse);
    });

    test('returns true when file size changed', () async {
      final cachePath = path.join(tempDir.path, '.asset_opt_cache');
      final testDate = DateTime(2024, 3, 15, 8, 0);

      final cacheService = CacheService(cachePath: cachePath);
      cacheService.updateEntry('/cached/image.png', 512, testDate);

      final result = cacheService.shouldOptimize(
        '/cached/image.png',
        1024,
        testDate,
      );

      expect(result, isTrue);
    });

    test('returns true when modified date changed', () async {
      final cachePath = path.join(tempDir.path, '.asset_opt_cache');
      final originalDate = DateTime(2024, 3, 15, 8, 0);
      final newDate = DateTime(2024, 3, 16, 10, 0);

      final cacheService = CacheService(cachePath: cachePath);
      cacheService.updateEntry('/cached/image.png', 512, originalDate);

      final result = cacheService.shouldOptimize('/cached/image.png', 512, newDate);

      expect(result, isTrue);
    });
  });

  group('updateEntry', () {
    test('normalizes paths consistently', () async {
      final cachePath = path.join(tempDir.path, '.asset_opt_cache');
      final testDate = DateTime(2024, 5, 20, 14, 30);

      final cacheService = CacheService(cachePath: cachePath);
      cacheService.updateEntry('/path/to/image.png', 256, testDate);

      expect(
        cacheService.shouldOptimize('/path/to/image.png', 256, testDate),
        isFalse,
      );
    });

    test('overwrites existing entry with same path', () async {
      final cachePath = path.join(tempDir.path, '.asset_opt_cache');
      final date1 = DateTime(2024, 1, 1);
      final date2 = DateTime(2024, 2, 1);

      final cacheService = CacheService(cachePath: cachePath);
      cacheService.updateEntry('/same/path.png', 100, date1);
      cacheService.updateEntry('/same/path.png', 200, date2);

      expect(cacheService.shouldOptimize('/same/path.png', 200, date2), isFalse);
      expect(cacheService.shouldOptimize('/same/path.png', 100, date1), isTrue);
    });

    test('stores optimizedAt timestamp', () async {
      final cachePath = path.join(tempDir.path, '.asset_opt_cache');
      final testDate = DateTime(2024, 4, 10);

      final cacheService = CacheService(cachePath: cachePath);
      cacheService.updateEntry('/test/path.jpg', 800, testDate);
      await cacheService.save();

      final cacheFile = File(cachePath);
      final content = await cacheFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      expect(data['/test/path.jpg']['optimizedAt'], isNotNull);
    });
  });
}
