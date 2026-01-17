import 'dart:io';
import 'package:asset_opt/model/asset_detail.dart';

class Color {
  static bool enabled = stdout.supportsAnsiEscapes;

  static String _wrap(String text, String code) =>
      enabled ? '$code$text\x1B[0m' : text;

  static String red(String text) => _wrap(text, '\x1B[31m');
  static String green(String text) => _wrap(text, '\x1B[32m');
  static String yellow(String text) => _wrap(text, '\x1B[33m');
  static String blue(String text) => _wrap(text, '\x1B[34m');
  static String magenta(String text) => _wrap(text, '\x1B[35m');
  static String cyan(String text) => _wrap(text, '\x1B[36m');
  static String white(String text) => _wrap(text, '\x1B[37m');

  static String bold(String text) => _wrap(text, '\x1B[1m');
  static String dim(String text) => _wrap(text, '\x1B[2m');
  static String italic(String text) => _wrap(text, '\x1B[3m');
  static String underline(String text) => _wrap(text, '\x1B[4m');

  static String bgRed(String text) => _wrap(text, '\x1B[41m');
  static String bgGreen(String text) => _wrap(text, '\x1B[42m');
  static String bgYellow(String text) => _wrap(text, '\x1B[43m');
  static String bgBlue(String text) => _wrap(text, '\x1B[44m');
  static String bgMagenta(String text) => _wrap(text, '\x1B[45m');
  static String bgCyan(String text) => _wrap(text, '\x1B[46m');
  static String bgWhite(String text) => _wrap(text, '\x1B[47m');

  static String brightRed(String text) => _wrap(text, '\x1B[91m');
  static String brightGreen(String text) => _wrap(text, '\x1B[92m');
  static String brightYellow(String text) => _wrap(text, '\x1B[93m');
  static String brightBlue(String text) => _wrap(text, '\x1B[94m');
  static String brightMagenta(String text) => _wrap(text, '\x1B[95m');
  static String brightCyan(String text) => _wrap(text, '\x1B[96m');
  static String brightWhite(String text) => _wrap(text, '\x1B[97m');

  static String gradient(String text) {
    if (!enabled) return text;

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
    if (!enabled) return text;
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
