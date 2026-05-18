import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/gesture_result_model.dart';
import '../models/hand_landmark_model.dart';

class GestureClassifierService {
  /// Classifies gesture from 21 MediaPipe hand landmarks.
  ///
  /// MVP:
  /// - thumbs_up -> confirm
  /// - fist -> back
  /// - open_palm -> next
  /// - unknown -> no_action
  GestureResultModel classify(List<HandLandmark> landmarks) {
    if (landmarks.length < 21) {
      return GestureResultModel.none();
    }

    final foldedCount = _foldedFingerCount(landmarks);
    final extendedCount = _extendedFingerCount(landmarks);

    final thumbExtended = _isThumbExtended(landmarks);
    final thumbSeparated = _isThumbSeparatedFromPalmAndFingers(landmarks);

    final thumbsUpScore = _thumbsUpScore(
      landmarks,
      foldedCount: foldedCount,
      thumbExtended: thumbExtended,
      thumbSeparated: thumbSeparated,
    );

    final openPalmScore = _openPalmScore(
      landmarks,
      extendedCount: extendedCount,
      foldedCount: foldedCount,
    );

    final fistScore = _fistScore(
      landmarks,
      foldedCount: foldedCount,
      thumbExtended: thumbExtended,
      thumbSeparated: thumbSeparated,
    );

    String selectedGesture = 'unknown';

    // ============================================================
    // 1. THUMBS UP PRIORITY
    // ============================================================
    //
    // Thumbs Up dicek paling awal karena mirip Fist:
    // index, middle, ring, pinky sama-sama folded.
    //
    // Versi ini dibuat lebih tahan terhadap angle kamera.
    // Jadi thumbSeparated TIDAK wajib true, karena pada angle samping
    // landmark thumb bisa terlihat dekat dengan jari lain walaupun gesture valid.
    if (thumbsUpScore >= 0.58 && foldedCount >= 3 && thumbExtended) {
      selectedGesture = 'thumbs_up';

      _printDebugScores(
        openPalmScore: openPalmScore,
        fistScore: fistScore,
        thumbsUpScore: thumbsUpScore,
        foldedCount: foldedCount,
        extendedCount: extendedCount,
        thumbExtended: thumbExtended,
        thumbSeparated: thumbSeparated,
        selectedGesture: selectedGesture,
      );

      return GestureResultModel(
        gestureType: 'thumbs_up',
        action: 'confirm',
        confidence: thumbsUpScore.clamp(0.65, 1.0),
        landmarks: landmarks,
        timestamp: DateTime.now(),
      );
    }

    // ============================================================
    // 2. OPEN PALM
    // ============================================================
    //
    // Open Palm butuh mayoritas jari extended.
    // Ini dicek setelah Thumbs Up supaya tidak salah baca saat thumb terbuka.
    if (openPalmScore >= 0.72 && extendedCount >= 3 && foldedCount <= 1) {
      selectedGesture = 'open_palm';

      _printDebugScores(
        openPalmScore: openPalmScore,
        fistScore: fistScore,
        thumbsUpScore: thumbsUpScore,
        foldedCount: foldedCount,
        extendedCount: extendedCount,
        thumbExtended: thumbExtended,
        thumbSeparated: thumbSeparated,
        selectedGesture: selectedGesture,
      );

      return GestureResultModel(
        gestureType: 'open_palm',
        action: 'next',
        confidence: openPalmScore.clamp(0.65, 1.0),
        landmarks: landmarks,
        timestamp: DateTime.now(),
      );
    }

    // ============================================================
    // 3. FIST
    // ============================================================
    //
    // Fist dicek terakhir.
    // Fist harus punya mayoritas jari folded.
    // Kalau thumbSeparated true, kemungkinan besar itu Thumbs Up,
    // jadi fist score akan turun di _fistScore().
    if (fistScore >= 0.68 && foldedCount >= 3 && thumbsUpScore < 0.58) {
      selectedGesture = 'fist';

      _printDebugScores(
        openPalmScore: openPalmScore,
        fistScore: fistScore,
        thumbsUpScore: thumbsUpScore,
        foldedCount: foldedCount,
        extendedCount: extendedCount,
        thumbExtended: thumbExtended,
        thumbSeparated: thumbSeparated,
        selectedGesture: selectedGesture,
      );

      return GestureResultModel(
        gestureType: 'fist',
        action: 'back',
        confidence: fistScore.clamp(0.65, 1.0),
        landmarks: landmarks,
        timestamp: DateTime.now(),
      );
    }

    _printDebugScores(
      openPalmScore: openPalmScore,
      fistScore: fistScore,
      thumbsUpScore: thumbsUpScore,
      foldedCount: foldedCount,
      extendedCount: extendedCount,
      thumbExtended: thumbExtended,
      thumbSeparated: thumbSeparated,
      selectedGesture: selectedGesture,
    );

    return GestureResultModel.unknown(landmarks);
  }

  // ============================================================
  // SCORING
  // ============================================================

  double _thumbsUpScore(
    List<HandLandmark> l, {
    required int foldedCount,
    required bool thumbExtended,
    required bool thumbSeparated,
  }) {
    double score = 0.0;

    final palm = _palmSize(l);
    final palmCenter = _palmCenter(l);

    final thumbTip = l[4];
    final thumbIp = l[3];
    final thumbMcp = l[2];

    final thumbTipToMcp = _distance(thumbTip, thumbMcp);
    final thumbIpToMcp = _distance(thumbIp, thumbMcp);
    final thumbTipToPalm = _distance(thumbTip, palmCenter);

    // Pada thumbs up, 3-4 jari selain thumb harus folded.
    // Dibuat cukup besar supaya angle samping tetap masuk.
    score += (foldedCount / 4.0) * 0.45;

    // Syarat utama Thumbs Up:
    // jempol terlihat memanjang dari MCP ke TIP.
    if (thumbExtended) {
      score += 0.35;
    }

    // Jangan jadikan separated sebagai syarat wajib.
    // Pada angle samping, landmark thumb bisa overlap dengan jari lain.
    // Jadi ini hanya bonus kecil.
    if (thumbSeparated) {
      score += 0.10;
    }

    // Bonus kalau thumb tip memang lebih panjang dari ruas dasarnya.
    if (thumbTipToMcp > thumbIpToMcp * 1.12) {
      score += 0.08;
    }

    // Bonus kalau thumb tidak terlalu dekat pusat telapak.
    if (thumbTipToPalm > palm * 0.55) {
      score += 0.07;
    }

    return score.clamp(0.0, 1.0);
  }

  double _openPalmScore(
    List<HandLandmark> l, {
    required int extendedCount,
    required int foldedCount,
  }) {
    double score = 0.0;

    score += (extendedCount / 4.0) * 0.90;

    final palm = _palmSize(l);
    final thumbAway = _distance(l[4], l[9]) > palm * 0.55;

    if (thumbAway) {
      score += 0.10;
    }

    // Kalau banyak jari folded, jangan dianggap open palm.
    if (foldedCount >= 2) {
      score *= 0.55;
    }

    return score.clamp(0.0, 1.0);
  }

  double _fistScore(
    List<HandLandmark> l, {
    required int foldedCount,
    required bool thumbExtended,
    required bool thumbSeparated,
  }) {
    final palm = _palmSize(l);
    final palmCenter = _palmCenter(l);

    final tips = [
      l[8], // index tip
      l[12], // middle tip
      l[16], // ring tip
      l[20], // pinky tip
    ];

    final closeTips = tips.where((tip) {
      return _distance(tip, palmCenter) < palm * 1.65;
    }).length;

    final foldedScore = foldedCount / 4.0;
    final closeScore = closeTips / 4.0;

    double score = (foldedScore * 0.75) + (closeScore * 0.25);

    // Kalau thumb sangat separated, kemungkinan besar Thumbs Up.
    if (thumbSeparated) {
      score *= 0.35;
    }

    // Kalau thumb extended tapi tidak separated,
    // jangan terlalu dihukum karena pada fist jempol kadang tetap terlihat keluar.
    if (thumbExtended && !thumbSeparated) {
      score *= 0.85;
    }

    return score.clamp(0.0, 1.0);
  }

  // ============================================================
  // FINGER COUNT HELPERS
  // ============================================================

  int _foldedFingerCount(List<HandLandmark> l) {
    final fingers = [
      _isFingerFolded(l, tip: 8, pip: 6, mcp: 5), // index
      _isFingerFolded(l, tip: 12, pip: 10, mcp: 9), // middle
      _isFingerFolded(l, tip: 16, pip: 14, mcp: 13), // ring
      _isFingerFolded(l, tip: 20, pip: 18, mcp: 17), // pinky
    ];

    return fingers.where((value) => value).length;
  }

  int _extendedFingerCount(List<HandLandmark> l) {
    final fingers = [
      _isFingerExtended(l, tip: 8, pip: 6, mcp: 5), // index
      _isFingerExtended(l, tip: 12, pip: 10, mcp: 9), // middle
      _isFingerExtended(l, tip: 16, pip: 14, mcp: 13), // ring
      _isFingerExtended(l, tip: 20, pip: 18, mcp: 17), // pinky
    ];

    return fingers.where((value) => value).length;
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
    final tipToMcp = _distance(l[tip], l[mcp]);

    return tipToWrist > pipToWrist + palm * 0.08 &&
        pipToWrist > mcpToWrist - palm * 0.05 &&
        tipToMcp > palm * 0.70;
  }

  bool _isFingerFolded(
    List<HandLandmark> l, {
    required int tip,
    required int pip,
    required int mcp,
  }) {
    final palm = _palmSize(l);
    final palmCenter = _palmCenter(l);

    final tipToWrist = _distance(l[tip], l[0]);
    final pipToWrist = _distance(l[pip], l[0]);
    final mcpToWrist = _distance(l[mcp], l[0]);

    final tipToMcp = _distance(l[tip], l[mcp]);
    final pipToMcp = _distance(l[pip], l[mcp]);

    final tipToPalm = _distance(l[tip], palmCenter);
    final mcpToPalm = _distance(l[mcp], palmCenter);

    final foldedByWrist = tipToWrist < pipToWrist + palm * 0.22 ||
        tipToWrist < mcpToWrist + palm * 0.38;

    final foldedByCurl = tipToMcp < pipToMcp * 1.45;

    final foldedByPalm = tipToPalm < mcpToPalm + palm * 0.48;

    return foldedByWrist || foldedByCurl || foldedByPalm;
  }

  bool _isThumbExtended(List<HandLandmark> l) {
    final palm = _palmSize(l);
    final palmCenter = _palmCenter(l);

    final thumbTip = l[4];
    final thumbIp = l[3];
    final thumbMcp = l[2];

    final thumbTipToMcp = _distance(thumbTip, thumbMcp);
    final thumbIpToMcp = _distance(thumbIp, thumbMcp);
    final thumbTipToPalm = _distance(thumbTip, palmCenter);

    // Ini sengaja dibuat lebih longgar supaya thumbs up dari angle miring
    // tetap terdeteksi.
    final longEnough = thumbTipToMcp > palm * 0.55;
    final longerThanBase = thumbTipToMcp > thumbIpToMcp * 1.12;
    final awayFromPalm = thumbTipToPalm > palm * 0.55;

    return longEnough && longerThanBase && awayFromPalm;
  }

  bool _isThumbSeparatedFromPalmAndFingers(List<HandLandmark> l) {
    final palm = _palmSize(l);
    final palmCenter = _palmCenter(l);

    final thumbTip = l[4];

    final thumbTipToPalm = _distance(thumbTip, palmCenter);

    final fingerTips = [
      l[8],
      l[12],
      l[16],
      l[20],
    ];

    final distancesToFingerTips = fingerTips.map((tip) {
      return _distance(thumbTip, tip);
    }).toList();

    final minDistanceToFingerTip = distancesToFingerTips.reduce(min);
    final avgDistanceToFingerTip =
        distancesToFingerTips.reduce((a, b) => a + b) /
            distancesToFingerTips.length;

    final farFromPalm = thumbTipToPalm > palm * 0.85;

    // Dibuat agak longgar.
    // Kalau terlalu ketat, thumbs up dari angle samping sering jadi unknown.
    final farFromFingerCluster =
        minDistanceToFingerTip > palm * 0.45 ||
        avgDistanceToFingerTip > palm * 0.72;

    return farFromPalm && farFromFingerCluster;
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
    final x = (l[0].x + l[5].x + l[9].x + l[13].x + l[17].x) / 5.0;
    final y = (l[0].y + l[5].y + l[9].y + l[13].y + l[17].y) / 5.0;

    return HandLandmark(
      x: x,
      y: y,
      confidence: 1.0,
    );
  }

  double _palmSize(List<HandLandmark> l) {
    final wrist = l[0];
    final middleMcp = l[9];

    final size = _distance(wrist, middleMcp);

    return max(size, 0.05);
  }

  void _printDebugScores({
    required double openPalmScore,
    required double fistScore,
    required double thumbsUpScore,
    required int foldedCount,
    required int extendedCount,
    required bool thumbExtended,
    required bool thumbSeparated,
    required String selectedGesture,
  }) {
    if (!kDebugMode) return;

    debugPrint(
      '[GESTURE CLASSIFIER] '
      'open=${openPalmScore.toStringAsFixed(2)} | '
      'fist=${fistScore.toStringAsFixed(2)} | '
      'thumb=${thumbsUpScore.toStringAsFixed(2)} | '
      'folded=$foldedCount | '
      'extended=$extendedCount | '
      'thumbExtended=$thumbExtended | '
      'thumbSeparated=$thumbSeparated | '
      'selected=$selectedGesture',
    );
  }
}