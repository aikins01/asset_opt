import 'package:asset_opt/model/asset_detail.dart';

class Color {
  static String red(String text) => '\x1B[31m$text\x1B[0m';
  static String green(String text) => '\x1B[32m$text\x1B[0m';
  static String yellow(String text) => '\x1B[33m$text\x1B[0m';
  static String blue(String text) => '\x1B[34m$text\x1B[0m';
  static String magenta(String text) => '\x1B[35m$text\x1B[0m';
  static String cyan(String text) => '\x1B[36m$text\x1B[0m';
  static String white(String text) => '\x1B[37m$text\x1B[0m';
  static String bold(String text) => '\x1B[1m$text\x1B[0m';
  static String dim(String text) => '\x1B[2m$text\x1B[0m';

  static String gradient(String text) {
    final colors = ['\x1B[36m', '\x1B[34m', '\x1B[35m'];
    final result = StringBuffer();
    final charsPerColor = (text.length / colors.length).ceil();

    for (var i = 0; i < text.length; i++) {
      final colorIndex = (i / charsPerColor).floor();
      if (colorIndex < colors.length) {
        result.write('${colors[colorIndex]}${text[i]}');
      } else {
        result.write(text[i]);
      }
    }

    result.write('\x1B[0m');
    return result.toString();
  }
}

class DirStats {
  int totalSize = 0;
  int fileCount = 0;

  void addAsset(AssetDetail asset) {
    totalSize += asset.info.size;
    fileCount++;
  }
}
