class AssetInfo {
  final String name;
  final String path;
  final int size;
  final String type;
  final DateTime lastModified;

  AssetInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.type,
    required this.lastModified,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
        'size': size,
        'type': type,
        'lastModified': lastModified.toIso8601String(),
      };

  factory AssetInfo.fromJson(Map<String, dynamic> json) => AssetInfo(
        name: json['name'],
        path: json['path'],
        size: json['size'],
        type: json['type'],
        lastModified: DateTime.parse(json['lastModified']),
      );
}
