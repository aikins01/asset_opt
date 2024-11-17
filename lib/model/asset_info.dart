import 'package:path/path.dart' as path_util;
import 'image_info.dart';

class AssetInfo {
  final String name;
  final String path;
  final int size;
  final String type;
  final DateTime lastModified;
  final ImageInfo? imageInfo;

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
