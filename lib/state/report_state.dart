import 'base_state.dart';

class ReportState extends BaseState {
  bool _isReporting = false;
  String? _error;

  bool get isReporting => _isReporting;
  String? get error => _error;

  void startReporting() {
    _isReporting = true;
    _error = null;
    notifyListeners();
  }

  void completeReporting() {
    _isReporting = false;
    notifyListeners();
  }

  void failReporting(String error) {
    _isReporting = false;
    _error = error;
    notifyListeners();
  }
}
