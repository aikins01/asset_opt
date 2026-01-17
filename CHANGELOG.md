# Changelog

## 1.0.4

### New features
- **Asset usage analysis**: Detect unused assets by scanning Dart code for references in lib/ and bin/
- **Bundled cwebp binaries**: Zero-setup WebP conversion with bundled cwebp 1.6.0 for all platforms (macos-arm64, macos-x64, linux-x64, linux-arm64, windows-x64)
- **SVG optimization**: Pure Dart SVG minification (~70% reduction) - removes comments, metadata, editor data, empty containers, hidden elements, shortens numbers
- **PNG to WebP conversion**: Automatic conversion for PNGs without alpha channel using native cwebp
- **Configuration file support**: Load settings from `asset_opt.yaml` with `--init` flag to create default config
- **Custom optimization presets**: Define presets for thumbnails, backgrounds, icons, etc.

### Improvements
- Added `--preset` flag to use optimization presets from config file
- **Batch concurrency**: Asset analysis and usage scanning now process files in parallel batches of 8 for faster analysis on large projects
- **Versioned cache paths**: Native binaries now cache to version-specific directories to prevent conflicts on upgrades
- **Runtime tool validation**: Native tools are validated by executing `--version` before use, catching "exists but not executable" issues
- **Config error reporting**: Invalid config files now show warning messages instead of silently using defaults
- **Safe config init**: `--init` no longer overwrites existing config files
- Analysis now gracefully handles corrupt/unreadable images instead of aborting
- Fixed directory tree display on Windows (use platform-aware path handling)
- Improved system tool discovery on Windows (proper line ending handling)
- Native binary validation before execution (size check on cached files)

### Bug fixes
- Fixed CLI crash when invalid arguments passed
- Fixed NaN% display when 0 files optimized
- Fixed directory structure showing full absolute paths instead of project-relative
- Fixed NativeOptimizer initialization order (set initialized after successful init)
- Fixed SVG optimization path (check extension before raster decode)
- Fixed WebP optimization attempting to re-encode already-WebP files
- Fixed progress reporting division by zero with empty asset list
- Fixed bundled binary discovery for globally activated packages (use Isolate.resolvePackageUri)
- Fixed cache directory on Windows (use LOCALAPPDATA)
- Fixed report command creating directories instead of files

## 1.0.3

- Updated Dart SDK constraint to ^3.10.0
- Updated lints to ^6.0.0
- Updated dependencies (image 4.7.2, args 2.7.0, yaml 3.1.3)
- Fixed lint warnings for unused variables and string interpolation

### Cross-platform improvements
- **Fixed Windows crash** (issue #1): RangeError in directory stats due to hardcoded `/` separators
- Added ANSI color support detection (graceful fallback on Windows)
- Added `--no-color` flag for CI/redirected output
- Fixed path separators to use `path.join()` and `path.dirname()` throughout
- Moved cache to `.dart_tool/asset_opt/cache.json`
- Normalized file paths in cache for consistent cross-platform behavior
- Fixed symlink loop prevention in directory scanning

### Testing
- Added 120 comprehensive tests covering all services, commands, and models

## 1.0.2

Initial release with the following features:

- 📊 Asset Analysis
  - Size and dimension analysis
  - Format detection
  - Issue identification
  - Directory structure visualization

- 🗜️ Optimization Features
  - JPEG compression
  - PNG optimization
  - Size reduction
  - Format recommendations

- 📈 Reporting
  - Detailed terminal output
  - Progress tracking
  - JSON report generation
  - Size statistics

## 1.0.0

- Initial version
