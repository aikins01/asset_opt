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
    String outputDir,
    String reportName,
  ) async {
    try {
      _state.startReporting();

      await _reportService.saveAnalysisReport(
        analysis,
        '$outputDir/${reportName}_analysis.json',
      );

      if (optimizations.isNotEmpty) {
        await _reportService.saveOptimizationReport(
          optimizations,
          '$outputDir/${reportName}_optimization.json',
        );
      }

      _state.completeReporting();
    } catch (e) {
      _state.failReporting(e.toString());
      rethrow;
    }
  }
}
