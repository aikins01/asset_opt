# asset_opt

A CLI tool for analyzing and optimizing Flutter/Dart project assets. Provides detailed analysis, actionable recommendations, and automatic image optimization.

![Repo Card](https://raw.githubusercontent.com/aikins01/asset_opt/master/.github/assets/asset_opt_repocard.png)

## Features

### Analysis

- Size and type distribution visualization
- Directory structure breakdown
- Image dimension analysis
- Unused asset detection
- Issue detection with recommendations

### Optimization

- Automatic image compression (JPEG, PNG, WebP)
- Format conversion (PNG -> WebP for non-alpha images)
- SVG minification (~70% reduction typical)
- Safe backups before any modification

### Cross-Platform

- Zero-setup native compression via bundled binaries
- Supports macOS (arm64/x64), Linux (x64/arm64), Windows (x64)

## Installation

```bash
dart pub global activate asset_opt
```

Or add to your project's dev dependencies:

```yaml
dev_dependencies:
    asset_opt: ^1.0.4
```

## Usage

### Command Line

```bash
# Show help
asset_opt --help

# Analyze assets
asset_opt --analyze

# Analyze and optimize
asset_opt --optimize

# Specify project path and quality
asset_opt -p /path/to/project -q 85 --optimize

# Create default config file
asset_opt --init

# Use optimization preset
asset_opt --optimize --preset thumbnails

# Verbose output
asset_opt --verbose

# Disable colors (for CI/redirected output)
asset_opt --no-color
```

### As a Library

```dart
import 'package:asset_opt/asset_opt.dart';

void main() async {
  final fileService = FileService();
  final imageService = ImageService();
  final analysisState = AnalysisState();

  final analyzer = AnalyzeCommand(
    fileService,
    imageService,
    analysisState,
  );

  final analysis = await analyzer.execute('./');

  if (analysis.hasIssues()) {
    for (final asset in analysis.assets) {
      for (final issue in asset.issues) {
        print('${asset.info.name}: ${issue.message}');
      }
    }
  }
}
```

## Output

### Analysis Report

```
📊 Asset Analysis Report
────────────────────────
Project: /Users/username/projects/my_app
────────────────────────
└─ assets (632 files, 22.4 MB)
   ├─ images (631 files, 22.4 MB)
   │  ├─ flags (492 files, 3.7 MB)
   │  └─ bgs (4 files, 2.5 MB)
   └─ icons (1 files, 829 B)
```

### Type Distribution

```
Type     Size       Files   Distribution
PNG      22.4 MB    631    │████████████████████████████  │ 65.2%
JPEG     10.2 MB    492    │████████████████              │ 29.8%
WEBP      1.5 MB      4    │███                           │  4.3%
SVG     829.0 B       1    │                              │  0.7%
```

## Configuration

Create `asset_opt.yaml` in your project root, or run `asset_opt --init`:

```yaml
optimization:
    jpeg_quality: 85
    webp_quality: 80
    strip_metadata: true
    convert_png_to_webp: true

limits:
    max_file_size: 1MB
    max_dimensions: 2000

presets:
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
    - "**/test/assets/*"
    - "**/fixtures/*"
```

## FAQ

**Is it safe to use on production assets?**  
Yes. The tool creates backups before any optimization.

**Should I commit the generated reports?**  
No. Add `asset_opt_reports/` to your `.gitignore`.

**What formats are supported?**  
PNG, JPEG, WebP, and SVG.

**Does it work with CI/CD?**  
Yes. Use `--no-color` for cleaner logs.

## Contributing

Contributions welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE)
