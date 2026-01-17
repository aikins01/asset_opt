import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Service for detecting unused assets by scanning Dart code.
class UsageService {
  static const _concurrencyLimit = 8;
  static const _assetExtensions = {'.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg', '.json'};
  static final _variantPattern = RegExp(r'/\d+(\.\d+)?x/');
  
  static const _rootExcludeDirs = {
    '.dart_tool',
    'build',
    '.idea',
    '.vscode',
    'ios',
    'android',
    'web',
    'macos',
    'linux',
    'windows',
  };

  static const _excludePatterns = [
    '.g.dart',
    '.freezed.dart',
    '.gr.dart',
    '.mocks.dart',
    '.gen.dart',
    '.pb.dart',
    '.pbjson.dart',
    '.pbgrpc.dart',
  ];

  /// Finds all asset paths referenced in Dart code.
  Future<Set<String>> findUsedAssetPaths(String projectRoot) async {
    final usedPaths = <String>{};
    final dartFiles = await _findDartFiles(projectRoot);

    for (var i = 0; i < dartFiles.length; i += _concurrencyLimit) {
      final batch = dartFiles.skip(i).take(_concurrencyLimit).toList();
      
      final batchResults = await Future.wait(
        batch.map((file) async {
          try {
            final content = await file.readAsString();
            return _extractAssetPaths(content);
          } catch (_) {
            return <String>{};
          }
        }),
      );
      
      for (final paths in batchResults) {
        usedPaths.addAll(paths);
      }
    }

    return usedPaths;
  }

  /// Identifies assets not referenced in code.
  Set<String> findUnusedAssets(
    List<String> allAssetPaths,
    Set<String> usedAssetPaths,
    String projectRoot,
  ) {
    final unused = <String>{};

    for (final assetPath in allAssetPaths) {
      final normalizedKey = normalizeAssetKey(assetPath, projectRoot);
      
      if (!usedAssetPaths.contains(normalizedKey)) {
        unused.add(assetPath);
      }
    }

    return unused;
  }

  Future<List<File>> _findDartFiles(String projectRoot) async {
    final files = <File>[];
    final dirs = ['lib', 'bin', 'test']
        .map((d) => Directory(p.join(projectRoot, d)))
        .toList();

    for (final dir in dirs) {
      if (await dir.exists()) {
        await _collectDartFiles(dir, files);
      }
    }

    return files;
  }

  Future<void> _collectDartFiles(Directory dir, List<File> files) async {
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final relativePath = p.relative(entity.path, from: dir.path);
        
        if (_isExcludedFile(relativePath)) continue;
        
        files.add(entity);
      }
    }
  }

  bool _isExcludedFile(String relativePath) {
    final parts = p.split(relativePath);
    if (parts.isNotEmpty && _rootExcludeDirs.contains(parts.first)) {
      return true;
    }
    
    for (final pattern in _excludePatterns) {
      if (relativePath.endsWith(pattern)) return true;
    }
    
    return false;
  }

  Set<String> _extractAssetPaths(String content) {
    final paths = <String>{};
    final stringPattern = RegExp(r'''r?(["'])((?:[^"'\\]|\\.)*)(\1)''');
    
    for (final match in stringPattern.allMatches(content)) {
      final value = match.group(2);
      if (value == null || value.isEmpty) continue;
      
      final normalized = value.replaceAll('\\/', '/').replaceAll('\\\\', '/');
      
      if (_isLikelyAssetPath(normalized)) {
        paths.add(_normalizeAssetPath(normalized));
      }
    }
    
    return paths;
  }

  bool _isLikelyAssetPath(String path) {
    if (path.startsWith('http://') || 
        path.startsWith('https://') || 
        path.startsWith('data:') ||
        path.startsWith('package:') ||
        path.startsWith('packages/')) {
      return false;
    }
    
    final ext = p.extension(path).toLowerCase();
    if (!_assetExtensions.contains(ext)) return false;
    
    if (path.contains('/')) return true;
    
    return path.contains('.');
  }

  String _normalizeAssetPath(String path) {
    var normalized = path.replaceAll('\\', '/');
    if (normalized.startsWith('./')) {
      normalized = normalized.substring(2);
    }
    if (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    
    return normalized.replaceAll(_variantPattern, '/');
  }

  /// Normalizes an asset path for comparison.
  String normalizeAssetKey(String assetPath, String projectRoot) {
    var relative = p.relative(assetPath, from: projectRoot);
    relative = relative.replaceAll('\\', '/');
    
    if (relative.startsWith('./')) {
      relative = relative.substring(2);
    }
    
    return relative.replaceAll(_variantPattern, '/');
  }
}
