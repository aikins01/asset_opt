import 'package:asset_opt/model/analysis_result.dart';

import 'base_state.dart';

class AnalysisState extends BaseState {
  AnalysisResult? _lastAnalysis;
  bool _isAnalyzing = false;
  String? _error;

  AnalysisResult? get lastAnalysis => _lastAnalysis;
  bool get isAnalyzing => _isAnalyzing;
  String? get error => _error;

  void startAnalysis() {
    _isAnalyzing = true;
    _error = null;
    notifyListeners();
  }

  void completeAnalysis(AnalysisResult result) {
    _lastAnalysis = result;
    _isAnalyzing = false;
    _error = null;
    notifyListeners();
  }

  void failAnalysis(String error) {
    _isAnalyzing = false;
    _error = error;
    notifyListeners();
  }
}
