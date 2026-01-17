import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:asset_opt/model/optimization_config.dart';

/// Result of loading a configuration file.
class ConfigLoadResult {
  /// The loaded configuration, if successful.
  final AssetOptConfig? config;

  /// Error message if loading failed.
  final String? error;

  /// Creates a successful result.
  ConfigLoadResult.success(this.config) : error = null;

  /// Creates a failed result.
  ConfigLoadResult.error(this.error) : config = null;

  /// Creates a result when config file doesn't exist.
  ConfigLoadResult.notFound() : config = null, error = null;

  /// True if an error occurred.
  bool get hasError => error != null;

  /// True if config was loaded.
  bool get hasConfig => config != null;
}

/// Service for loading and managing asset_opt.yaml configuration.
class ConfigService {
  static const _configFileName = 'asset_opt.yaml';

  /// Loads configuration from asset_opt.yaml in the project root.
  Future<ConfigLoadResult> loadConfig(String projectPath) async {
    final configFile = File(p.join(projectPath, _configFileName));
    if (!await configFile.exists()) {
      return ConfigLoadResult.notFound();
    }

    try {
      final content = await configFile.readAsString();
      final yaml = loadYaml(content) as YamlMap?;
      if (yaml == null) {
        return ConfigLoadResult.error('Config file is empty or invalid YAML');
      }

      return ConfigLoadResult.success(AssetOptConfig.fromYaml(yaml));
    } catch (e) {
      return ConfigLoadResult.error('Failed to parse config: $e');
    }
  }

  /// Creates a default asset_opt.yaml config file.
  ///
  /// Returns true if created, false if file already exists (unless [force]).
  Future<bool> createDefaultConfig(String projectPath, {bool force = false}) async {
    final configFile = File(p.join(projectPath, _configFileName));
    if (await configFile.exists() && !force) {
      return false;
    }
    await configFile.writeAsString(_defaultConfig);
    return true;
  }

  static const _defaultConfig = '''
# asset_opt configuration
# https://github.com/aikins01/asset_opt

optimization:
  jpeg_quality: 85
  webp_quality: 80
  strip_metadata: true
  convert_png_to_webp: true  # Convert PNGs without alpha to WebP

limits:
  max_file_size: 1MB
  max_dimensions: 2000

presets:
  # Custom presets for different asset types
  thumbnails:
    max_dimensions: 200
    jpeg_quality: 75
  backgrounds:
    max_dimensions: 1920
    jpeg_quality: 90
  icons:
    max_dimensions: 512
    jpeg_quality: 85

exclude:
  - '**/test/assets/*'
  - '**/fixtures/*'
''';
}

/// Parsed configuration from asset_opt.yaml.
class AssetOptConfig {
  /// Image optimization settings.
  final OptimizationSettings optimization;

  /// Size and dimension limits.
  final LimitSettings limits;

  /// Named optimization presets.
  final Map<String, PresetSettings> presets;

  /// Glob patterns for files to exclude.
  final List<String> exclude;

  /// Creates a configuration.
  AssetOptConfig({
    required this.optimization,
    required this.limits,
    this.presets = const {},
    this.exclude = const [],
  });

  factory AssetOptConfig.fromYaml(YamlMap yaml) {
    return AssetOptConfig(
      optimization: OptimizationSettings.fromYaml(
        yaml['optimization'] as YamlMap? ?? YamlMap(),
      ),
      limits: LimitSettings.fromYaml(
        yaml['limits'] as YamlMap? ?? YamlMap(),
      ),
      presets: _parsePresets(yaml['presets'] as YamlMap?),
      exclude: _parseStringList(yaml['exclude']),
    );
  }

  static Map<String, PresetSettings> _parsePresets(YamlMap? yaml) {
    if (yaml == null) return {};
    final presets = <String, PresetSettings>{};
    for (final entry in yaml.entries) {
      final name = entry.key as String;
      final value = entry.value as YamlMap?;
      if (value != null) {
        presets[name] = PresetSettings.fromYaml(value);
      }
    }
    return presets;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is YamlList) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Converts to an [OptimizationConfig] for use in optimization.
  OptimizationConfig toOptimizationConfig({String? presetName}) {
    final preset = presetName != null ? presets[presetName] : null;
    
    return OptimizationConfig(
      jpegQuality: preset?.jpegQuality ?? optimization.jpegQuality,
      webpQuality: preset?.webpQuality ?? optimization.webpQuality,
      convertToWebp: optimization.convertPngToWebp,
      stripMetadata: optimization.stripMetadata,
      resize: preset?.maxDimensions != null
          ? ImageResize(
              width: preset!.maxDimensions!,
              height: preset.maxDimensions!,
            )
          : null,
    );
  }
}

class OptimizationSettings {
  final int jpegQuality;
  final int webpQuality;
  final bool stripMetadata;
  final bool convertPngToWebp;

  OptimizationSettings({
    this.jpegQuality = 85,
    this.webpQuality = 80,
    this.stripMetadata = true,
    this.convertPngToWebp = true,
  });

  factory OptimizationSettings.fromYaml(YamlMap yaml) {
    return OptimizationSettings(
      jpegQuality: yaml['jpeg_quality'] as int? ?? 85,
      webpQuality: yaml['webp_quality'] as int? ?? 80,
      stripMetadata: yaml['strip_metadata'] as bool? ?? true,
      convertPngToWebp: yaml['convert_png_to_webp'] as bool? ?? true,
    );
  }
}

class LimitSettings {
  final int maxFileSize;
  final int maxDimensions;

  LimitSettings({
    this.maxFileSize = 1024 * 1024,
    this.maxDimensions = 2000,
  });

  factory LimitSettings.fromYaml(YamlMap yaml) {
    return LimitSettings(
      maxFileSize: _parseSize(yaml['max_file_size']),
      maxDimensions: yaml['max_dimensions'] as int? ?? 2000,
    );
  }

  static int _parseSize(dynamic value) {
    if (value == null) return 1024 * 1024;
    if (value is int) return value;
    if (value is String) {
      final match = RegExp(r'^(\d+)\s*(KB|MB|GB)?$', caseSensitive: false)
          .firstMatch(value.trim());
      if (match != null) {
        final num = int.parse(match.group(1)!);
        final unit = match.group(2)?.toUpperCase() ?? 'B';
        switch (unit) {
          case 'KB':
            return num * 1024;
          case 'MB':
            return num * 1024 * 1024;
          case 'GB':
            return num * 1024 * 1024 * 1024;
          default:
            return num;
        }
      }
    }
    return 1024 * 1024;
  }
}

class PresetSettings {
  final int? maxDimensions;
  final int? jpegQuality;
  final int? webpQuality;

  PresetSettings({
    this.maxDimensions,
    this.jpegQuality,
    this.webpQuality,
  });

  factory PresetSettings.fromYaml(YamlMap yaml) {
    return PresetSettings(
      maxDimensions: yaml['max_dimensions'] as int?,
      jpegQuality: yaml['jpeg_quality'] as int?,
      webpQuality: yaml['webp_quality'] as int?,
    );
  }
}
