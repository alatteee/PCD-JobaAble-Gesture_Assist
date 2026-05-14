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
    final fistScore = _fistScore(landmarks);
    final thumbsUpScore = _thumbsUpScore(landmarks);

    debugPrint(
      'SCORE => open=${openPalmScore.toStringAsFixed(2)} '
      'fist=${fistScore.toStringAsFixed(2)} '
      'thumb=${thumbsUpScore.toStringAsFixed(2)}',
    );

    // PENTING:
    // Thumbs up dicek paling awal karena bentuknya mirip fist:
    // 4 jari terlipat, hanya thumb yang extended.
    if (thumbsUpScore >= 0.80) {
      return GestureResultModel(
        gestureType: 'thumbs_up',
        action: 'confirm',
        confidence: thumbsUpScore,
        landmarks: landmarks,
        timestamp: DateTime.now(),
      );
    }

    if (openPalmScore >= 0.75 && openPalmScore > fistScore) {
      return GestureResultModel(
        gestureType: 'open_palm',
        action: 'next',
        confidence: openPalmScore,
        landmarks: landmarks,
        timestamp: DateTime.now(),
      );
    }

    if (fistScore >= 0.75) {
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
    if (foldedCount < 3) {
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

    // Syarat baru:
    // Pada thumbs up asli, ujung thumb biasanya jadi titik paling dominan/jauh.
    // Pada fist, thumb sering terlihat terbuka sedikit, tapi tidak dominan jauh.
    final thumbClearlyExtended = thumbLength > thumbBaseLength * 1.45;
    final thumbLongEnough = thumbLength > palm * 0.75;
    final thumbFarFromPalm =
        _distance(thumbTip, middleMcp) > palm * 1.05 ||
        _distance(thumbTip, indexMcp) > palm * 0.95;

    final thumbDominatesOtherFingers =
        thumbTipToWrist > avgOtherTipToWrist * 1.10 &&
        thumbTipToWrist >= maxOtherTipToWrist * 0.95;

    // Bonus visual, bukan syarat utama.
    final thumbVisuallyHigher =
        thumbTip.y < indexMcp.y || thumbTip.y < middleMcp.y;

    double score = 0.0;

    score += (foldedCount / 4.0) * 0.35;

    if (thumbClearlyExtended) score += 0.25;
    if (thumbLongEnough) score += 0.15;
    if (thumbFarFromPalm) score += 0.15;
    if (thumbDominatesOtherFingers) score += 0.20;
    if (thumbVisuallyHigher) score += 0.05;

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
}