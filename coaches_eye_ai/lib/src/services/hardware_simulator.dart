import 'dart:async';
import 'dart:math';
import '../models/shot_model.dart';

/// Hardware simulator for development and testing
/// Simulates the ESP32 + BNO055 sensor data for cricket bat
class HardwareSimulator {
  Timer? _timer;
  final StreamController<ShotModel> _shotController =
      StreamController<ShotModel>.broadcast();
  final Random _random = Random();
  String? _currentSessionId;
  int _shotCounter = 0;

  /// Get stream of shot data
  Stream<ShotModel> getShotStream() {
    return _shotController.stream;
  }

  /// Start simulating shots for a session
  void startSession(String sessionId) {
    _currentSessionId = sessionId;
    _shotCounter = 0;

    // Emit a shot every 2-3 seconds
    _timer = Timer.periodic(
      Duration(seconds: 2 + _random.nextInt(2)), // 2-3 seconds
      (_) => _emitShot(),
    );
  }

  /// Stop simulating shots
  void stopSession() {
    _timer?.cancel();
    _timer = null;
    _currentSessionId = null;
    _shotCounter = 0;
  }

  /// Emit a simulated shot
  void _emitShot() {
    if (_currentSessionId == null) return;

    _shotCounter++;
    final shotId = '${_currentSessionId}_shot_$_shotCounter';

    final shot = ShotModel(
      shotId: shotId,
      sessionId: _currentSessionId!,
      timestamp: DateTime.now(),
      batSpeed: _generateBatSpeed(),
      powerIndex: _generatePowerIndex(),
      timingScore: _generateTimingScore(),
      sweetSpotAccuracy: _generateSweetSpotAccuracy(),
    );

    _shotController.add(shot);
  }

  /// Generate realistic bat speed (70-130 km/h)
  double _generateBatSpeed() {
    // Most shots are between 80-120 km/h with some outliers
    final baseSpeed = 80.0 + _random.nextDouble() * 40.0; // 80-120
    final variation = (_random.nextDouble() - 0.5) * 20.0; // ±10 variation
    return (baseSpeed + variation).clamp(70.0, 130.0);
  }

  /// Generate power index (60-95)
  int _generatePowerIndex() {
    // Power distribution: mostly 70-90, some excellent shots
    if (_random.nextDouble() < 0.1) {
      // 10% chance of excellent shot (90-95)
      return 90 + _random.nextInt(6);
    } else if (_random.nextDouble() < 0.2) {
      // 20% chance of good shot (80-89)
      return 80 + _random.nextInt(10);
    } else {
      // 70% chance of average shot (60-79)
      return 60 + _random.nextInt(20);
    }
  }

  /// Generate timing score (-25 to +25 ms)
  double _generateTimingScore() {
    // Most shots are close to perfect timing
    if (_random.nextDouble() < 0.3) {
      // 30% chance of perfect timing
      return 0.0;
    } else if (_random.nextDouble() < 0.6) {
      // 30% chance of slightly early/late (±5ms)
      return (_random.nextDouble() - 0.5) * 10.0;
    } else {
      // 40% chance of more noticeable timing issues (±25ms)
      return (_random.nextDouble() - 0.5) * 50.0;
    }
  }

  /// Generate sweet spot accuracy (0.7-1.0)
  double _generateSweetSpotAccuracy() {
    // Most shots hit the sweet spot well
    if (_random.nextDouble() < 0.2) {
      // 20% chance of perfect sweet spot
      return 1.0;
    } else if (_random.nextDouble() < 0.5) {
      // 30% chance of very good sweet spot (0.9-1.0)
      return 0.9 + _random.nextDouble() * 0.1;
    } else {
      // 50% chance of good sweet spot (0.7-0.9)
      return 0.7 + _random.nextDouble() * 0.2;
    }
  }

  /// Simulate a specific type of shot (for testing)
  ShotModel simulateSpecificShot({
    required String sessionId,
    required String shotId,
    double? batSpeed,
    int? powerIndex,
    double? timingScore,
    double? sweetSpotAccuracy,
  }) {
    return ShotModel(
      shotId: shotId,
      sessionId: sessionId,
      timestamp: DateTime.now(),
      batSpeed: batSpeed ?? _generateBatSpeed(),
      powerIndex: powerIndex ?? _generatePowerIndex(),
      timingScore: timingScore ?? _generateTimingScore(),
      sweetSpotAccuracy: sweetSpotAccuracy ?? _generateSweetSpotAccuracy(),
    );
  }

  /// Get shot statistics for the current session
  Map<String, dynamic> getSessionStats() {
    return {
      'totalShots': _shotCounter,
      'isActive': _currentSessionId != null,
      'sessionId': _currentSessionId,
    };
  }

  /// Dispose resources
  void dispose() {
    stopSession();
    _shotController.close();
  }
}
