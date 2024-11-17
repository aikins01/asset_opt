import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:yaml/yaml.dart';

class AssetOptimizer {
  final String projectPath;
  final int quality;
  final bool recursive;

  AssetOptimizer({
    required this.projectPath,
    this.quality = 85,
    this.recursive = true,
  });

  Future<OptimizationResult> optimize() async {
    final result = OptimizationResult();

    // Validate project path
    if (!await Directory(projectPath).exists()) {
      throw Exception('Project directory does not exist');
    }

    // Read pubspec.yaml to get assets directory
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      throw Exception('pubspec.yaml not found');
    }

    final pubspecContent = await pubspecFile.readAsString();
    final pubspec = loadYaml(pubspecContent);

    // Get assets paths from pubspec
    final assetPaths = <String>[];
    if (pubspec['flutter'] != null && pubspec['flutter']['assets'] != null) {
      assetPaths.addAll((pubspec['flutter']['assets'] as YamlList)
          .map((e) => path.join(projectPath, e.toString())));
    }

    if (assetPaths.isEmpty) {
      throw Exception('No asset directories found in pubspec.yaml');
    }

    // Process each asset directory
    for (final assetPath in assetPaths) {
      final directory = Directory(assetPath);
      if (!await directory.exists()) continue;

      await for (final entity in directory.list(recursive: recursive)) {
        if (entity is! File) continue;

        final extension = path.extension(entity.path).toLowerCase();
        if (!['.jpg', '.jpeg', '.png'].contains(extension)) continue;

        final originalSize = await entity.length();
        final optimizedFile = await _optimizeImage(entity.path);

        if (optimizedFile != null) {
          final newSize = await optimizedFile.length();
          final saved = originalSize - newSize;

          if (saved > 0) {
            await entity.delete();
            await optimizedFile.copy(entity.path);
            await optimizedFile.delete();

            result.addFile(
                path.basename(entity.path), originalSize, newSize, saved);
          }
        }
      }
    }

    return result;
  }

  Future<File?> _optimizeImage(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return null;

      final extension = path.extension(imagePath).toLowerCase();
      final optimizedPath = '$imagePath.optimized';

      List<int> optimizedBytes;
      if (extension == '.jpg' || extension == '.jpeg') {
        optimizedBytes = img.encodeJpg(image, quality: quality);
      } else if (extension == '.png') {
        optimizedBytes = img.encodePng(image, level: 9);
      } else {
        return null;
      }

      return await File(optimizedPath).writeAsBytes(optimizedBytes);
    } catch (e) {
      print('Error processing $imagePath: $e');
      return null;
    }
  }
}

class OptimizationResult {
  final List<FileResult> files = [];
  int get totalFiles => files.length;
  int get totalSaved => files.fold(0, (sum, file) => sum + file.savedBytes);

  void addFile(String name, int originalSize, int newSize, int savedBytes) {
    files.add(FileResult(
      name: name,
      originalSize: originalSize,
      newSize: newSize,
      savedBytes: savedBytes,
    ));
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    for (final file in files) {
      buffer.writeln('Optimized ${file.name}:');
      buffer.writeln(
          '  Original: ${(file.originalSize / 1024).toStringAsFixed(2)} KB');
      buffer.writeln('  New: ${(file.newSize / 1024).toStringAsFixed(2)} KB');
      buffer.writeln(
          '  Saved: ${(file.savedBytes / 1024).toStringAsFixed(2)} KB\n');
    }

    buffer.writeln('Summary:');
    buffer.writeln('Files processed: $totalFiles');
    buffer.writeln(
        'Total space saved: ${(totalSaved / 1024 / 1024).toStringAsFixed(2)} MB');

    return buffer.toString();
  }
}

class FileResult {
  final String name;
  final int originalSize;
  final int newSize;
  final int savedBytes;

  FileResult({
    required this.name,
    required this.originalSize,
    required this.newSize,
    required this.savedBytes,
  });
}
