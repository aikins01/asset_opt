import 'dart:io';

import 'package:asset_opt/state/analysis_state.dart';
import 'package:asset_opt/state/base_state.dart';

import 'progress_view.dart';

class AnalysisProgressListener implements StateListener {
  final ProgressView _view;
  final AnalysisState _state;

  AnalysisProgressListener(this._state, this._view);

  @override
  void onStateChanged() {
    if (_state.isAnalyzing) {
      stdout.write(_view.formatProgress(
        _state.currentTask,
        _state.progress,
        _state.processedFiles,
        _state.totalFiles,
      ));
    }
  }
}
