import 'package:path/path.dart' as path_util;
import 'image_info.dart';

/// Basic information about an asset file.
class AssetInfo {
  /// The file name (e.g., "logo.png").
  final String name;

  /// The absolute file path.
  final String path;

  /// File size in bytes.
  final int size;

  /// File type/extension without dot (e.g., "png", "jpg").
  final String type;

  /// When the file was last modified.
  final DateTime lastModified;

  /// Image-specific metadata, if available.
  final ImageInfo? imageInfo;

  /// Creates an asset info instance.
  AssetInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.type,
    required this.lastModified,
    this.imageInfo,
  });

  String get directory => path_util.dirname(path);
  String get extension => path_util.extension(path);

  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
        'size': size,
        'type': type,
        'lastModified': lastModified.toIso8601String(),
        'imageInfo': imageInfo != null
            ? {
                'width': imageInfo!.width,
                'height': imageInfo!.height,
                'format': imageInfo!.format,
                'hasAlpha': imageInfo!.hasAlpha,
              }
            : null,
      };

  factory AssetInfo.fromJson(Map<String, dynamic> json) => AssetInfo(
        name: json['name'],
        path: json['path'],
        size: json['size'],
        type: json['type'],
        lastModified: DateTime.parse(json['lastModified']),
        imageInfo: json['imageInfo'] != null
            ? ImageInfo(
                width: json['imageInfo']['width'],
                height: json['imageInfo']['height'],
                format: json['imageInfo']['format'],
                hasAlpha: json['imageInfo']['hasAlpha'],
              )
            : null,
      );
}
