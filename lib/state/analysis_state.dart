import 'package:asset_opt/model/analysis_result.dart';

import 'base_state.dart';

class AnalysisState extends BaseState {
  AnalysisResult? _lastAnalysis;
  bool _isAnalyzing = false;
  String? _error;
  String _currentTask = '';
  double _progress = 0.0;
  int _processedFiles = 0;
  int _totalFiles = 0;

  AnalysisResult? get lastAnalysis => _lastAnalysis;
  bool get isAnalyzing => _isAnalyzing;
  String? get error => _error;
  String get currentTask => _currentTask;
  double get progress => _progress;
  int get processedFiles => _processedFiles;
  int get totalFiles => _totalFiles;

  void startAnalysis() {
    _isAnalyzing = true;
    _error = null;
    _progress = 0.0;
    _currentTask = 'Starting analysis...';
    notifyListeners();
  }

  void updateProgress(String task, int processed, int total) {
    _currentTask = task;
    _processedFiles = processed;
    _totalFiles = total;
    _progress = total > 0 ? processed / total : 0.0;
    notifyListeners();
  }

  void setTask(String task) {
    _currentTask = task;
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
