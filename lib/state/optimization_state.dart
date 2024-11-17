import 'package:asset_opt/model/optimization_result.dart';

import 'base_state.dart';

class OptimizationState extends BaseState {
  List<OptimizationResult> _results = [];
  Map<String, String> _errors = {};
  bool _isOptimizing = false;
  double _progress = 0.0;
  String? _error;

  List<OptimizationResult> get results => List.unmodifiable(_results);
  Map<String, String> get errors => Map.unmodifiable(_errors);
  bool get isOptimizing => _isOptimizing;
  double get progress => _progress;
  String? get error => _error;

  void startOptimization() {
    _isOptimizing = true;
    _progress = 0.0;
    _results = [];
    _errors = {};
    _error = null;
    notifyListeners();
  }

  void updateProgress(double progress) {
    _progress = progress;
    notifyListeners();
  }

  void addResult(OptimizationResult result) {
    _results.add(result);
    notifyListeners();
  }

  void addError(String path, String error) {
    _errors[path] = error;
    notifyListeners();
  }

  void completeOptimization() {
    _isOptimizing = false;
    _progress = 1.0;
    notifyListeners();
  }

  void failOptimization(String error) {
    _isOptimizing = false;
    _error = error;
    notifyListeners();
  }
}
