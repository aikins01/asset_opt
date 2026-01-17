import 'dart:convert';
import 'dart:io';
import 'package:asset_opt/model/cache_entry.dart';
import 'package:path/path.dart' as p;

class CacheService {
  final String cachePath;
  final Map<String, CacheEntry> _cache = {};

  CacheService({required this.cachePath});

  String _normalizeKey(String path) => p.normalize(path);

  Future<void> initialize() async {
    try {
      final file = File(cachePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;

        data.forEach((key, value) {
          _cache[_normalizeKey(key)] = CacheEntry.fromJson(value);
        });
      }
    } catch (e) {
      print('Warning: Failed to load cache: $e');
    }
  }

  Future<void> save() async {
    try {
      final file = File(cachePath);
      final parent = file.parent;
      if (!await parent.exists()) {
        await parent.create(recursive: true);
      }
      final data = _cache.map(
        (key, value) => MapEntry(key, value.toJson()),
      );

      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('Warning: Failed to save cache: $e');
    }
  }

  bool shouldOptimize(String path, int size, DateTime modified) {
    final entry = _cache[_normalizeKey(path)];
    if (entry == null) return true;

    return entry.size != size || entry.modified != modified;
  }

  void updateEntry(String path, int size, DateTime modified) {
    final normalizedPath = _normalizeKey(path);
    _cache[normalizedPath] = CacheEntry(
      path: normalizedPath,
      size: size,
      modified: modified,
      optimizedAt: DateTime.now(),
    );
  }
}
