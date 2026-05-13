class GestureCooldownHelper {
  final int cooldownMs;
  DateTime? _lastTriggerTime;

  GestureCooldownHelper({this.cooldownMs = 1000});

  /// Returns true if the cooldown period has passed since the last successful trigger.
  bool canTrigger() {
    if (_lastTriggerTime == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(_lastTriggerTime!).inMilliseconds;
    return difference >= cooldownMs;
  }

  /// Sets the last trigger time to now.
  void updateLastTrigger() {
    _lastTriggerTime = DateTime.now();
  }

  /// Reset the cooldown (e.g., when switching modes)
  void reset() {
    _lastTriggerTime = null;
  }
}
