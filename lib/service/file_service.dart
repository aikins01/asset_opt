import 'dart:io';
import 'package:asset_opt/model/asset_info.dart';
import 'package:asset_opt/model/file_scan_result.dart';
import 'package:asset_opt/utils/exceptions.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

class FileService {
  static const _supportedTypes = {
    '.jpg': 'jpeg',
    '.jpeg': 'jpeg',
    '.png': 'png',
    '.webp': 'webp',
    '.svg': 'svg',
    '.gif': 'gif'
  };

  Future<YamlMap?> readPubspec(String projectPath) async {
    try {
      final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
      if (!await pubspecFile.exists()) {
        throw AssetOptException('pubspec.yaml not found in $projectPath');
      }

      final content = await pubspecFile.readAsString();
      return loadYaml(content) as YamlMap;
    } on YamlException catch (e) {
      throw AssetOptException('Invalid pubspec.yaml: ${e.message}');
    } catch (e) {
      throw AssetOptException('Failed to read pubspec.yaml: $e');
    }
  }

  Future<List<String>> findAssetPaths(String projectPath) async {
    final pubspec = await readPubspec(projectPath);

    if (pubspec == null ||
        pubspec['flutter'] == null ||
        pubspec['flutter']['assets'] == null) {
      return [];
    }

    try {
      return (pubspec['flutter']['assets'] as YamlList)
          .map((e) => path.join(projectPath, e.toString()))
          .toList();
    } catch (e) {
      throw AssetOptException('Invalid assets configuration in pubspec.yaml');
    }
  }

  Future<FileScanResult> scanAssets(
    List<String> assetPaths, {
    bool recursive = true,
    Set<String>? allowedExtensions,
  }) async {
    final assets = <AssetInfo>[];
    final errors = <String, String>{};
    final allowedExts = allowedExtensions ?? _supportedTypes.keys.toSet();

    for (final assetPath in assetPaths) {
      final directory = Directory(assetPath);

      if (!await directory.exists()) {
        errors[assetPath] = 'Directory does not exist';
        continue;
      }

      try {
        await for (final entity in directory.list(recursive: recursive)) {
          if (entity is! File) continue;

          final extension = path.extension(entity.path).toLowerCase();
          if (!allowedExts.contains(extension)) continue;

          try {
            final stat = await entity.stat();
            assets.add(AssetInfo(
              name: path.basename(entity.path),
              path: entity.path,
              size: stat.size,
              type: _supportedTypes[extension] ?? extension.substring(1),
              lastModified: stat.modified,
            ));
          } catch (e) {
            errors[entity.path] = 'Failed to read file: $e';
          }
        }
      } catch (e) {
        errors[assetPath] = 'Failed to scan directory: $e';
      }
    }

    return FileScanResult(
      assets: assets,
      errors: errors,
    );
  }

  Future<void> backupFile(File file) async {
    final backupPath = '${file.path}.backup';
    try {
      await file.copy(backupPath);
    } catch (e) {
      throw AssetOptException('Failed to backup file ${file.path}: $e');
    }
  }

  Future<void> restoreBackup(String originalPath) async {
    final backupFile = File('$originalPath.backup');
    final originalFile = File(originalPath);

    try {
      if (await backupFile.exists()) {
        await backupFile.copy(originalPath);
        await backupFile.delete();
      }
    } catch (e) {
      throw AssetOptException('Failed to restore backup for $originalPath: $e');
    }
  }

  Future<void> cleanupBackups(List<String> paths) async {
    for (final path in paths) {
      try {
        final backupFile = File('$path.backup');
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
      } catch (e) {
        print('Warning: Failed to cleanup backup for $path: $e');
      }
    }
  }
}
