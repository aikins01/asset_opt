# Contributing

Thanks for your interest in contributing to asset_opt! Here's everything you need to know to get started.

## Development

### Prerequisites

- Dart SDK >=2.19.0 <4.0.0
- Flutter (optional, for testing with Flutter projects)
- Git

### Setup

1. Fork and clone the repo
   ```bash
   git clone https://github.com/your-username/asset_opt.git
   cd asset_opt
   ```

2. Install dependencies
   ```bash
   dart pub get
   ```

3. Run tests
   ```bash
   dart test
   ```

### Project Structure

```
├── bin/
│   └── asset_opt.dart          # CLI entry point
│
├── lib/
│   ├── commands/               # CLI commands
│   ├── models/                 # Data models
│   ├── services/              # Core services
│   ├── state/                 # State management
│   ├── views/                 # Terminal UI
│   └── asset_opt.dart         # Public API
│
├── test/
│   ├── commands/
│   ├── models/
│   └── services/
│
├── example/
│   └── main.dart
│
└── tool/                      # Development scripts
```


## Making Changes

### Branch Naming

- Features: `feature/description`
- Fixes: `fix/description`
- Documentation: `docs/description`

### Commit Style

We follow conventional commits:

```bash
feat: add WebP conversion support
fix: correct progress bar calculation
docs: update CLI usage examples
```

### Code Style

- Run formatter before committing:
  ```bash
  dart format .
  ```
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Maintain existing patterns in the codebase

## Testing

Please add tests for any new functionality:

```dart
void main() {
  group('AssetAnalyzer', () {
    test('should detect large images', () {
      // Your test here
    });
  });
}
```

## Documentation

- Add dartdoc comments for public APIs
- Update README.md if adding new features
- Include example usage in doc comments

## Pull Requests

1. Update your fork
2. Create a feature branch
3. Make your changes
4. Run tests
5. Create PR with description:
   ```markdown
   ## Changes
   - Added WebP support
   - Improved progress reporting

   ## Screenshots
   [If applicable]

   ## Testing
   1. Run `dart pub get`
   2. Run `dart test`
   ```

## Getting Help

- Open an issue for bugs
- Discussions for questions
- Check existing PRs for context

## First Time?

Look for issues labeled `good first issue` or `help wanted`.

### Good First Tasks

- Add new optimization recommendations
- Improve error messages
- Add tests for existing features
- Update documentation

---

By contributing, you agree to the [MIT License](LICENSE) terms.
