import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/hand_landmark_model.dart';
import '../models/gesture_result_model.dart';

class GestureClassifierService {
  /// Classifies gesture from 21 real MediaPipe hand landmarks.
  ///
  /// Output:
  /// - open_palm -> next
  /// - fist -> back
  /// - thumbs_up -> confirm
  /// - unknown -> no_action
  GestureResultModel classify(List<HandLandmark> landmarks) {
    if (landmarks.length < 21) {
      return GestureResultModel.none();
    }

    final openPalmScore = _openPalmScore(landmarks);
    var fistScore = _fistScore(landmarks);
    final thumbsUpScore = _thumbsUpScore(landmarks);

    debugPrint(
      'SCORE => open=${openPalmScore.toStringAsFixed(2)} '
      'fist=${fistScore.toStringAsFixed(2)} '
      'thumb=${thumbsUpScore.toStringAsFixed(2)}',
    );

    // PENTING:
    // Thumbs up dan Fist sangat mirip (4 jari terlipat).
    // Kita harus memastikan pemenang skor tertinggi yang diambil dengan kombinasi scoring + angle.
    // Gunakan scoring untuk determinasi gesture dengan presisi tinggi.
    
    // === OPTION C: Penalize Fist When Thumb Dominates ===
    // Jika thumb clearly extended dan dominates other fingers, reduce fist score
    // Logika: dalam thumbs up asli, jempol harus visually dominant (bukan just "available")
    if (thumbsUpScore >= 0.65) {
      final thumb = landmarks[4];
      final thumbMcp = landmarks[2];
      final thumbIp = landmarks[3];
      final palm = _palmSize(landmarks);
      
      final thumbLength = _distance(thumb, thumbMcp);
      final thumbBaseLength = _distance(thumbIp, thumbMcp);
      final thumbClearlyExtended = thumbLength > thumbBaseLength * 1.65;
      
      // Check if thumb dominates
      final thumbTipToWrist = _distance(thumb, landmarks[0]);
      final otherTips = [_distance(landmarks[8], landmarks[0]), 
                         _distance(landmarks[12], landmarks[0]), 
                         _distance(landmarks[16], landmarks[0]), 
                         _distance(landmarks[20], landmarks[0])];
      final avgOtherTipToWrist = otherTips.reduce((a, b) => a + b) / otherTips.length;
      final maxOtherTipToWrist = otherTips.reduce(max);
      
      // Jika thumb clearly extended, reduce fist score (25% penalty)
      // Logika: thumbs up selalu punya thumb extended; fist punya semua jari tertutup
      if (thumbClearlyExtended) {
        fistScore *= 0.75;
        if (kDebugMode) {
          print('[FIST PENALTY v2] Applied 25% penalty due to thumb extension: $fistScore');
        }
      }
    }
    
    // DEBUG: Log semua scores untuk tuning
    if (kDebugMode) {
      print('[CLASSIFY DEBUG] open=$openPalmScore fist=$fistScore thumb=$thumbsUpScore');
    }
    
    // 1. Cek Thumbs Up (Score >= 0.65 dengan validasi angle dan dominasi fist)
    // Lowered threshold dari 0.80 karena natural thumbs up mungkin tidak sekuat forced position
    if (thumbsUpScore >= 0.65 && thumbsUpScore > fistScore) {
      // Tambahan: validasi sudut jempol untuk memastikan truly upright
      if (_validateThumbAngle(landmarks)) {
        return GestureResultModel(
          gestureType: 'thumbs_up',
          action: 'confirm',
          confidence: thumbsUpScore,
          landmarks: landmarks,
          timestamp: DateTime.now(),
        );
      }
    }

    // 2. Cek Open Palm
    if (openPalmScore >= 0.75 && openPalmScore > fistScore && openPalmScore > thumbsUpScore) {
      return GestureResultModel(
        gestureType: 'open_palm',
        action: 'next',
        confidence: openPalmScore,
        landmarks: landmarks,
        timestamp: DateTime.now(),
      );
    }

    // 3. Cek Fist (Hanya jika skornya dominan dan Thumbs Up gagal)
    if (fistScore >= 0.85 && fistScore > thumbsUpScore) {
      return GestureResultModel(
        gestureType: 'fist',
        action: 'back',
        confidence: fistScore,
        landmarks: landmarks,
        timestamp: DateTime.now(),
      );
    }


    return GestureResultModel.unknown(landmarks);
  }

  // ============================================================
  // SCORING
  // ============================================================

  double _openPalmScore(List<HandLandmark> l) {
    final fingers = [
      _isFingerExtended(l, tip: 8, pip: 6, mcp: 5), // index
      _isFingerExtended(l, tip: 12, pip: 10, mcp: 9), // middle
      _isFingerExtended(l, tip: 16, pip: 14, mcp: 13), // ring
      _isFingerExtended(l, tip: 20, pip: 18, mcp: 17), // pinky
    ];

    final extendedCount = fingers.where((v) => v).length;

    // Thumb tidak dibuat terlalu wajib karena posisi thumb bisa berubah
    // tergantung tangan kiri/kanan dan sudut kamera.
    final thumbAway = _distance(l[4], l[9]) > _palmSize(l) * 0.55;

    double score = extendedCount / 4.0;

    if (thumbAway) {
      score += 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  double _fistScore(List<HandLandmark> l) {
    final fingers = [
      _isFingerFolded(l, tip: 8, pip: 6, mcp: 5), // index
      _isFingerFolded(l, tip: 12, pip: 10, mcp: 9), // middle
      _isFingerFolded(l, tip: 16, pip: 14, mcp: 13), // ring
      _isFingerFolded(l, tip: 20, pip: 18, mcp: 17), // pinky
    ];

    final foldedCount = fingers.where((v) => v).length;

    // Pada fist, ujung jari biasanya dekat area telapak.
    final palmCenter = _palmCenter(l);
    final palm = _palmSize(l);

    final tips = [l[8], l[12], l[16], l[20]];
    final closeTips = tips.where((tip) {
      return _distance(tip, palmCenter) < palm * 1.15;
    }).length;

    final foldedScore = foldedCount / 4.0;
    final closeScore = closeTips / 4.0;

    return ((foldedScore * 0.7) + (closeScore * 0.3)).clamp(0.0, 1.0);
  }

  double _thumbsUpScore(List<HandLandmark> l) {
    final palm = _palmSize(l);

    final thumbTip = l[4];
    final thumbIp = l[3];
    final thumbMcp = l[2];

    final indexMcp = l[5];
    final middleMcp = l[9];

    final indexFolded = _isFingerFolded(l, tip: 8, pip: 6, mcp: 5);
    final middleFolded = _isFingerFolded(l, tip: 12, pip: 10, mcp: 9);
    final ringFolded = _isFingerFolded(l, tip: 16, pip: 14, mcp: 13);
    final pinkyFolded = _isFingerFolded(l, tip: 20, pip: 18, mcp: 17);

    final foldedCount = [
      indexFolded,
      middleFolded,
      ringFolded,
      pinkyFolded,
    ].where((v) => v).length;

    // Kalau jari selain thumb belum benar-benar folded,
    // jangan dianggap thumbs up.
    if (foldedCount < 4) {
      return 0.0;
    }

    final thumbLength = _distance(thumbTip, thumbMcp);
    final thumbBaseLength = _distance(thumbIp, thumbMcp);

    final thumbTipToWrist = _distance(thumbTip, l[0]);

    final otherTipToWrist = [
      _distance(l[8], l[0]),
      _distance(l[12], l[0]),
      _distance(l[16], l[0]),
      _distance(l[20], l[0]),
    ];

    final avgOtherTipToWrist =
        otherTipToWrist.reduce((a, b) => a + b) / otherTipToWrist.length;

    final maxOtherTipToWrist = otherTipToWrist.reduce(max);

    final thumbClearlyExtended = thumbLength > thumbBaseLength * 1.65; // dari 1.80
    final thumbLongEnough = thumbLength > palm * 0.90; // dari 1.0
    final thumbFarFromPalm =
        _distance(thumbTip, middleMcp) > palm * 1.30 || // dari 1.40
        _distance(thumbTip, indexMcp) > palm * 1.20; // dari 1.30

    final thumbDominatesOtherFingers =
        thumbTipToWrist > avgOtherTipToWrist * 1.30 && // dari 1.40
        thumbTipToWrist >= maxOtherTipToWrist * 1.10; // dari 1.20

    // Cek sudut jempol: jempol harus "tegak" relatif terhadap telapak tangan.
    // Ini membantu membedakan thumbs up asli dari thumb yang hanya "nyempil" di fist.
    final thumbAngleFromPalm = _calculateThumbAngle(l);
    final thumbUprightAngle = 
        (thumbAngleFromPalm >= 60 && thumbAngleFromPalm <= 120) || 
        (thumbAngleFromPalm >= 240 && thumbAngleFromPalm <= 300) ||
        (thumbAngleFromPalm >= 150 && thumbAngleFromPalm <= 210); // tambah range untuk accommodate variasi

    // Bonus visual, bukan syarat utama.
    final thumbVisuallyHigher =
        thumbTip.y < indexMcp.y && thumbTip.y < middleMcp.y;

    double score = 0.0;

    score += (foldedCount / 4.0) * 0.30; // Sedikit diturunkan karena ada bonus angle

    if (thumbClearlyExtended) score += 0.25;
    if (thumbLongEnough) score += 0.15;
    if (thumbFarFromPalm) score += 0.15;
    if (thumbDominatesOtherFingers) score += 0.20;
    if (thumbVisuallyHigher) score += 0.05;
    // Tambahan: angle check memberikan bonus signifikan karena sangat distinguish
    if (thumbUprightAngle) score += 0.15;

    return score.clamp(0.0, 1.0);
  }

  // ============================================================
  // FINGER HELPERS
  // ============================================================

  bool _isFingerExtended(
    List<HandLandmark> l, {
    required int tip,
    required int pip,
    required int mcp,
  }) {
    final palm = _palmSize(l);

    final tipToWrist = _distance(l[tip], l[0]);
    final pipToWrist = _distance(l[pip], l[0]);
    final mcpToWrist = _distance(l[mcp], l[0]);

    // Jari dianggap extended kalau tip lebih jauh dari wrist
    // dibanding PIP/MCP. Ini lebih tahan rotasi daripada cek y saja.
    return tipToWrist > pipToWrist &&
        pipToWrist > mcpToWrist &&
        tipToWrist > palm * 1.15;
  }

  bool _isFingerFolded(
    List<HandLandmark> l, {
    required int tip,
    required int pip,
    required int mcp,
  }) {
    final palm = _palmSize(l);

    final tipToWrist = _distance(l[tip], l[0]);
    final pipToWrist = _distance(l[pip], l[0]);
    final mcpToWrist = _distance(l[mcp], l[0]);

    // Folded kalau tip tidak lebih jauh secara jelas dari PIP/MCP.
    // Ini cocok untuk kepalan dan jari terlipat pada thumbs up.
    return tipToWrist < pipToWrist + palm * 0.15 ||
        tipToWrist < mcpToWrist + palm * 0.35;
  }

  // ============================================================
  // GEOMETRY HELPERS
  // ============================================================

  double _distance(HandLandmark a, HandLandmark b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
  }

  HandLandmark _palmCenter(List<HandLandmark> l) {
    final x = (l[0].x + l[5].x + l[9].x + l[13].x + l[17].x) / 5;
    final y = (l[0].y + l[5].y + l[9].y + l[13].y + l[17].y) / 5;

    return HandLandmark(
      x: x,
      y: y,
      confidence: 1.0,
    );
  }

  double _palmSize(List<HandLandmark> l) {
    // Ukuran telapak relatif agar threshold tidak tergantung
    // tangan dekat/jauh kamera.
    final wrist = l[0];
    final middleMcp = l[9];

    final size = _distance(wrist, middleMcp);

    // Safety supaya threshold tidak terlalu kecil.
    return max(size, 0.05);
  }

  /// Menghitung sudut jempol relatif terhadap telapak tangan.
  /// Nilai 0-360 derajat. Untuk thumbs up, sudut biasanya perpendikuler atau tidak sejajar dengan palm.
  double _calculateThumbAngle(List<HandLandmark> l) {
    final wrist = l[0];
    final thumbTip = l[4];
    final middleMcp = l[9];

    // Vector dari wrist ke thumbTip (arah jempol)
    final thumbVecX = thumbTip.x - wrist.x;
    final thumbVecY = thumbTip.y - wrist.y;

    // Vector dari wrist ke middle MCP (arah telapak/center)
    final palmVecX = middleMcp.x - wrist.x;
    final palmVecY = middleMcp.y - wrist.y;

    // Hitung sudut menggunakan atan2
    final palmAngle = atan2(palmVecY, palmVecX) * 180 / pi;
    final thumbAngle = atan2(thumbVecY, thumbVecX) * 180 / pi;

    var angleDiff = (thumbAngle - palmAngle) % 360;
    if (angleDiff < 0) {
      angleDiff += 360;
    }

    // DEBUG: Log angle calculation untuk tuning
    if (kDebugMode) {
      print('[ANGLE] palmDir=$palmAngle° thumbDir=$thumbAngle° diff=$angleDiff°');
    }

    return angleDiff;
  }

  /// Validasi bahwa jempol berada dalam posisi "tegak" (upright).
  /// Lebih lenient untuk accommodate berbagai hand orientations.
  bool _validateThumbAngle(List<HandLandmark> landmarks) {
    if (landmarks.length < 21) return false;
    
    final angle = _calculateThumbAngle(landmarks);
    
    // Thumbs up characteristics:
    // - Thumb points AWAY dari palm center (angle ~90-270 range)
    // - NOT parallel dengan palm direction (not near 0° atau 180°)
    
    // Definisi: angle is "perpendicular-ish" jika NOT nearly parallel
    final isNearlyParallel = 
        (angle >= 350 || angle <= 10) ||  // 0° ± 10
        (angle >= 170 && angle <= 190);   // 180° ± 10
    
    // Thumbs up ketika angle is perpendicular-ish (bukan sejajar dengan palm)
    final isPerpendicularish = !isNearlyParallel;
    
    // Tambahan: check jika thumb tip lebih jauh dari palm center
    // Ini memastikan thumb truly extended, bukan hanya "angled"
    final wrist = landmarks[0];
    final thumbTip = landmarks[4];
    final middleMcp = landmarks[9];
    
    final thumbDistFromWrist = _distance(thumbTip, wrist);
    final palmScaleFromWrist = _distance(middleMcp, wrist);
    
    final thumbIsLong = thumbDistFromWrist > palmScaleFromWrist * 1.1;
    
    return isPerpendicularish && thumbIsLong;
  }
}