class CacheEntry {
  final String path;
  final int size;
  final DateTime modified;
  final DateTime optimizedAt;

  CacheEntry({
    required this.path,
    required this.size,
    required this.modified,
    required this.optimizedAt,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'size': size,
        'modified': modified.toIso8601String(),
        'optimizedAt': optimizedAt.toIso8601String(),
      };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
        path: json['path'],
        size: json['size'],
        modified: DateTime.parse(json['modified']),
        optimizedAt: DateTime.parse(json['optimizedAt']),
      );
}
