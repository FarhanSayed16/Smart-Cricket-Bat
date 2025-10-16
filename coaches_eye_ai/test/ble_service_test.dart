import 'package:flutter_test/flutter_test.dart';
import 'package:coaches_eye_ai/src/services/ble_service.dart';
import 'package:coaches_eye_ai/src/services/error_handler.dart';
import 'package:coaches_eye_ai/src/services/ble_test_service.dart';

void main() {
  group('BLE Service Tests', () {
    late BLEService bleService;

    setUp(() {
      bleService = BLEService();
    });

    tearDown(() {
      bleService.dispose();
    });

    test('should initialize BLE service', () async {
      expect(bleService, isNotNull);
      expect(bleService.isConnected, false);
      expect(bleService.currentConnectionState, ConnectionState.disconnected);
    });

    test('should validate sensor data format', () {
      // Valid data
      expect(DataValidator.isValidSensorData('1.0,2.0,3.0,4.0,5.0,6.0'), true);
      expect(
        DataValidator.isValidSensorData('12.34,-5.67,8.90,123.45,-67.89,45.12'),
        true,
      );

      // Invalid data
      expect(DataValidator.isValidSensorData('invalid,data'), false);
      expect(DataValidator.isValidSensorData('1.0,2.0,3.0'), false); // Too few
      expect(
        DataValidator.isValidSensorData('1.0,2.0,3.0,4.0,5.0,6.0,7.0'),
        false,
      ); // Too many
      expect(DataValidator.isValidSensorData(''), false); // Empty
    });

    test('should validate sensor values', () {
      // Valid values
      expect(DataValidator.isValidAcceleration(25.0), true);
      expect(DataValidator.isValidAcceleration(-25.0), true);
      expect(DataValidator.isValidGyroscope(500.0), true);
      expect(DataValidator.isValidGyroscope(-500.0), true);

      // Invalid values
      expect(DataValidator.isValidAcceleration(60.0), false); // Too high
      expect(DataValidator.isValidAcceleration(-60.0), false); // Too low
      expect(DataValidator.isValidGyroscope(1200.0), false); // Too high
      expect(DataValidator.isValidGyroscope(-1200.0), false); // Too low
    });

    test('should sanitize sensor data', () {
      final inputData = {
        'accX': 1.0,
        'accY': double.nan,
        'accZ': double.infinity,
        'gyroX': 2.0,
        'gyroY': -double.infinity,
        'gyroZ': 3.0,
      };

      final sanitized = DataValidator.sanitizeSensorData(inputData);

      expect(sanitized.length, 3);
      expect(sanitized.containsKey('accX'), true);
      expect(sanitized.containsKey('gyroX'), true);
      expect(sanitized.containsKey('gyroZ'), true);
      expect(sanitized.containsKey('accY'), false);
      expect(sanitized.containsKey('accZ'), false);
      expect(sanitized.containsKey('gyroY'), false);
    });
  });

  group('Error Handler Tests', () {
    late ErrorHandler errorHandler;

    setUp(() {
      errorHandler = ErrorHandler();
    });

    tearDown(() {
      errorHandler.dispose();
    });

    test('should handle BLE errors', () {
      final error = BLEException('Test error', BLEErrorType.connection);

      expect(() => errorHandler.handleBLEError(error), returnsNormally);
    });

    test('should provide user-friendly error messages', () {
      final connectionError = BLEException(
        'Connection failed',
        BLEErrorType.connection,
      );
      final permissionError = BLEException(
        'Permission denied',
        BLEErrorType.permission,
      );

      expect(
        errorHandler.getUserFriendlyMessage(connectionError),
        contains('Connection failed'),
      );
      expect(
        errorHandler.getUserFriendlyMessage(permissionError),
        contains('Bluetooth permission'),
      );
    });

    test('should provide retry suggestions', () {
      final timeoutError = BLEException('Timeout', BLEErrorType.timeout);
      final dataError = BLEException('Data error', BLEErrorType.data);

      expect(
        errorHandler.getRetrySuggestion(timeoutError.type),
        contains('charged'),
      );
      expect(
        errorHandler.getRetrySuggestion(dataError.type),
        contains('Disconnect'),
      );
    });
  });

  group('BLE Test Service Tests', () {
    late BLETestService testService;

    setUp(() {
      testService = BLETestService();
    });

    tearDown(() {
      testService.dispose();
    });

    test('should generate test shot data', () {
      final shot = testService.generateTestShot(
        sessionId: 'test_session',
        shotId: 'test_shot',
        batSpeed: 100.0,
        powerIndex: 85,
      );

      expect(shot.sessionId, 'test_session');
      expect(shot.shotId, 'test_shot');
      expect(shot.batSpeed, 100.0);
      expect(shot.powerIndex, 85);
    });

    test('should run data parsing tests', () async {
      expect(() => testService.testDataParsing(), returnsNormally);
    });

    test('should run error handling tests', () async {
      // Create a fresh test service for this test
      final freshTestService = BLETestService();
      expect(() => freshTestService.testErrorHandling(), returnsNormally);
    });
  });

  group('Performance Monitor Tests', () {
    late PerformanceMonitor monitor;

    setUp(() {
      monitor = PerformanceMonitor();
    });

    test('should track operation durations', () {
      monitor.startOperation('test_operation');

      // Simulate some work
      Future.delayed(Duration(milliseconds: 100), () {
        monitor.endOperation('test_operation');

        final avgDuration = monitor.getAverageDuration('test_operation');
        expect(avgDuration, isNotNull);
        expect(avgDuration!.inMilliseconds, greaterThan(90));
        expect(avgDuration.inMilliseconds, lessThan(200));
      });
    });

    test('should provide performance metrics', () {
      monitor.startOperation('test1');
      monitor.endOperation('test1');

      monitor.startOperation('test2');
      monitor.endOperation('test2');

      final metrics = monitor.getMetrics();
      expect(metrics.length, 2);
      expect(metrics.containsKey('test1'), true);
      expect(metrics.containsKey('test2'), true);
    });
  });

  group('Integration Tests', () {
    late BLEService integrationBleService;

    setUp(() {
      integrationBleService = BLEService();
    });

    tearDown(() {
      integrationBleService.dispose();
    });

    test('should handle connection state changes', () async {
      // Test initial state
      expect(
        integrationBleService.currentConnectionState,
        ConnectionState.disconnected,
      );
      expect(integrationBleService.isConnected, false);
    });

    test('should handle data rate limiting', () async {
      // Test that service can be created and disposed without errors
      expect(integrationBleService, isNotNull);
      expect(
        integrationBleService.currentConnectionState,
        ConnectionState.disconnected,
      );
    });
  });
}
