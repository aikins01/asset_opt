abstract class StateListener {
  void onStateChanged();
}

class BaseState {
  final List<StateListener> _listeners = [];

  void addListener(StateListener listener) {
    _listeners.add(listener);
  }

  void removeListener(StateListener listener) {
    _listeners.remove(listener);
  }

  void notifyListeners() {
    for (final listener in _listeners) {
      listener.onStateChanged();
    }
  }
}
