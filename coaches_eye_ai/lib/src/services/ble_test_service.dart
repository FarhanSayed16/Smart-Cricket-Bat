import 'dart:async';
import 'dart:math';
import '../models/shot_model.dart';
import 'ble_service.dart';
import 'error_handler.dart';

/// Comprehensive testing service for BLE functionality
class BLETestService {
  static final BLETestService _instance = BLETestService._internal();
  factory BLETestService() => _instance;
  BLETestService._internal();

  final Random _random = Random();
  Timer? _testTimer;
  bool _isRunning = false;

  /// Test data parsing with various scenarios
  Future<void> testDataParsing() async {
    print('Starting data parsing tests...');

    final testCases = [
      // Valid data
      '1.0,2.0,3.0,4.0,5.0,6.0',
      '12.34,-5.67,8.90,123.45,-67.89,45.12',

      // Invalid data
      'invalid,data,format',
      '1.0,2.0,3.0', // Too few values
      '1.0,2.0,3.0,4.0,5.0,6.0,7.0', // Too many values
      'NaN,Infinity,-Infinity,1.0,2.0,3.0', // Invalid numbers
      '', // Empty string
    ];

    for (final testCase in testCases) {
      final isValid = DataValidator.isValidSensorData(testCase);
      print('Test case: "$testCase" -> Valid: $isValid');
    }

    print('Data parsing tests completed');
  }

  /// Test connection scenarios
  Future<void> testConnectionScenarios() async {
    print('Starting connection scenario tests...');

    // Test 1: Connection timeout
    await _testConnectionTimeout();

    // Test 2: Invalid service discovery
    await _testInvalidServiceDiscovery();

    // Test 3: Characteristic not found
    await _testCharacteristicNotFound();

    print('Connection scenario tests completed');
  }

  /// Test data transmission with various rates
  Future<void> testDataTransmission() async {
    print('Starting data transmission tests...');

    // Test normal data rate (20Hz)
    await _testDataRate(20);

    // Test high data rate (50Hz)
    await _testDataRate(50);

    // Test low data rate (5Hz)
    await _testDataRate(5);

    print('Data transmission tests completed');
  }

  /// Test shot detection with simulated data
  Future<void> testShotDetection() async {
    print('Starting shot detection tests...');

    final testShots = [
      // Strong shot
      {
        'accX': 20.0,
        'accY': 15.0,
        'accZ': 25.0,
        'gyroX': 300.0,
        'gyroY': 250.0,
        'gyroZ': 200.0,
      },

      // Weak shot
      {
        'accX': 5.0,
        'accY': 3.0,
        'accZ': 7.0,
        'gyroX': 50.0,
        'gyroY': 40.0,
        'gyroZ': 60.0,
      },

      // Edge case - just above threshold
      {
        'accX': 15.1,
        'accY': 0.0,
        'accZ': 0.0,
        'gyroX': 0.0,
        'gyroY': 0.0,
        'gyroZ': 0.0,
      },

      // Edge case - just below threshold
      {
        'accX': 14.9,
        'accY': 0.0,
        'accZ': 0.0,
        'gyroX': 0.0,
        'gyroY': 0.0,
        'gyroZ': 0.0,
      },
    ];

    for (final shot in testShots) {
      final accMag = sqrt(
        pow(shot['accX']!, 2) + pow(shot['accY']!, 2) + pow(shot['accZ']!, 2),
      );
      final gyroMag = sqrt(
        pow(shot['gyroX']!, 2) +
            pow(shot['gyroY']!, 2) +
            pow(shot['gyroZ']!, 2),
      );

      final isShot = accMag > 15.0 || gyroMag > 200.0;
      print('Shot test: acc=$accMag, gyro=$gyroMag -> Detected: $isShot');
    }

    print('Shot detection tests completed');
  }

  /// Test error handling scenarios
  Future<void> testErrorHandling() async {
    print('Starting error handling tests...');

    final errorHandler = ErrorHandler();

    // Test different error types
    final testErrors = [
      BLEException('Connection failed', BLEErrorType.connection),
      BLEException('Permission denied', BLEErrorType.permission),
      BLEException('Data corruption', BLEErrorType.data),
      BLEException('Timeout occurred', BLEErrorType.timeout),
      BLEException('Unknown error', BLEErrorType.unknown),
    ];

    for (final error in testErrors) {
      errorHandler.handleBLEError(error, context: 'Test');
      final userMessage = errorHandler.getUserFriendlyMessage(error);
      final retrySuggestion = errorHandler.getRetrySuggestion(error.type);

      print('Error: ${error.message}');
      print('User message: $userMessage');
      print('Retry suggestion: $retrySuggestion');
    }

    print('Error handling tests completed');
  }

  /// Test performance metrics
  Future<void> testPerformanceMetrics() async {
    print('Starting performance metrics tests...');

    final monitor = PerformanceMonitor();

    // Simulate various operations
    for (int i = 0; i < 10; i++) {
      monitor.startOperation('connection');
      await Future.delayed(Duration(milliseconds: 100 + _random.nextInt(200)));
      monitor.endOperation('connection');

      monitor.startOperation('data_parsing');
      await Future.delayed(Duration(milliseconds: 10 + _random.nextInt(50)));
      monitor.endOperation('data_parsing');
    }

    final metrics = monitor.getMetrics();
    print('Performance metrics: $metrics');

    print('Performance metrics tests completed');
  }

  /// Run all tests
  Future<void> runAllTests() async {
    print('Running comprehensive BLE tests...');

    try {
      await testDataParsing();
      await testConnectionScenarios();
      await testDataTransmission();
      await testShotDetection();
      await testErrorHandling();
      await testPerformanceMetrics();

      print('All tests completed successfully');
    } catch (e) {
      print('Test suite failed: $e');
      ErrorHandler().handleError(e, context: 'Test Suite');
    }
  }

  /// Test connection timeout scenario
  Future<void> _testConnectionTimeout() async {
    print('Testing connection timeout...');
    // Simulate timeout scenario
    try {
      await Future.delayed(Duration(seconds: 35)); // Longer than timeout
      throw BLEException('Connection timeout', BLEErrorType.timeout);
    } catch (e) {
      ErrorHandler().handleError(e, context: 'Connection Timeout Test');
    }
  }

  /// Test invalid service discovery
  Future<void> _testInvalidServiceDiscovery() async {
    print('Testing invalid service discovery...');
    try {
      throw BLEException('Target service not found', BLEErrorType.connection);
    } catch (e) {
      ErrorHandler().handleError(e, context: 'Service Discovery Test');
    }
  }

  /// Test characteristic not found
  Future<void> _testCharacteristicNotFound() async {
    print('Testing characteristic not found...');
    try {
      throw BLEException(
        'Data characteristic not found',
        BLEErrorType.connection,
      );
    } catch (e) {
      ErrorHandler().handleError(e, context: 'Characteristic Test');
    }
  }

  /// Test data rate handling
  Future<void> _testDataRate(int rateHz) async {
    print('Testing data rate: ${rateHz}Hz');

    final intervalMs = 1000 ~/ rateHz;
    final testDuration = Duration(seconds: 5);
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < testDuration) {
      // Simulate data packet
      final data =
          '${_random.nextDouble() * 20 - 10},'
          '${_random.nextDouble() * 20 - 10},'
          '${_random.nextDouble() * 20 - 10},'
          '${_random.nextDouble() * 400 - 200},'
          '${_random.nextDouble() * 400 - 200},'
          '${_random.nextDouble() * 400 - 200}';

      // Test data validation
      final isValid = DataValidator.isValidSensorData(data);
      if (!isValid) {
        print('Invalid data detected at ${rateHz}Hz: $data');
      }

      await Future.delayed(Duration(milliseconds: intervalMs));
    }

    print('Data rate test completed for ${rateHz}Hz');
  }

  /// Generate test shot data
  ShotModel generateTestShot({
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
      batSpeed: batSpeed ?? 80.0 + _random.nextDouble() * 40.0,
      powerIndex: powerIndex ?? _random.nextInt(100),
      timingScore: timingScore ?? (_random.nextDouble() - 0.5) * 30.0,
      sweetSpotAccuracy: sweetSpotAccuracy ?? 0.7 + _random.nextDouble() * 0.3,
    );
  }

  /// Start continuous testing
  void startContinuousTesting() {
    if (_isRunning) return;

    _isRunning = true;
    _testTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _runContinuousTest();
    });

    print('Continuous testing started');
  }

  /// Stop continuous testing
  void stopContinuousTesting() {
    _testTimer?.cancel();
    _testTimer = null;
    _isRunning = false;
    print('Continuous testing stopped');
  }

  /// Run continuous test
  void _runContinuousTest() {
    print('Running continuous test...');
    // Run basic validation tests
    testDataParsing();
  }

  void dispose() {
    stopContinuousTesting();
  }
}
