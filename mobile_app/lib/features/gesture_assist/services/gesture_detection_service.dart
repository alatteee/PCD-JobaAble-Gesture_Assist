import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:hand_landmarker/hand_landmarker.dart' as mp;

import '../models/gesture_result_model.dart';
import '../models/hand_landmark_model.dart';
import '../utils/image_preprocessor.dart';
import '../utils/gesture_cooldown_helper.dart';
import 'gesture_log_local_service.dart';
import '../models/gesture_log_model.dart';
import '../../../services/offline_service.dart';

class GestureDetectionService {
  final GestureCooldownHelper _cooldown =
      GestureCooldownHelper(cooldownMs: 1000);
  final GestureLogLocalService _localLogService = GestureLogLocalService();

  bool _isProcessing = false;

  /// Plugin real hand landmark detection.
  /// Package hand_landmarker memakai MediaPipe Hand Landmarker di Android.
  mp.HandLandmarkerPlugin? _handLandmarker;

  /// Kalau true, service akan mencoba membaca landmark tangan asli.
  /// Kalau AI aktif tapi tidak ada tangan, overlay akan dikosongkan.
  /// Dummy hanya dipakai kalau real detector gagal init / tidak aktif.
  bool _useRealDetection = true;

  /// Mode dummy gesture untuk tahap testing/fallback.
  /// Nilai yang didukung:
  /// - open_palm
  /// - fist
  /// - thumbs_up
  String _debugGestureType = 'open_palm';

  /// Anti-spam logging.
  /// Tujuannya agar gesture yang sama tidak disimpan terus-menerus
  /// selama camera stream aktif.
  String? _lastLoggedGestureType;
  DateTime? _lastLoggedAt;

  /// Kalau gesture sama terus, baru boleh disimpan ulang setelah durasi ini.
  /// Misalnya user tetap open_palm selama lama, history tidak penuh tiap 1 detik.
  static const int _sameGestureRelogDelayMs = 5000;

  String get debugGestureType => _debugGestureType;

  /// Panggil ini setelah camera berhasil initialize.
  /// Jangan dibuat async karena API HandLandmarkerPlugin.create() synchronous.
  void initializeRealDetector() {
    if (_handLandmarker != null) return;

    try {
      _handLandmarker = mp.HandLandmarkerPlugin.create(
        numHands: 1,
        minHandDetectionConfidence: 0.7,
        delegate: mp.HandLandmarkerDelegate.gpu,
      );

      _useRealDetection = true;
      debugPrint('✅ HandLandmarker initialized');
    } catch (e) {
      _useRealDetection = false;
      debugPrint('❌ Failed to initialize HandLandmarker: $e');
    }
  }

  void setDebugGestureType(String gestureType) {
    const allowedGestures = ['open_palm', 'fist', 'thumbs_up'];

    if (allowedGestures.contains(gestureType)) {
      _debugGestureType = gestureType;
    } else {
      _debugGestureType = 'open_palm';
    }
  }

  /// Main entry point untuk detection pipeline.
  ///
  /// Alur sekarang:
  /// CameraImage
  /// -> coba real hand landmark detection
  /// -> kalau dapat 21 landmark, return result real_hand_detected
  /// -> kalau AI aktif tapi tidak ada tangan, return no_hand + landmark kosong
  /// -> kalau AI gagal init / tidak aktif, fallback ke dummy landmark.
  Future<GestureResultModel?> processImage(
    CameraImage image, {
    int sensorOrientation = 90,
  }) async {
    if (_isProcessing) return null;
    _isProcessing = true;

    try {
      // ============================================================
      // 1. REAL HAND LANDMARK DETECTION
      // ============================================================
      if (_useRealDetection && _handLandmarker != null) {
        try {
          final hands = _handLandmarker!.detect(
            image,
            sensorOrientation,
          );

          final realLandmarks = _convertMediaPipeLandmarks(hands);

          if (realLandmarks.length == 21) {
            final result = GestureResultModel(
              gestureType: 'real_hand_detected',
              action: 'tracking',
              confidence: 0.95,
              landmarks: realLandmarks,
              timestamp: DateTime.now(),
            );

            // Untuk tahap awal, real_hand_detected boleh masuk history
            // tapi tetap pakai anti-spam agar tidak memenuhi Hive.
            if (_cooldown.canTrigger() && _shouldLogGesture(result)) {
              _cooldown.updateLastTrigger();
              await _saveGestureLog(result);
              _updateLastLoggedGesture(result);
            }

            return result;
          }

          // PENTING:
          // Kalau AI aktif tapi tidak menemukan tangan,
          // jangan fallback ke dummy.
          // Dummy lama dibuat dalam koordinat layar normal,
          // sedangkan overlay sekarang sudah ditransform untuk landmark real.
          return GestureResultModel(
            gestureType: 'no_hand',
            action: 'waiting',
            confidence: 0.0,
            landmarks: [],
            timestamp: DateTime.now(),
          );
        } catch (e) {
          debugPrint('❌ Real hand detection failed: $e');

          // Kalau detect error sesaat, kosongkan overlay dulu.
          // Jangan tampilkan dummy supaya tidak terlihat miring/aneh.
          return GestureResultModel(
            gestureType: 'no_hand',
            action: 'waiting',
            confidence: 0.0,
            landmarks: [],
            timestamp: DateTime.now(),
          );
        }
      }

      // ============================================================
      // 2. FALLBACK DUMMY PIPELINE
      // ============================================================
      // Bagian ini hanya jalan kalau real detector belum aktif / gagal init.
      // Dummy tetap dipertahankan agar fitur debug lama tidak hilang.

      // Preprocessing placeholder.
      // Untuk sekarang belum dipakai, tapi tetap dipanggil agar pipeline PCD
      // kamu tetap terlihat siap untuk pengembangan TFLite/manual preprocessing.
      // ignore: unused_local_variable
      final inputData = await ImagePreprocessor.preprocessCameraImage(image);

      final mockLandmarks = _generateMockLandmarks(_debugGestureType);

      final result = _buildDebugGestureResult(
        gestureType: _debugGestureType,
        landmarks: mockLandmarks,
      );

      if (result.gestureType != 'none' &&
          _cooldown.canTrigger() &&
          _shouldLogGesture(result)) {
        _cooldown.updateLastTrigger();

        await _saveGestureLog(result);
        _updateLastLoggedGesture(result);

        return result;
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error in GestureDetectionService: $e');
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  /// Convert output package hand_landmarker menjadi model HandLandmark milik project.
  /// Package mengembalikan List<Hand>, tiap Hand punya 21 landmark.
  List<HandLandmark> _convertMediaPipeLandmarks(List<mp.Hand> hands) {
    if (hands.isEmpty) return [];

    final firstHand = hands.first;

    return firstHand.landmarks.map((landmark) {
      return HandLandmark(
        x: landmark.x.clamp(0.0, 1.0),
        y: landmark.y.clamp(0.0, 1.0),
        confidence: 0.95,
      );
    }).toList();
  }

  GestureResultModel _buildDebugGestureResult({
    required String gestureType,
    required List<HandLandmark> landmarks,
  }) {
    switch (gestureType) {
      case 'fist':
        return GestureResultModel(
          gestureType: 'fist',
          action: 'back',
          confidence: 0.85,
          landmarks: landmarks,
          timestamp: DateTime.now(),
        );

      case 'thumbs_up':
        return GestureResultModel(
          gestureType: 'thumbs_up',
          action: 'confirm',
          confidence: 0.95,
          landmarks: landmarks,
          timestamp: DateTime.now(),
        );

      case 'open_palm':
      default:
        return GestureResultModel(
          gestureType: 'open_palm',
          action: 'next',
          confidence: 0.9,
          landmarks: landmarks,
          timestamp: DateTime.now(),
        );
    }
  }

  bool _shouldLogGesture(GestureResultModel result) {
    final now = DateTime.now();

    // Jangan simpan no_hand ke history.
    if (result.gestureType == 'no_hand') {
      return false;
    }

    // Gesture pertama selalu disimpan.
    if (_lastLoggedGestureType == null || _lastLoggedAt == null) {
      return true;
    }

    // Kalau gesture berubah, langsung simpan.
    if (_lastLoggedGestureType != result.gestureType) {
      return true;
    }

    // Kalau gesture sama, simpan ulang hanya setelah jeda tertentu.
    final elapsedMs = now.difference(_lastLoggedAt!).inMilliseconds;
    return elapsedMs >= _sameGestureRelogDelayMs;
  }

  void _updateLastLoggedGesture(GestureResultModel result) {
    _lastLoggedGestureType = result.gestureType;
    _lastLoggedAt = DateTime.now();
  }

  Future<void> _saveGestureLog(GestureResultModel result) async {
    final user = OfflineService.getLoggedInUser();
    final userId = user?['_id']?.toString() ?? 'unknown_user';

    final log = GestureLogModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      gestureType: result.gestureType,
      action: result.action,
      confidence: result.confidence,
      screenContext: 'gesture_camera_page',
      timestamp: result.timestamp,
    );

    await _localLogService.saveGestureLog(log);
  }

  /// Placeholder untuk output landmark detection asli.
  /// Untuk sekarang tetap dipertahankan sebagai fallback/debug.
  List<HandLandmark> _generateMockLandmarks(String gestureType) {
    switch (gestureType) {
      case 'fist':
        return _mockFist();
      case 'thumbs_up':
        return _mockThumbsUp();
      case 'open_palm':
      default:
        return _mockOpenPalm();
    }
  }

  HandLandmark _point(double x, double y) {
    return HandLandmark(
      x: x.clamp(0.0, 1.0),
      y: y.clamp(0.0, 1.0),
      confidence: 0.95,
    );
  }

  /// 21 titik landmark tangan terbuka.
  /// Index mengikuti format umum MediaPipe:
  /// 0 wrist
  /// 1-4 thumb
  /// 5-8 index
  /// 9-12 middle
  /// 13-16 ring
  /// 17-20 pinky
  List<HandLandmark> _mockOpenPalm() {
    return [
      _point(0.50, 0.82), // 0 wrist

      _point(0.42, 0.72), // 1 thumb cmc
      _point(0.34, 0.62), // 2 thumb mcp
      _point(0.27, 0.52), // 3 thumb ip
      _point(0.20, 0.43), // 4 thumb tip

      _point(0.42, 0.62), // 5 index mcp
      _point(0.39, 0.48), // 6 index pip
      _point(0.38, 0.35), // 7 index dip
      _point(0.37, 0.22), // 8 index tip

      _point(0.50, 0.60), // 9 middle mcp
      _point(0.50, 0.44), // 10 middle pip
      _point(0.50, 0.30), // 11 middle dip
      _point(0.50, 0.16), // 12 middle tip

      _point(0.58, 0.62), // 13 ring mcp
      _point(0.61, 0.48), // 14 ring pip
      _point(0.62, 0.35), // 15 ring dip
      _point(0.63, 0.23), // 16 ring tip

      _point(0.66, 0.67), // 17 pinky mcp
      _point(0.71, 0.56), // 18 pinky pip
      _point(0.74, 0.46), // 19 pinky dip
      _point(0.77, 0.36), // 20 pinky tip
    ];
  }

  /// 21 titik dummy untuk fist.
  /// Dibuat menyebar agar terlihat jelas di overlay,
  /// tetapi bentuknya tetap menunjukkan jari-jari terlipat.
  List<HandLandmark> _mockFist() {
    return [
      _point(0.50, 0.82), // 0 wrist

      // Thumb folded across palm
      _point(0.42, 0.72), // 1 thumb cmc
      _point(0.36, 0.66), // 2 thumb mcp
      _point(0.34, 0.59), // 3 thumb ip
      _point(0.40, 0.54), // 4 thumb tip

      // Index folded
      _point(0.40, 0.61), // 5 index mcp
      _point(0.38, 0.52), // 6 index pip
      _point(0.43, 0.48), // 7 index dip
      _point(0.48, 0.53), // 8 index tip

      // Middle folded
      _point(0.50, 0.60), // 9 middle mcp
      _point(0.49, 0.50), // 10 middle pip
      _point(0.53, 0.47), // 11 middle dip
      _point(0.57, 0.53), // 12 middle tip

      // Ring folded
      _point(0.60, 0.61), // 13 ring mcp
      _point(0.61, 0.52), // 14 ring pip
      _point(0.58, 0.48), // 15 ring dip
      _point(0.54, 0.54), // 16 ring tip

      // Pinky folded
      _point(0.68, 0.65), // 17 pinky mcp
      _point(0.69, 0.57), // 18 pinky pip
      _point(0.65, 0.53), // 19 pinky dip
      _point(0.60, 0.58), // 20 pinky tip
    ];
  }

  /// 21 titik dummy untuk thumbs up.
  /// Thumb dibuat tinggi, jari lain dilipat.
  List<HandLandmark> _mockThumbsUp() {
    return [
      _point(0.50, 0.82), // 0 wrist

      _point(0.46, 0.68),
      _point(0.45, 0.52),
      _point(0.45, 0.36),
      _point(0.45, 0.20), // 4 thumb tip tinggi

      _point(0.42, 0.62),
      _point(0.44, 0.58),
      _point(0.47, 0.58),
      _point(0.50, 0.60), // 8 index tip rendah/lipat

      _point(0.50, 0.62),
      _point(0.52, 0.58),
      _point(0.54, 0.58),
      _point(0.56, 0.61), // 12 middle tip rendah/lipat

      _point(0.58, 0.63),
      _point(0.59, 0.59),
      _point(0.60, 0.59),
      _point(0.61, 0.62), // 16 ring tip rendah/lipat

      _point(0.65, 0.67),
      _point(0.64, 0.62),
      _point(0.63, 0.61),
      _point(0.62, 0.64), // 20 pinky tip rendah/lipat
    ];
  }

  void dispose() {
    try {
      _handLandmarker?.dispose();
      _handLandmarker = null;
      debugPrint('✅ HandLandmarker disposed');
    } catch (e) {
      debugPrint('❌ Failed to dispose HandLandmarker: $e');
    }
  }
}