import 'package:flutter/material.dart';

import '../models/gesture_action_model.dart';

/// Service untuk execute gesture actions dengan aman.
/// Halaman cukup register callback sesuai kebutuhan:
/// - Confirm: Thumbs Up
/// - Next: Open Palm
/// - Back: Fist
class GestureActionService {
  static final GestureActionService _instance =
      GestureActionService._internal();

  factory GestureActionService() {
    return _instance;
  }

  GestureActionService._internal();

  GestureConfirmCallback? _onConfirm;
  GestureNextCallback? _onNext;
  GestureBackCallback? _onBack;

  ScrollController? _scrollController;

  static const double scrollOffset = 300.0;
  static const int scrollDurationMs = 500;

  /// Register callback untuk CONFIRM action.
  void onConfirmAction(GestureConfirmCallback callback) {
    _onConfirm = callback;
  }

  /// Register callback untuk NEXT action.
  void onNextAction(GestureNextCallback callback) {
    _onNext = callback;
  }

  /// Register callback untuk BACK action.
  void onBackAction(GestureBackCallback callback) {
    _onBack = callback;
  }

  /// Register scroll controller untuk fallback NEXT action.
  void setScrollController(ScrollController controller) {
    _scrollController = controller;
  }

  /// Clear semua callbacks dan controller.
  /// Dipanggil saat halaman dispose / tidak aktif.
  void clearCallbacks() {
    _onConfirm = null;
    _onNext = null;
    _onBack = null;
    _scrollController = null;
  }

  /// Execute CONFIRM action (Thumbs Up).
  Future<GestureActionResult> executeConfirm() async {
    try {
      if (_onConfirm == null) {
        return GestureActionResult(
          type: GestureActionType.confirm,
          status: ActionStatus.skipped,
          message: 'Tidak ada aksi confirm pada halaman ini',
        );
      }

      final success = await _onConfirm!();

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

  /// Execute NEXT action (Open Palm).
  ///
  /// Prioritas:
  /// 1. callback halaman
  /// 2. fallback scroll controller
  Future<GestureActionResult> executeNext() async {
    try {
      if (_onNext != null) {
        final success = await _onNext!();

        return GestureActionResult(
          type: GestureActionType.next,
          status: success ? ActionStatus.success : ActionStatus.failed,
          message: success ? 'Lanjut berhasil' : 'Lanjut gagal',
        );
      }

      if (_scrollController != null && _scrollController!.hasClients) {
        final currentOffset = _scrollController!.offset;
        final maxOffset = _scrollController!.position.maxScrollExtent;

        if (currentOffset >= maxOffset) {
          return GestureActionResult(
            type: GestureActionType.next,
            status: ActionStatus.skipped,
            message: 'Sudah berada di bagian paling bawah',
          );
        }

        final nextOffset =
            (currentOffset + scrollOffset).clamp(0.0, maxOffset);

        await _scrollController!.animateTo(
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

  /// Execute BACK action (Fist).
  ///
  /// Prioritas:
  /// 1. callback halaman
  /// 2. fallback Navigator.maybePop()
  Future<GestureActionResult> executeBack(BuildContext? context) async {
    try {
      if (_onBack != null) {
        final success = await _onBack!();

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
    switch (type) {
      case GestureActionType.confirm:
        return _onConfirm != null;
      case GestureActionType.next:
        return _onNext != null ||
            (_scrollController != null && _scrollController!.hasClients);
      case GestureActionType.back:
        return _onBack != null || hasContext;
      case GestureActionType.unknown:
        return false;
    }
  }

  void printRegisteredCallbacks() {
    debugPrint('[GestureActionService] === Registered Callbacks ===');
    debugPrint('[GestureActionService] Confirm: ${_onConfirm != null}');
    debugPrint('[GestureActionService] Next: ${_onNext != null}');
    debugPrint('[GestureActionService] Back: ${_onBack != null}');
    debugPrint(
      '[GestureActionService] ScrollController: ${_scrollController != null}',
    );
    debugPrint('[GestureActionService] =============================');
  }
}