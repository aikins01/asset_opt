import 'terminal_colors.dart';

class ProgressView {
  static const _barWidth = 40;

  String formatProgress(String task, double progress,
      [int? current, int? total]) {
    final percentage = (progress * 100).toStringAsFixed(1);
    final completedWidth = (progress * _barWidth).round();

    final bar = [
      Color.dim('│'),
      Color.cyan('█' * completedWidth),
      Color.dim(' ' * (_barWidth - completedWidth)),
      Color.dim('│'),
    ].join('');

    final count =
        current != null && total != null ? Color.dim(' ($current/$total)') : '';

    return '\r${task.padRight(30)} $bar ${Color.yellow('$percentage%')}$count';
  }
}
