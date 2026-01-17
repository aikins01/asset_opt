/// Image-specific metadata extracted from an asset file.
class ImageInfo {
  /// Image width in pixels.
  final int width;

  /// Image height in pixels.
  final int height;

  /// Image format (e.g., "png", "jpeg", "webp").
  final String format;

  /// Whether the image has an alpha/transparency channel.
  final bool hasAlpha;

  /// Additional metadata (EXIF, etc.), if extracted.
  final Map<String, dynamic>? metadata;

  /// Creates an image info instance.
  ImageInfo({
    required this.width,
    required this.height,
    required this.format,
    required this.hasAlpha,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'format': format,
        'hasAlpha': hasAlpha,
        'metadata': metadata,
      };

  factory ImageInfo.fromJson(Map<String, dynamic> json) => ImageInfo(
        width: json['width'],
        height: json['height'],
        format: json['format'],
        hasAlpha: json['hasAlpha'],
        metadata: json['metadata'],
      );
}
