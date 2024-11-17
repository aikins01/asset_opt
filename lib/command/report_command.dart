import 'package:asset_opt/model/analysis_result.dart';
import 'package:asset_opt/model/optimization_result.dart';
import 'package:asset_opt/service/report_service.dart';
import 'package:asset_opt/state/report_state.dart';

class ReportCommand {
  final ReportService _reportService;
  final ReportState _state;

  ReportCommand(this._reportService, this._state);

  Future<void> execute(
    AnalysisResult analysis,
    List<OptimizationResult> optimizations,
    String outputPath,
  ) async {
    try {
      _state.startReporting();

      // Generate and save analysis report
      await _reportService.saveAnalysisReport(
        analysis,
        '$outputPath/analysis_report.json',
      );

      // Generate and save optimization report
      if (optimizations.isNotEmpty) {
        await _reportService.saveOptimizationReport(
          optimizations,
          '$outputPath/optimization_report.json',
        );
      }

      _state.completeReporting();
    } catch (e) {
      _state.failReporting(e.toString());
      rethrow;
    }
  }
}
