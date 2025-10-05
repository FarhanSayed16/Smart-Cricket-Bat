import 'dart:async';
import 'dart:math';
import '../models/shot_model.dart';

/// ESP32 + BNO055 sensor simulator for cricket bat
/// Simulates realistic sensor data from accelerometer, gyroscope, and magnetometer
class HardwareSimulator {
  Timer? _timer;
  final StreamController<ShotModel> _shotController =
      StreamController<ShotModel>.broadcast();
  final Random _random = Random();
  String? _currentSessionId;
  int _shotCounter = 0;

  // ESP32 sensor simulation parameters
  double _lastAccelerationX = 0.0;
  double _lastAccelerationY = 0.0;
  double _lastAccelerationZ = 0.0;
  double _lastGyroX = 0.0;
  double _lastGyroY = 0.0;
  double _lastGyroZ = 0.0;

  // Shot detection thresholds (realistic values)
  static const double _accelerationThreshold = 15.0; // m/s²
  static const double _gyroThreshold = 200.0; // degrees/s

  /// Get stream of shot data
  Stream<ShotModel> getShotStream() {
    return _shotController.stream;
  }

  /// Start simulating shots for a session
  void startSession(String sessionId) {
    _currentSessionId = sessionId;
    _shotCounter = 0;

    // Simulate ESP32 sensor readings every 50ms (20Hz sampling rate)
    _timer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _simulateSensorReading(),
    );
  }

  /// Stop simulating shots
  void stopSession() {
    _timer?.cancel();
    _timer = null;
    _currentSessionId = null;
    _shotCounter = 0;
  }

  /// Simulate ESP32 sensor readings and detect shots
  void _simulateSensorReading() {
    if (_currentSessionId == null) return;

    // Simulate realistic sensor noise and movement
    _lastAccelerationX += (_random.nextDouble() - 0.5) * 2.0;
    _lastAccelerationY += (_random.nextDouble() - 0.5) * 2.0;
    _lastAccelerationZ += (_random.nextDouble() - 0.5) * 2.0;

    _lastGyroX += (_random.nextDouble() - 0.5) * 10.0;
    _lastGyroY += (_random.nextDouble() - 0.5) * 10.0;
    _lastGyroZ += (_random.nextDouble() - 0.5) * 10.0;

    // Apply gravity to Z-axis (bat is typically held vertically)
    _lastAccelerationZ += 9.81;

    // Detect shot based on acceleration and gyroscope thresholds
    final accelerationMagnitude = sqrt(
      pow(_lastAccelerationX, 2) +
          pow(_lastAccelerationY, 2) +
          pow(_lastAccelerationZ, 2),
    );

    final gyroMagnitude = sqrt(
      pow(_lastGyroX, 2) + pow(_lastGyroY, 2) + pow(_lastGyroZ, 2),
    );

    // Shot detected if acceleration or gyro exceeds thresholds
    if (accelerationMagnitude > _accelerationThreshold ||
        gyroMagnitude > _gyroThreshold) {
      _detectShot(accelerationMagnitude, gyroMagnitude);
    }
  }

  /// Detect and process a cricket shot
  void _detectShot(double accelerationMagnitude, double gyroMagnitude) {
    _shotCounter++;
    final shotId = '${_currentSessionId}_shot_$_shotCounter';

    // Calculate realistic shot parameters based on sensor data
    final batSpeed = _calculateBatSpeed(accelerationMagnitude, gyroMagnitude);
    final powerIndex = _calculatePowerIndex(accelerationMagnitude);
    final timingScore = _calculateTimingScore();
    final sweetSpotAccuracy = _calculateSweetSpotAccuracy(
      accelerationMagnitude,
    );

    final shot = ShotModel(
      shotId: shotId,
      sessionId: _currentSessionId!,
      timestamp: DateTime.now(),
      batSpeed: batSpeed,
      powerIndex: powerIndex,
      timingScore: timingScore,
      sweetSpotAccuracy: sweetSpotAccuracy,
    );

    _shotController.add(shot);

    // Reset sensor values after shot detection
    _resetSensorValues();
  }

  /// Calculate bat speed based on sensor data (km/h)
  double _calculateBatSpeed(double acceleration, double gyro) {
    // Realistic bat speed calculation based on acceleration and angular velocity
    // Professional cricket bats typically reach 120-140 km/h
    final baseSpeed = 80.0 + (acceleration * 2.0) + (gyro * 0.1);
    return baseSpeed.clamp(60.0, 150.0);
  }

  /// Calculate power index (0-100) based on acceleration
  int _calculatePowerIndex(double acceleration) {
    // Power correlates with acceleration magnitude
    final power = (acceleration * 3.0).clamp(0.0, 100.0);
    return power.round();
  }

  /// Calculate timing score (-50 to +50 ms)
  double _calculateTimingScore() {
    // Timing depends on swing consistency
    final timingVariation = (_random.nextDouble() - 0.5) * 30.0;
    return timingVariation.clamp(-50.0, 50.0);
  }

  /// Calculate sweet spot accuracy (0.0-1.0)
  double _calculateSweetSpotAccuracy(double acceleration) {
    // Sweet spot accuracy depends on acceleration consistency
    final baseAccuracy = 0.7 + (acceleration / 50.0);
    return baseAccuracy.clamp(0.0, 1.0);
  }

  /// Reset sensor values after shot detection
  void _resetSensorValues() {
    _lastAccelerationX = 0.0;
    _lastAccelerationY = 0.0;
    _lastAccelerationZ = 0.0;
    _lastGyroX = 0.0;
    _lastGyroY = 0.0;
    _lastGyroZ = 0.0;
  }

  /// Get current sensor readings for debugging
  Map<String, double> getCurrentSensorReadings() {
    return {
      'accelerationX': _lastAccelerationX,
      'accelerationY': _lastAccelerationY,
      'accelerationZ': _lastAccelerationZ,
      'gyroX': _lastGyroX,
      'gyroY': _lastGyroY,
      'gyroZ': _lastGyroZ,
    };
  }

  /// Simulate a manual shot trigger (for testing)
  void triggerManualShot() {
    if (_currentSessionId == null) return;

    // Simulate a strong shot
    _detectShot(25.0, 300.0);
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
      batSpeed: batSpeed ?? _calculateBatSpeed(20.0, 250.0),
      powerIndex: powerIndex ?? _calculatePowerIndex(20.0),
      timingScore: timingScore ?? _calculateTimingScore(),
      sweetSpotAccuracy: sweetSpotAccuracy ?? _calculateSweetSpotAccuracy(20.0),
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
