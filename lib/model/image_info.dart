class ImageInfo {
  final int width;
  final int height;
  final String format;
  final bool hasAlpha;
  final Map<String, dynamic>? metadata;

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
