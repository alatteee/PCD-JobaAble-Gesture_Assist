import 'package:flutter/material.dart';
import '../models/gesture_action_model.dart';

/// Service untuk execute gesture actions dengan aman
class GestureActionService {
  static final GestureActionService _instance = GestureActionService._internal();

  factory GestureActionService() {
    return _instance;
  }

  GestureActionService._internal();

  // Callback yang bisa didaftarkan oleh halaman
  GestureConfirmCallback? _onConfirm;
  GestureNextCallback? _onNext;
  GestureBackCallback? _onBack;

  ScrollController? _scrollController;

  // Constants
  static const double scrollOffset = 300.0;
  static const double scrollDuration = 500; // milliseconds

  /// Register callback untuk CONFIRM action
  void onConfirmAction(GestureConfirmCallback callback) {
    _onConfirm = callback;
  }

  /// Register callback untuk NEXT action
  void onNextAction(GestureNextCallback callback) {
    _onNext = callback;
  }

  /// Register callback untuk BACK action
  void onBackAction(GestureBackCallback callback) {
    _onBack = callback;
  }

  /// Register scroll controller untuk NEXT action (scroll down)
  void setScrollController(ScrollController controller) {
    _scrollController = controller;
  }

  /// Clear semua callbacks dan controllers
  void clearCallbacks() {
    _onConfirm = null;
    _onNext = null;
    _onBack = null;
    _scrollController = null;
  }

  /// Execute CONFIRM action (Thumbs Up)
  /// Panggil callback confirmAction jika ada
  Future<GestureActionResult> executeConfirm() async {
    try {
      if (_onConfirm == null) {
        return GestureActionResult(
          type: GestureActionType.confirm,
          status: ActionStatus.skipped,
          message: 'Tidak ada confirm action terdaftar untuk halaman ini',
        );
      }

      final success = await _onConfirm!();

      return GestureActionResult(
        type: GestureActionType.confirm,
        status: success ? ActionStatus.success : ActionStatus.failed,
        message: success ? '✅ Konfirmasi berhasil' : '❌ Konfirmasi gagal',
      );
    } catch (e) {
      return GestureActionResult(
        type: GestureActionType.confirm,
        status: ActionStatus.failed,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  /// Execute NEXT action (Open Palm)
  /// Scroll ke bawah jika ada ScrollController, atau panggil callback
  Future<GestureActionResult> executeNext() async {
    try {
      // Prioritas 1: Gunakan callback jika ada
      if (_onNext != null) {
        final success = await _onNext!();
        return GestureActionResult(
          type: GestureActionType.next,
          status: success ? ActionStatus.success : ActionStatus.failed,
          message: success ? '👉 Lanjut berhasil' : '❌ Lanjut gagal',
        );
      }

      // Prioritas 2: Scroll ke bawah jika ada ScrollController
      if (_scrollController != null && _scrollController!.hasClients) {
        final currentOffset = _scrollController!.offset;
        final maxOffset = _scrollController!.position.maxScrollExtent;
        final nextOffset =
            (currentOffset + scrollOffset).clamp(0.0, maxOffset);

        await _scrollController!.animateTo(
          nextOffset,
          duration: Duration(milliseconds: scrollDuration.toInt()),
          curve: Curves.easeInOut,
        );

        return GestureActionResult(
          type: GestureActionType.next,
          status: ActionStatus.success,
          message: '👉 Scroll ke bawah',
          data: {'offset': nextOffset},
        );
      }

      // Tidak ada aksi yang bisa dilakukan
      return GestureActionResult(
        type: GestureActionType.next,
        status: ActionStatus.skipped,
        message: 'Tidak ada next action terdaftar',
      );
    } catch (e) {
      return GestureActionResult(
        type: GestureActionType.next,
        status: ActionStatus.failed,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  /// Execute BACK action (Fist)
  /// Gunakan Navigator.maybePop() jika ada context
  /// Atau panggil callback jika ada
  Future<GestureActionResult> executeBack(BuildContext? context) async {
    try {
      // Prioritas 1: Gunakan callback jika ada
      if (_onBack != null) {
        final success = await _onBack!();
        return GestureActionResult(
          type: GestureActionType.back,
          status: success ? ActionStatus.success : ActionStatus.failed,
          message: success ? '👈 Kembali berhasil' : '❌ Kembali gagal',
        );
      }

      // Prioritas 2: Gunakan Navigator.maybePop() jika ada context
      if (context != null) {
        final popped = await Navigator.maybePop(context);
        return GestureActionResult(
          type: GestureActionType.back,
          status: popped ? ActionStatus.success : ActionStatus.skipped,
          message: popped
              ? '👈 Kembali'
              : '⏸️ Sudah di halaman pertama (tidak bisa kembali)',
        );
      }

      return GestureActionResult(
        type: GestureActionType.back,
        status: ActionStatus.failed,
        message: 'Tidak ada context untuk Navigator.pop',
      );
    } catch (e) {
      return GestureActionResult(
        type: GestureActionType.back,
        status: ActionStatus.failed,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  /// Check apakah action bisa dijalankan
  bool canExecuteAction(GestureActionType type) {
    switch (type) {
      case GestureActionType.confirm:
        return _onConfirm != null;
      case GestureActionType.next:
        return _onNext != null ||
            (_scrollController != null && _scrollController!.hasClients);
      case GestureActionType.back:
        return _onBack != null; // Navigator bisa selalu dipanggil
      case GestureActionType.unknown:
        return false;
    }
  }

  /// Debug: Print current registered callbacks
  void printRegisteredCallbacks() {
    print('[GestureActionService] === Registered Callbacks ===');
    print('[GestureActionService] Confirm: ${_onConfirm != null ? '✅' : '❌'}');
    print('[GestureActionService] Next: ${_onNext != null ? '✅' : '❌'}');
    print('[GestureActionService] Back: ${_onBack != null ? '✅' : '❌'}');
    print(
      '[GestureActionService] ScrollController: ${_scrollController != null ? '✅' : '❌'}',
    );
    print('[GestureActionService] ========================');
  }
}
