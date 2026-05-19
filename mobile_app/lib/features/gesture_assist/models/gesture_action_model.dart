/// Model untuk gesture action yang akan dijalankan
enum GestureActionType {
  next, // Open Palm → navigate next / scroll down
  back, // Fist → navigate back
  confirm, // Thumbs Up → confirm action
  unknown,
}

enum ActionStatus {
  success,
  failed,
  skipped, // e.g., gesture mode off / no registered action
  notReady, // confidence/stability/cooldown not met
}

/// Result dari gesture action execution
class GestureActionResult {
  final GestureActionType type;
  final ActionStatus status;
  final String? message;
  final dynamic data;
  final DateTime timestamp;

  GestureActionResult({
    required this.type,
    required this.status,
    this.message,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isSuccess => status == ActionStatus.success;
  bool get isFailed => status == ActionStatus.failed;
  bool get isSkipped => status == ActionStatus.skipped;
  bool get isNotReady => status == ActionStatus.notReady;

  @override
  String toString() {
    return 'GestureActionResult(type: $type, status: $status, message: $message)';
  }
}

/// Callback untuk halaman yang ingin handle gesture action.
/// Return true jika action berhasil, false jika gagal / tidak bisa dijalankan.
typedef GestureConfirmCallback = Future<bool> Function();
typedef GestureNextCallback = Future<bool> Function();
typedef GestureBackCallback = Future<bool> Function();