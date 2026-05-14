import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/gesture_result_model.dart';

/// Service untuk menangani aksi nyata berdasarkan gesture yang masuk.
/// Controller ini menggunakan [HapticFeedback] agar user mendapatkan respon fisik.
class GestureActionController {
  final BuildContext context;

  GestureActionController(this.context);

  /// Menjalankan aksi berdasarkan tipe gesture.
  void handleAction(GestureResultModel result) {
    switch (result.gestureType) {
      case 'open_palm':
        _handleNext();
        break;
      case 'fist':
        _handleBack();
        break;
      case 'thumbs_up':
        _handleConfirm();
        break;
      default:
        // Tidak ada aksi untuk unknown atau no_hand
        break;
    }
  }

  void _handleNext() {
    debugPrint('🚀 Action: NEXT triggered');
    HapticFeedback.mediumImpact();
    
    // Contoh implementasi: Scroll ke bawah jika di dalam ListView
    // Atau bisa juga berpindah Tab.
    // Di sini kita bisa menambahkan notifikasi visual (SnackBar) sebagai bukti aksi.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aksi: Next (Lanjut)'),
        duration: Duration(milliseconds: 500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleBack() {
    debugPrint('🚀 Action: BACK triggered');
    HapticFeedback.mediumImpact();

    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aksi: Back (Halaman Utama)'),
          duration: Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _handleConfirm() {
    debugPrint('🚀 Action: CONFIRM triggered');
    HapticFeedback.heavyImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: const Text('Aksi: OK / Konfirmasi'),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
