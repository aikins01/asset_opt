import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as p;

/// Provides native image optimization using bundled binaries.
///
/// Supports cwebp for WebP conversion and pngquant for PNG optimization.
/// Automatically uses bundled binaries or falls back to system-installed tools.
class NativeOptimizer {
  static const _version = '1.0.4';
  
  static String? _cwebpPath;
  static String? _pngquantPath;
  static bool _initialized = false;

  /// Initializes the native optimizer by locating available tools.
  ///
  /// Must be called before using [toWebp] or [optimizePng].
  static Future<void> initialize() async {
    if (_initialized) return;

    _cwebpPath = await _resolveTool('cwebp', ['-version']);
    _pngquantPath = await _resolveTool('pngquant', ['--version']);
    
    _initialized = true;
  }

  static Future<String?> _resolveTool(String name, List<String> versionArgs) async {
    final bundled = await _extractBundledTool(name);
    if (bundled != null && await _validateTool(bundled, versionArgs)) {
      return bundled;
    }
    
    final system = await _findSystemTool(name);
    if (system != null && await _validateTool(system, versionArgs)) {
      return system;
    }
    
    return null;
  }

  static Future<bool> _validateTool(String path, List<String> versionArgs) async {
    Process? proc;
    try {
      proc = await Process.start(path, versionArgs);
      final exitCode = await proc.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          proc?.kill();
          return 1;
        },
      );
      return exitCode == 0;
    } catch (_) {
      proc?.kill();
      return false;
    }
  }

  static Future<String?> _extractBundledTool(String name) async {
    final platform = _getPlatformDir();
    if (platform == null) return null;

    final ext = Platform.isWindows ? '.exe' : '';
    final bundledPath = await _getBundledBinaryPath(platform, '$name$ext');
    
    if (bundledPath == null) return null;
    
    final bundledFile = File(bundledPath);
    if (!await bundledFile.exists()) return null;

    final cacheDir = await _getCacheDir();
    final cachedPath = p.join(cacheDir, '$name$ext');
    final cachedFile = File(cachedPath);

    final bundledSize = await bundledFile.length();
    
    bool needsCopy = true;
    if (await cachedFile.exists()) {
      final cachedSize = await cachedFile.length();
      needsCopy = cachedSize != bundledSize;
    }

    if (needsCopy) {
      try {
        await Directory(cacheDir).create(recursive: true);
        await bundledFile.copy(cachedPath);
        
        if (!Platform.isWindows) {
          final chmodResult = await Process.run('chmod', ['+x', cachedPath]);
          if (chmodResult.exitCode != 0) {
            return null;
          }
        }
      } catch (_) {
        return null;
      }
    }

    if (!await cachedFile.exists()) return null;
    
    return cachedPath;
  }

  static Future<String?> _getBundledBinaryPath(String platform, String binary) async {
    final packageUri = Uri.parse('package:asset_opt/src/native_bins/$platform/$binary');
    
    try {
      final resolvedUri = await Isolate.resolvePackageUri(packageUri);
      if (resolvedUri != null && resolvedUri.scheme == 'file') {
        final path = resolvedUri.toFilePath();
        if (await File(path).exists()) {
          return path;
        }
      }
    } catch (_) {}

    final executableDir = p.dirname(Platform.resolvedExecutable);
    final aotPaths = [
      p.join(executableDir, 'native_bins', platform, binary),
      p.join(executableDir, '..', 'lib', 'src', 'native_bins', platform, binary),
      p.join(executableDir, 'src', 'native_bins', platform, binary),
    ];
    
    for (final aotPath in aotPaths) {
      if (await File(aotPath).exists()) {
        return aotPath;
      }
    }

    return null;
  }

  static String? _getPlatformDir() {
    final arch = Abi.current().toString();
    
    if (Platform.isMacOS) {
      if (arch.contains('arm64')) return 'macos-arm64';
      if (arch.contains('x64')) return 'macos-x64';
    } else if (Platform.isLinux) {
      if (arch.contains('arm64')) return 'linux-arm64';
      if (arch.contains('x64')) return 'linux-x64';
    } else if (Platform.isWindows) {
      if (arch.contains('x64')) return 'windows-x64';
    }
    
    return null;
  }

  static Future<String> _getCacheDir() async {
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData != null) {
        return p.join(localAppData, 'asset_opt', _version, 'bin');
      }
    }
    
    final home = Platform.environment['HOME'] ?? 
                 Platform.environment['USERPROFILE'] ?? 
                 Directory.systemTemp.path;
    return p.join(home, '.cache', 'asset_opt', _version, 'bin');
  }

  static Future<String?> _findSystemTool(String name) async {
    try {
      final result = await Process.run(
        Platform.isWindows ? 'where' : 'which',
        [name],
      );
      if (result.exitCode == 0) {
        final lines = const LineSplitter().convert(result.stdout as String);
        if (lines.isNotEmpty) {
          final toolPath = lines.first.trim();
          if (toolPath.isNotEmpty && await File(toolPath).exists()) {
            return toolPath;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Whether cwebp is available for WebP conversion.
  static bool get hasCwebp => _cwebpPath != null;

  /// Whether pngquant is available for PNG optimization.
  static bool get hasPngquant => _pngquantPath != null;

  /// Converts an image to WebP format.
  static Future<File?> toWebp(
    File input,
    String outputPath, {
    int quality = 80,
  }) async {
    if (_cwebpPath == null) return null;

    try {
      final result = await Process.run(
        _cwebpPath!,
        ['-q', quality.toString(), input.path, '-o', outputPath],
      );

      if (result.exitCode == 0 && await File(outputPath).exists()) {
        return File(outputPath);
      }
    } catch (_) {}
    return null;
  }

  /// Optimizes a PNG file using pngquant.
  static Future<File?> optimizePng(File input, String outputPath) async {
    if (_pngquantPath == null) return null;

    try {
      final result = await Process.run(
        _pngquantPath!,
        ['--force', '--output', outputPath, '--quality', '65-80', input.path],
      );

      if (result.exitCode == 0 && await File(outputPath).exists()) {
        return File(outputPath);
      }
    } catch (_) {}
    return null;
  }

  /// Returns a comma-separated list of available tools.
  static String get availableTools {
    final tools = <String>[];
    if (hasCwebp) tools.add('cwebp');
    if (hasPngquant) tools.add('pngquant');
    return tools.isEmpty ? 'none' : tools.join(', ');
  }
}
