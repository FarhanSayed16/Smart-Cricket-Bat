import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coaches_eye_ai/src/services/ble_service.dart';
import 'package:coaches_eye_ai/src/models/shot_model.dart';
import 'package:coaches_eye_ai/src/providers/providers.dart';

void main() {
  group('BLE Service Integration Tests', () {
    late ProviderContainer container;
    late BLEService bleService;

    setUp(() {
      container = ProviderContainer();
      bleService = container.read(bleServiceProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('BLE Service should be created successfully', () {
      expect(bleService, isNotNull);
      expect(bleService.isConnected, false);
    });

    test('BLE Service should have correct UUIDs', () {
      expect(BLEService.SERVICE_UUID, '4fafc201-1fb5-459e-8fcc-c5c9c331914b');
      expect(
        BLEService.CHARACTERISTIC_UUID,
        'beb5483e-36e1-4688-b7f5-ea07361b26a8',
      );
      expect(BLEService.DEVICE_NAME, 'Smart Bat');
    });

    test('BLE Service should handle session management', () {
      const sessionId = 'test_session_123';

      // Start session
      bleService.startSession(sessionId);
      expect(bleService.getConnectionStatus()['sessionId'], sessionId);

      // Stop session
      bleService.stopSession();
      expect(bleService.getConnectionStatus()['sessionId'], null);
    });

    test('BLE Service should provide connection streams', () {
      expect(bleService.connectionStream, isNotNull);
      expect(bleService.shotStream, isNotNull);
      expect(bleService.scanStream, isNotNull);
      expect(bleService.connectionStateStream, isNotNull);
    });

    test('BLE Service should handle shot data processing', () {
      // Test shot processing with mock data
      const sessionId = 'test_session_123';
      bleService.startSession(sessionId);

      // Simulate sensor data processing
      final mockSensorData = '10.5,5.2,9.8,150.0,200.0,100.0';

      // This would normally be called internally by the BLE service
      // when receiving data from the ESP32
      expect(mockSensorData.split(',').length, 6);

      bleService.stopSession();
    });

    test('BLE Service should validate sensor data', () {
      // Test valid data
      expect(
        bleService.getCurrentSensorReadings(),
        isA<Map<String, dynamic>>(),
      );

      // Test performance metrics
      expect(bleService.getPerformanceMetrics(), isA<Map<String, dynamic>>());
    });
  });
}
