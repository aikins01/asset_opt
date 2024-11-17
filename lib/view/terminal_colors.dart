import 'package:asset_opt/model/asset_detail.dart';

class Color {
  // Basic colors
  static String red(String text) => '\x1B[31m$text\x1B[0m';
  static String green(String text) => '\x1B[32m$text\x1B[0m';
  static String yellow(String text) => '\x1B[33m$text\x1B[0m';
  static String blue(String text) => '\x1B[34m$text\x1B[0m';
  static String magenta(String text) => '\x1B[35m$text\x1B[0m';
  static String cyan(String text) => '\x1B[36m$text\x1B[0m';
  static String white(String text) => '\x1B[37m$text\x1B[0m';

  // Text styles
  static String bold(String text) => '\x1B[1m$text\x1B[0m';
  static String dim(String text) => '\x1B[2m$text\x1B[0m';
  static String italic(String text) => '\x1B[3m$text\x1B[0m';
  static String underline(String text) => '\x1B[4m$text\x1B[0m';

  // Background colors
  static String bgRed(String text) => '\x1B[41m$text\x1B[0m';
  static String bgGreen(String text) => '\x1B[42m$text\x1B[0m';
  static String bgYellow(String text) => '\x1B[43m$text\x1B[0m';
  static String bgBlue(String text) => '\x1B[44m$text\x1B[0m';
  static String bgMagenta(String text) => '\x1B[45m$text\x1B[0m';
  static String bgCyan(String text) => '\x1B[46m$text\x1B[0m';
  static String bgWhite(String text) => '\x1B[47m$text\x1B[0m';

  // Bright colors
  static String brightRed(String text) => '\x1B[91m$text\x1B[0m';
  static String brightGreen(String text) => '\x1B[92m$text\x1B[0m';
  static String brightYellow(String text) => '\x1B[93m$text\x1B[0m';
  static String brightBlue(String text) => '\x1B[94m$text\x1B[0m';
  static String brightMagenta(String text) => '\x1B[95m$text\x1B[0m';
  static String brightCyan(String text) => '\x1B[96m$text\x1B[0m';
  static String brightWhite(String text) => '\x1B[97m$text\x1B[0m';

  // Gradient effect (for progress bars)
  static String gradient(String text) {
    final colors = [
      '\x1B[36m', // cyan
      '\x1B[34m', // blue
      '\x1B[35m', // magenta
    ];

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

  static String combine(String text, List<String> codes) {
    return codes.join() + text + '\x1B[0m' * codes.length;
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
