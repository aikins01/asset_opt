/// Configuration for image optimization operations.
class OptimizationConfig {
  /// JPEG output quality (1-100).
  final int jpegQuality;

  /// WebP output quality (1-100).
  final int webpQuality;

  /// Target dimensions for resizing, if any.
  final ImageResize? resize;

  /// Convert images to WebP format.
  final bool convertToWebp;

  /// Convert PNGs without alpha to JPEG.
  final bool convertToJpeg;

  /// Remove metadata (EXIF, etc.) from images.
  final bool stripMetadata;

  /// Creates an optimization config with defaults.
  OptimizationConfig({
    this.jpegQuality = 85,
    this.webpQuality = 80,
    this.resize,
    this.convertToWebp = false,
    this.convertToJpeg = true,
    this.stripMetadata = true,
  });
}

/// Target dimensions for image resizing.
class ImageResize {
  /// Target width in pixels.
  final int width;

  /// Target height in pixels.
  final int height;

  /// Creates resize dimensions.
  ImageResize({
    required this.width,
    required this.height,
  });
}
