import 'package:flutter/foundation.dart';

import '../models/gesture_result_model.dart';

class GestureStabilityOutput {
  final GestureResultModel result;
  final bool isStable;
  final bool shouldTriggerAction;
  final String rawGesture;
  final String? stableGesture;
  final int winnerCount;

  const GestureStabilityOutput({
    required this.result,
    required this.isStable,
    required this.shouldTriggerAction,
    required this.rawGesture,
    required this.stableGesture,
    required this.winnerCount,
  });
}

/// Helper untuk menjaga stabilitas hasil deteksi gesture.
///
/// Masalah lama:
/// - harus gesture yang sama berturut-turut
/// - begitu ada unknown 1 frame, counter reset
/// - UI jadi flicker: Fist/Thumbs Up -> Unknown -> Fist/Thumbs Up
///
/// Solusi:
/// - pakai buffer beberapa frame terakhir
/// - ambil mayoritas gesture valid
/// - unknown tidak ikut jadi pemenang
/// - last stable gesture ditahan sebentar agar UI tidak flicker
class GestureStabilityHelper {
  final int bufferSize;
  final int requiredStableFrames;
  final int unknownGraceMs;
  final int retriggerDelayMs;

  final List<GestureResultModel> _buffer = [];

  GestureResultModel? _lastStableResult;
  DateTime? _lastStableAt;

  String? _lastTriggeredGesture;
  DateTime? _lastTriggeredAt;

  GestureStabilityHelper({
    this.bufferSize = 6,
    this.requiredStableFrames = 3,
    this.unknownGraceMs = 500,
    this.retriggerDelayMs = 1600,
  });

  static const Set<String> _validGestures = {
    'thumbs_up',
    'fist',
    'open_palm',
  };

  GestureStabilityOutput process(GestureResultModel rawResult) {
    final rawGesture = rawResult.gestureType;

    if (rawGesture == 'no_hand' || rawGesture == 'none') {
      reset();

      return GestureStabilityOutput(
        result: rawResult,
        isStable: false,
        shouldTriggerAction: false,
        rawGesture: rawGesture,
        stableGesture: null,
        winnerCount: 0,
      );
    }

    if (_validGestures.contains(rawGesture)) {
      _buffer.add(rawResult);

      if (_buffer.length > bufferSize) {
        _buffer.removeAt(0);
      }
    }

    final winnerData = _findWinner();
    final winnerGesture = winnerData.gestureType;
    final winnerCount = winnerData.count;
    final avgConfidence = winnerData.avgConfidence;

    if (winnerGesture != null && winnerCount >= requiredStableFrames) {
      final stableResult = GestureResultModel(
        gestureType: winnerGesture,
        action: _actionForGesture(winnerGesture),
        confidence: avgConfidence.clamp(0.65, 1.0),
        landmarks: rawResult.landmarks,
        timestamp: DateTime.now(),
      );

      _lastStableResult = stableResult;
      _lastStableAt = DateTime.now();

      final now = DateTime.now();
      final isDifferentGesture = _lastTriggeredGesture != winnerGesture;
      final canRetriggerSameGesture = _lastTriggeredAt == null ||
          now.difference(_lastTriggeredAt!).inMilliseconds >= retriggerDelayMs;

      final shouldTrigger = isDifferentGesture || canRetriggerSameGesture;

      if (shouldTrigger) {
        _lastTriggeredGesture = winnerGesture;
        _lastTriggeredAt = now;
      }

      _printDebug(
        rawGesture: rawGesture,
        stableGesture: winnerGesture,
        winnerCount: winnerCount,
        shouldTrigger: shouldTrigger,
      );

      return GestureStabilityOutput(
        result: stableResult,
        isStable: true,
        shouldTriggerAction: shouldTrigger,
        rawGesture: rawGesture,
        stableGesture: winnerGesture,
        winnerCount: winnerCount,
      );
    }

    if (_lastStableResult != null && _lastStableAt != null) {
      final elapsed = DateTime.now().difference(_lastStableAt!).inMilliseconds;

      if (elapsed <= unknownGraceMs) {
        final heldResult = GestureResultModel(
          gestureType: _lastStableResult!.gestureType,
          action: _lastStableResult!.action,
          confidence: _lastStableResult!.confidence,
          landmarks: rawResult.landmarks,
          timestamp: DateTime.now(),
        );

        _printDebug(
          rawGesture: rawGesture,
          stableGesture: heldResult.gestureType,
          winnerCount: winnerCount,
          shouldTrigger: false,
        );

        return GestureStabilityOutput(
          result: heldResult,
          isStable: false,
          shouldTriggerAction: false,
          rawGesture: rawGesture,
          stableGesture: heldResult.gestureType,
          winnerCount: winnerCount,
        );
      }

      _lastStableResult = null;
      _lastStableAt = null;
      _lastTriggeredGesture = null;
      _lastTriggeredAt = null;
    }

    _printDebug(
      rawGesture: rawGesture,
      stableGesture: null,
      winnerCount: winnerCount,
      shouldTrigger: false,
    );

    return GestureStabilityOutput(
      result: rawResult,
      isStable: false,
      shouldTriggerAction: false,
      rawGesture: rawGesture,
      stableGesture: null,
      winnerCount: winnerCount,
    );
  }

  _GestureWinnerData _findWinner() {
    final Map<String, int> counts = {};
    final Map<String, double> confidenceSums = {};

    for (final result in _buffer) {
      final gesture = result.gestureType;

      if (!_validGestures.contains(gesture)) {
        continue;
      }

      counts[gesture] = (counts[gesture] ?? 0) + 1;
      confidenceSums[gesture] =
          (confidenceSums[gesture] ?? 0.0) + result.confidence;
    }

    String? winnerGesture;
    int winnerCount = 0;

    counts.forEach((gesture, count) {
      if (count > winnerCount) {
        winnerGesture = gesture;
        winnerCount = count;
      }
    });

    if (winnerGesture == null) {
      return const _GestureWinnerData(
        gestureType: null,
        count: 0,
        avgConfidence: 0.0,
      );
    }

    final avgConfidence =
        (confidenceSums[winnerGesture] ?? 0.0) / winnerCount;

    return _GestureWinnerData(
      gestureType: winnerGesture,
      count: winnerCount,
      avgConfidence: avgConfidence,
    );
  }

  String _actionForGesture(String gestureType) {
    switch (gestureType) {
      case 'thumbs_up':
        return 'confirm';
      case 'fist':
        return 'back';
      case 'open_palm':
        return 'next';
      default:
        return 'no_action';
    }
  }

  void reset() {
    _buffer.clear();
    _lastStableResult = null;
    _lastStableAt = null;
    _lastTriggeredGesture = null;
    _lastTriggeredAt = null;
  }

  String? get lastStableGesture => _lastStableResult?.gestureType;

  int get bufferLength => _buffer.length;

  void _printDebug({
    required String rawGesture,
    required String? stableGesture,
    required int winnerCount,
    required bool shouldTrigger,
  }) {
    if (!kDebugMode) return;

    final bufferText = _buffer.map((e) => e.gestureType).join(', ');

    debugPrint(
      '[GESTURE STABILITY] '
      'raw=$rawGesture | '
      'buffer=[$bufferText] | '
      'stable=$stableGesture | '
      'winnerCount=$winnerCount/$bufferSize | '
      'required=$requiredStableFrames | '
      'trigger=$shouldTrigger',
    );
  }
}

class _GestureWinnerData {
  final String? gestureType;
  final int count;
  final double avgConfidence;

  const _GestureWinnerData({
    required this.gestureType,
    required this.count,
    required this.avgConfidence,
  });
}