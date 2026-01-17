# Changelog

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
