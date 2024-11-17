class OptimizationConfig {
  final int jpegQuality;
  final int webpQuality;
  final ImageResize? resize;
  final bool convertToWebp;
  final bool stripMetadata;

  OptimizationConfig({
    this.jpegQuality = 85,
    this.webpQuality = 80,
    this.resize,
    this.convertToWebp = false,
    this.stripMetadata = true,
  });
}

class ImageResize {
  final int width;
  final int height;

  ImageResize({
    required this.width,
    required this.height,
  });
}
