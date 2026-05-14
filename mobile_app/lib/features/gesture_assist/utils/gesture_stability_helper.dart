import '../models/gesture_result_model.dart';

/// Helper untuk menjaga stabilitas hasil deteksi gesture.
/// Mencegah 'flicker' dengan mengharuskan gesture yang sama muncul 
/// berturut-turut selama beberapa frame sebelum dianggap 'Stable'.
class GestureStabilityHelper {
  final int requiredStableFrames;
  
  String? _candidateGesture;
  int _candidateCount = 0;
  String? _lastStableGesture;

  GestureStabilityHelper({this.requiredStableFrames = 5});

  /// Memproses hasil deteksi mentah dan mengembalikan status stabilitas.
  /// 
  /// Alur:
  /// 1. Jika no_hand atau none, reset status kandidat.
  /// 2. Jika gesture sama dengan kandidat sebelumnya, naikkan hitungan.
  /// 3. Jika hitungan mencapai threshold, tandai sebagai stable.
  bool processStability(GestureResultModel rawResult) {
    final currentGesture = rawResult.gestureType;

    // Abaikan dan reset jika tidak ada tangan atau unknown
    if (currentGesture == 'no_hand' || currentGesture == 'unknown' || currentGesture == 'none') {
      _candidateGesture = null;
      _candidateCount = 0;
      _lastStableGesture = null;
      return false;
    }

    // Jika gesture berbeda dari kandidat sebelumnya
    if (currentGesture != _candidateGesture) {
      _candidateGesture = currentGesture;
      _candidateCount = 1;
      return false;
    }

    // Jika gesture sama, naikkan counter
    _candidateCount++;

    // Cek apakah mencapai ambang batas stabilitas
    if (_candidateCount >= requiredStableFrames) {
      // Jika sudah stabil dan berbeda dari stable gesture terakhir (menghindari duplikasi trigger)
      if (_candidateGesture != _lastStableGesture) {
        _lastStableGesture = _candidateGesture;
        return true;
      }
    }

    return false;
  }

  /// Mengambil gesture yang saat ini dianggap kandidat stabil
  String? get candidateGesture => _candidateGesture;
  
  /// Mengambil jumlah frame konsisten saat ini
  int get candidateCount => _candidateCount;

  /// Reset status stability
  void reset() {
    _candidateGesture = null;
    _candidateCount = 0;
    _lastStableGesture = null;
  }
}
