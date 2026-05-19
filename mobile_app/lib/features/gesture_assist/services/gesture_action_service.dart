import 'package:flutter/material.dart';

import '../models/gesture_action_model.dart';

class GestureActionRegistration {
  final Object owner;
  final String screenContext;
  final GestureConfirmCallback? onConfirm;
  final GestureNextCallback? onNext;
  final GestureBackCallback? onBack;
  final ScrollController? scrollController;

  const GestureActionRegistration({
    required this.owner,
    required this.screenContext,
    this.onConfirm,
    this.onNext,
    this.onBack,
    this.scrollController,
  });
}

/// Service untuk execute gesture actions dengan aman.
///
/// Dibuat stack-based supaya callback halaman sebelumnya tidak ikut hilang
/// ketika halaman child dispose. Contoh:
/// Home -> JobDetail -> ApplyJob.
/// Saat ApplyJob dispose, callback JobDetail/Home tidak ikut di-clear global.
class GestureActionService {
  static final GestureActionService _instance =
      GestureActionService._internal();

  factory GestureActionService() {
    return _instance;
  }

  GestureActionService._internal();

  final List<GestureActionRegistration> _registrationStack =
      <GestureActionRegistration>[];

  static const double scrollOffset = 300.0;
  static const int scrollDurationMs = 500;

  GestureActionRegistration? get _activeRegistration {
    if (_registrationStack.isEmpty) return null;
    return _registrationStack.last;
  }

  String get activeScreenContext =>
      _activeRegistration?.screenContext ?? 'unknown';

  void registerPageActions({
    required Object owner,
    required String screenContext,
    GestureConfirmCallback? onConfirm,
    GestureNextCallback? onNext,
    GestureBackCallback? onBack,
    ScrollController? scrollController,
  }) {
    unregisterOwner(owner);

    _registrationStack.add(
      GestureActionRegistration(
        owner: owner,
        screenContext: screenContext,
        onConfirm: onConfirm,
        onNext: onNext,
        onBack: onBack,
        scrollController: scrollController,
      ),
    );

    debugPrint(
      '[GestureActionService] Registered $screenContext, stack=${_registrationStack.length}',
    );
    printRegisteredCallbacks();
  }

  void unregisterOwner(Object owner) {
    _registrationStack.removeWhere((item) => identical(item.owner, owner));
    debugPrint(
      '[GestureActionService] Unregistered owner, stack=${_registrationStack.length}',
    );
  }

  /// Compatibility helper untuk kode lama.
  /// Jika masih ada yang memanggil registerConfirmAction/registerNextAction
  /// langsung, action tetap masuk ke stack dengan owner service ini.
  void onConfirmAction(GestureConfirmCallback callback) {
    registerPageActions(
      owner: this,
      screenContext: activeScreenContext,
      onConfirm: callback,
      onNext: _activeRegistration?.onNext,
      onBack: _activeRegistration?.onBack,
      scrollController: _activeRegistration?.scrollController,
    );
  }

  void onNextAction(GestureNextCallback callback) {
    registerPageActions(
      owner: this,
      screenContext: activeScreenContext,
      onConfirm: _activeRegistration?.onConfirm,
      onNext: callback,
      onBack: _activeRegistration?.onBack,
      scrollController: _activeRegistration?.scrollController,
    );
  }

  void onBackAction(GestureBackCallback callback) {
    registerPageActions(
      owner: this,
      screenContext: activeScreenContext,
      onConfirm: _activeRegistration?.onConfirm,
      onNext: _activeRegistration?.onNext,
      onBack: callback,
      scrollController: _activeRegistration?.scrollController,
    );
  }

  void setScrollController(ScrollController controller) {
    registerPageActions(
      owner: this,
      screenContext: activeScreenContext,
      onConfirm: _activeRegistration?.onConfirm,
      onNext: _activeRegistration?.onNext,
      onBack: _activeRegistration?.onBack,
      scrollController: controller,
    );
  }

  void clearCallbacks() {
    _registrationStack.clear();
    debugPrint('[GestureActionService] Cleared all callbacks');
  }

  Future<GestureActionResult> executeConfirm() async {
    try {
      final registration = _activeRegistration;
      final callback = registration?.onConfirm;

      if (callback == null) {
        return GestureActionResult(
          type: GestureActionType.confirm,
          status: ActionStatus.skipped,
          message: 'Tidak ada aksi confirm pada halaman ini',
        );
      }

      final success = await callback();

      return GestureActionResult(
        type: GestureActionType.confirm,
        status: success ? ActionStatus.success : ActionStatus.failed,
        message: success ? 'Konfirmasi berhasil' : 'Konfirmasi gagal',
      );
    } catch (e) {
      return GestureActionResult(
        type: GestureActionType.confirm,
        status: ActionStatus.failed,
        message: 'Error confirm action: $e',
      );
    }
  }

  Future<GestureActionResult> executeNext() async {
    try {
      final registration = _activeRegistration;
      final callback = registration?.onNext;

      if (callback != null) {
        final success = await callback();

        return GestureActionResult(
          type: GestureActionType.next,
          status: success ? ActionStatus.success : ActionStatus.failed,
          message: success ? 'Lanjut berhasil' : 'Lanjut gagal',
        );
      }

      final scrollController = registration?.scrollController;

      if (scrollController != null && scrollController.hasClients) {
        final currentOffset = scrollController.offset;
        final maxOffset = scrollController.position.maxScrollExtent;

        if (currentOffset >= maxOffset) {
          return GestureActionResult(
            type: GestureActionType.next,
            status: ActionStatus.skipped,
            message: 'Sudah berada di bagian paling bawah',
          );
        }

        final nextOffset =
            (currentOffset + scrollOffset).clamp(0.0, maxOffset);

        await scrollController.animateTo(
          nextOffset,
          duration: const Duration(milliseconds: scrollDurationMs),
          curve: Curves.easeInOut,
        );

        return GestureActionResult(
          type: GestureActionType.next,
          status: ActionStatus.success,
          message: 'Scroll ke bawah',
          data: {'offset': nextOffset},
        );
      }

      return GestureActionResult(
        type: GestureActionType.next,
        status: ActionStatus.skipped,
        message: 'Tidak ada aksi next pada halaman ini',
      );
    } catch (e) {
      return GestureActionResult(
        type: GestureActionType.next,
        status: ActionStatus.failed,
        message: 'Error next action: $e',
      );
    }
  }

  Future<GestureActionResult> executeBack(BuildContext? context) async {
    try {
      final registration = _activeRegistration;
      final callback = registration?.onBack;

      if (callback != null) {
        final success = await callback();

        return GestureActionResult(
          type: GestureActionType.back,
          status: success ? ActionStatus.success : ActionStatus.failed,
          message: success ? 'Kembali berhasil' : 'Kembali gagal',
        );
      }

      if (context != null) {
        final popped = await Navigator.maybePop(context);

        return GestureActionResult(
          type: GestureActionType.back,
          status: popped ? ActionStatus.success : ActionStatus.skipped,
          message: popped
              ? 'Kembali'
              : 'Tidak ada halaman sebelumnya untuk kembali',
        );
      }

      return GestureActionResult(
        type: GestureActionType.back,
        status: ActionStatus.skipped,
        message: 'Tidak ada aksi back pada halaman ini',
      );
    } catch (e) {
      return GestureActionResult(
        type: GestureActionType.back,
        status: ActionStatus.failed,
        message: 'Error back action: $e',
      );
    }
  }

  bool canExecuteAction(GestureActionType type, {bool hasContext = false}) {
    final registration = _activeRegistration;

    switch (type) {
      case GestureActionType.confirm:
        return registration?.onConfirm != null;
      case GestureActionType.next:
        return registration?.onNext != null ||
            (registration?.scrollController != null &&
                registration!.scrollController!.hasClients);
      case GestureActionType.back:
        return registration?.onBack != null || hasContext;
      case GestureActionType.unknown:
        return false;
    }
  }

  void printRegisteredCallbacks() {
    final registration = _activeRegistration;

    debugPrint('[GestureActionService] === Active Registration ===');
    debugPrint('[GestureActionService] Stack: ${_registrationStack.length}');
    debugPrint(
      '[GestureActionService] Screen: ${registration?.screenContext ?? 'none'}',
    );
    debugPrint(
      '[GestureActionService] Confirm: ${registration?.onConfirm != null}',
    );
    debugPrint('[GestureActionService] Next: ${registration?.onNext != null}');
    debugPrint('[GestureActionService] Back: ${registration?.onBack != null}');
    debugPrint(
      '[GestureActionService] ScrollController: ${registration?.scrollController != null}',
    );
    debugPrint('[GestureActionService] ===========================');
  }
}
