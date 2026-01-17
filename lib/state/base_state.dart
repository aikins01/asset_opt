/// Listener for state changes.
abstract class StateListener {
  /// Called when the state changes.
  void onStateChanged();
}

/// Base class for observable state management.
class BaseState {
  final List<StateListener> _listeners = [];

  /// Registers a listener for state changes.
  void addListener(StateListener listener) {
    _listeners.add(listener);
  }

  /// Removes a previously registered listener.
  void removeListener(StateListener listener) {
    _listeners.remove(listener);
  }

  /// Notifies all listeners of a state change.
  void notifyListeners() {
    for (final listener in _listeners) {
      listener.onStateChanged();
    }
  }
}
