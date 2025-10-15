# Comprehensive Testing Guide for Smart Cricket Bat App

## Testing Strategy Overview

This guide covers all aspects of testing the Smart Cricket Bat app, from unit tests to hardware integration tests.

## 1. Unit Tests

### BLE Service Tests

```dart
// test/unit/ble_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../lib/src/services/ble_service.dart';

@GenerateMocks([BluetoothDevice, BluetoothCharacteristic])
void main() {
  group('BLEService Unit Tests', () {
    late BLEService bleService;
    late MockBluetoothDevice mockDevice;
    late MockBluetoothCharacteristic mockCharacteristic;

    setUp(() {
      bleService = BLEService();
      mockDevice = MockBluetoothDevice();
      mockCharacteristic = MockBluetoothCharacteristic();
    });

    test('should initialize with disconnected state', () {
      expect(bleService.isConnected, false);
      expect(bleService.currentConnectionState, ConnectionState.disconnected);
    });

    test('should validate sensor data format', () {
      // Valid data
      expect(DataValidator.isValidSensorData('1.0,2.0,3.0,4.0,5.0,6.0'), true);
      
      // Invalid data
      expect(DataValidator.isValidSensorData('invalid,data'), false);
      expect(DataValidator.isValidSensorData('1.0,2.0,3.0'), false);
    });

    test('should handle connection timeout', () async {
      when(mockDevice.connect(timeout: anyNamed('timeout')))
          .thenThrow(TimeoutException('Connection timeout', Duration(seconds: 30)));
      
      expect(
        () => bleService.connectToDevice(mockDevice),
        throwsA(isA<BLEException>()),
      );
    });

    test('should implement exponential backoff for reconnection', () async {
      // Test reconnection logic
      final attempts = <Duration>[];
      
      // Simulate connection failures
      for (int i = 0; i < 3; i++) {
        // Mock connection failure
        when(mockDevice.connect(timeout: anyNamed('timeout')))
            .thenThrow(Exception('Connection failed'));
        
        try {
          await bleService.connectToDevice(mockDevice);
        } catch (e) {
          // Expected to fail
        }
      }
      
      // Verify backoff timing
      expect(bleService._reconnectAttempts, equals(3));
    });

    test('should rate limit incoming data', () async {
      // Send data faster than rate limit
      for (int i = 0; i < 100; i++) {
        bleService._handleIncomingData([1, 2, 3, 4, 5, 6]);
      }
      
      // Should not exceed rate limit
      expect(bleService._dataCount, lessThanOrEqualTo(20)); // 20Hz limit
    });

    test('should validate sensor values within ranges', () {
      // Valid acceleration
      expect(DataValidator.isValidAcceleration(25.0), true);
      expect(DataValidator.isValidAcceleration(-25.0), true);
      
      // Invalid acceleration
      expect(DataValidator.isValidAcceleration(60.0), false);
      expect(DataValidator.isValidAcceleration(-60.0), false);
      
      // Valid gyroscope
      expect(DataValidator.isValidGyroscope(500.0), true);
      expect(DataValidator.isValidGyroscope(-500.0), true);
      
      // Invalid gyroscope
      expect(DataValidator.isValidGyroscope(1200.0), false);
      expect(DataValidator.isValidGyroscope(-1200.0), false);
    });
  });
}
```

### Error Handler Tests

```dart
// test/unit/error_handler_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../lib/src/services/error_handler.dart';
import '../lib/src/services/ble_service.dart';

void main() {
  group('ErrorHandler Tests', () {
    late ErrorHandler errorHandler;

    setUp(() {
      errorHandler = ErrorHandler();
    });

    tearDown(() {
      errorHandler.dispose();
    });

    test('should provide user-friendly error messages', () {
      final connectionError = BLEException('Connection failed', BLEErrorType.connection);
      final permissionError = BLEException('Permission denied', BLEErrorType.permission);
      
      expect(
        errorHandler.getUserFriendlyMessage(connectionError),
        contains('Connection failed'),
      );
      
      expect(
        errorHandler.getUserFriendlyMessage(permissionError),
        contains('Bluetooth permission'),
      );
    });

    test('should provide appropriate retry suggestions', () {
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

    test('should handle error stream', () async {
      final error = BLEException('Test error', BLEErrorType.unknown);
      
      // Listen to error stream
      final errors = <BLEException>[];
      final subscription = errorHandler.errorStream.listen(errors.add);
      
      // Trigger error
      errorHandler.handleBLEError(error);
      
      // Wait for stream
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(errors.length, 1);
      expect(errors.first, equals(error));
      
      await subscription.cancel();
    });
  });
}
```

## 2. Integration Tests

### BLE Integration Tests

```dart
// integration_test/ble_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:coaches_eye_ai/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('BLE Integration Tests', () {
    testWidgets('should scan for devices', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to device scan screen
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      // Start scanning
      await tester.tap(find.text('Scan for Smart Bat'));
      await tester.pumpAndSettle();

      // Wait for scan results
      await tester.pump(Duration(seconds: 5));

      // Verify scan button state
      expect(find.text('Scanning...'), findsOneWidget);
    });

    testWidgets('should handle connection errors gracefully', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to device scan screen
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      // Start scanning
      await tester.tap(find.text('Scan for Smart Bat'));
      await tester.pumpAndSettle();

      // Wait for scan to complete
      await tester.pump(Duration(seconds: 15));

      // Verify error handling
      expect(find.text('No Smart Bat devices found'), findsOneWidget);
    });

    testWidgets('should display connection status', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Check initial connection status
      expect(find.text('Not Connected'), findsOneWidget);

      // Navigate to device scan screen
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      // Verify connection status display
      expect(find.text('Smart Bat Connection'), findsOneWidget);
    });
  });
}
```

## 3. Hardware Integration Tests

### ESP32 Communication Tests

```dart
// test/hardware/esp32_communication_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../lib/src/services/ble_service.dart';

void main() {
  group('ESP32 Communication Tests', () {
    late BLEService bleService;

    setUp(() {
      bleService = BLEService();
    });

    tearDown(() {
      bleService.dispose();
    });

    test('should parse ESP32 sensor data format', () {
      // Test data format: "accX,accY,accZ,gyroX,gyroY,gyroZ"
      final testData = "12.34,-5.67,8.90,123.45,-67.89,45.12";
      
      expect(DataValidator.isValidSensorData(testData), true);
      
      final values = testData.split(',').map((e) => double.parse(e)).toList();
      expect(values.length, 6);
      expect(values[0], 12.34);
      expect(values[1], -5.67);
      expect(values[2], 8.90);
      expect(values[3], 123.45);
      expect(values[4], -67.89);
      expect(values[5], 45.12);
    });

    test('should detect shots from sensor data', () {
      // Strong shot data
      final strongShotData = "20.0,15.0,25.0,300.0,250.0,200.0";
      
      // Parse and calculate magnitudes
      final values = strongShotData.split(',').map((e) => double.parse(e)).toList();
      final accMag = sqrt(pow(values[0], 2) + pow(values[1], 2) + pow(values[2], 2));
      final gyroMag = sqrt(pow(values[3], 2) + pow(values[4], 2) + pow(values[5], 2));
      
      // Should detect shot
      expect(accMag > 15.0 || gyroMag > 200.0, true);
      
      // Weak shot data
      final weakShotData = "5.0,3.0,7.0,50.0,40.0,60.0";
      final weakValues = weakShotData.split(',').map((e) => double.parse(e)).toList();
      final weakAccMag = sqrt(pow(weakValues[0], 2) + pow(weakValues[1], 2) + pow(weakValues[2], 2));
      final weakGyroMag = sqrt(pow(weakValues[3], 2) + pow(weakValues[4], 2) + pow(weakValues[5], 2));
      
      // Should not detect shot
      expect(weakAccMag > 15.0 || weakGyroMag > 200.0, false);
    });

    test('should handle malformed ESP32 data', () {
      final malformedData = [
        "invalid,data,format",
        "1.0,2.0,3.0", // Too few values
        "1.0,2.0,3.0,4.0,5.0,6.0,7.0", // Too many values
        "NaN,Infinity,-Infinity,1.0,2.0,3.0", // Invalid numbers
        "", // Empty string
      ];

      for (final data in malformedData) {
        expect(DataValidator.isValidSensorData(data), false);
      }
    });

    test('should handle high-frequency data from ESP32', () async {
      // Simulate ESP32 sending data at 50Hz
      final startTime = DateTime.now();
      int dataCount = 0;
      
      while (DateTime.now().difference(startTime).inSeconds < 2) {
        bleService._handleIncomingData([1, 2, 3, 4, 5, 6]);
        dataCount++;
        await Future.delayed(Duration(milliseconds: 20)); // 50Hz
      }
      
      // Should be rate limited
      expect(bleService._dataCount, lessThanOrEqualTo(40)); // 20Hz * 2 seconds
    });
  });
}
```

## 4. Performance Tests

### Memory and Performance Tests

```dart
// test/performance/performance_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'dart:developer' as developer;
import '../lib/src/services/ble_service.dart';
import '../lib/src/services/performance_monitor.dart';

void main() {
  group('Performance Tests', () {
    late BLEService bleService;
    late PerformanceMonitor monitor;

    setUp(() {
      bleService = BLEService();
      monitor = PerformanceMonitor();
    });

    tearDown(() {
      bleService.dispose();
    });

    test('should not leak memory during data processing', () async {
      final initialMemory = _getMemoryUsage();
      
      // Process large amount of data
      for (int i = 0; i < 1000; i++) {
        bleService._handleIncomingData([1, 2, 3, 4, 5, 6]);
        await Future.delayed(Duration(milliseconds: 1));
      }
      
      // Force garbage collection
      await Future.delayed(Duration(seconds: 1));
      
      final finalMemory = _getMemoryUsage();
      final memoryIncrease = finalMemory - initialMemory;
      
      // Memory increase should be reasonable (< 10MB)
      expect(memoryIncrease, lessThan(10 * 1024 * 1024));
    });

    test('should maintain performance under load', () async {
      monitor.startOperation('data_processing');
      
      // Process data under load
      for (int i = 0; i < 100; i++) {
        bleService._handleIncomingData([1, 2, 3, 4, 5, 6]);
      }
      
      monitor.endOperation('data_processing');
      
      final avgDuration = monitor.getAverageDuration('data_processing');
      expect(avgDuration!.inMilliseconds, lessThan(100)); // Should be fast
    });

    test('should handle connection state changes efficiently', () async {
      monitor.startOperation('connection_state_change');
      
      // Simulate rapid state changes
      for (int i = 0; i < 100; i++) {
        bleService._connectionStateController.add(ConnectionState.connecting);
        bleService._connectionStateController.add(ConnectionState.connected);
        bleService._connectionStateController.add(ConnectionState.disconnected);
      }
      
      monitor.endOperation('connection_state_change');
      
      final avgDuration = monitor.getAverageDuration('connection_state_change');
      expect(avgDuration!.inMilliseconds, lessThan(50)); // Should be very fast
    });
  });
}

int _getMemoryUsage() {
  // This would be implemented with platform-specific memory monitoring
  return 0; // Placeholder
}
```

## 5. Manual Testing Procedures

### Device Connection Testing

1. **Bluetooth Permission Testing**
   - [ ] Test on Android 12+ (runtime permissions)
   - [ ] Test on Android 6-11 (legacy permissions)
   - [ ] Test on iOS 14+ (Bluetooth permissions)
   - [ ] Verify permission denial handling

2. **Device Discovery Testing**
   - [ ] Test with Smart Bat powered on
   - [ ] Test with Smart Bat powered off
   - [ ] Test with Smart Bat in pairing mode
   - [ ] Test with multiple BLE devices nearby
   - [ ] Test scanning timeout scenarios

3. **Connection Testing**
   - [ ] Test successful connection
   - [ ] Test connection timeout
   - [ ] Test connection failure scenarios
   - [ ] Test automatic reconnection
   - [ ] Test manual disconnection

### Data Transmission Testing

1. **Sensor Data Testing**
   - [ ] Test with valid sensor data
   - [ ] Test with malformed data
   - [ ] Test with high-frequency data
   - [ ] Test with low-frequency data
   - [ ] Test data validation and filtering

2. **Shot Detection Testing**
   - [ ] Test strong shot detection
   - [ ] Test weak shot detection
   - [ ] Test edge case detection
   - [ ] Test false positive prevention
   - [ ] Test shot parameter calculation

### Error Handling Testing

1. **Connection Error Testing**
   - [ ] Test Bluetooth disabled scenarios
   - [ ] Test device out of range
   - [ ] Test device power off during connection
   - [ ] Test connection interruption
   - [ ] Test error message display

2. **Data Error Testing**
   - [ ] Test corrupted data handling
   - [ ] Test partial data packets
   - [ ] Test data overflow scenarios
   - [ ] Test error recovery mechanisms

## 6. Automated Test Execution

### Test Scripts

```bash
#!/bin/bash
# scripts/run_tests.sh

echo "🧪 Running comprehensive test suite..."

# Unit tests
echo "📝 Running unit tests..."
flutter test test/unit/

# Integration tests
echo "🔗 Running integration tests..."
flutter test integration_test/

# Performance tests
echo "⚡ Running performance tests..."
flutter test test/performance/

# Hardware tests
echo "🔧 Running hardware tests..."
flutter test test/hardware/

echo "✅ All tests completed!"
```

### CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Test Suite

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.10.0'
        
    - name: Install dependencies
      run: flutter pub get
      
    - name: Run unit tests
      run: flutter test test/unit/
      
    - name: Run integration tests
      run: flutter test integration_test/
      
    - name: Analyze code
      run: flutter analyze
      
    - name: Check formatting
      run: dart format --set-exit-if-changed .
```

## 7. Test Data and Mocking

### Mock Data Generation

```dart
// test/utils/mock_data_generator.dart
class MockDataGenerator {
  static String generateValidSensorData() {
    final random = Random();
    final accX = (random.nextDouble() - 0.5) * 40; // -20 to 20
    final accY = (random.nextDouble() - 0.5) * 40;
    final accZ = (random.nextDouble() - 0.5) * 40;
    final gyroX = (random.nextDouble() - 0.5) * 800; // -400 to 400
    final gyroY = (random.nextDouble() - 0.5) * 800;
    final gyroZ = (random.nextDouble() - 0.5) * 800;
    
    return '$accX,$accY,$accZ,$gyroX,$gyroY,$gyroZ';
  }
  
  static String generateShotData() {
    final random = Random();
    final accX = 15.0 + random.nextDouble() * 20; // 15-35 (above threshold)
    final accY = (random.nextDouble() - 0.5) * 20;
    final accZ = (random.nextDouble() - 0.5) * 20;
    final gyroX = (random.nextDouble() - 0.5) * 400;
    final gyroY = (random.nextDouble() - 0.5) * 400;
    final gyroZ = (random.nextDouble() - 0.5) * 400;
    
    return '$accX,$accY,$accZ,$gyroX,$gyroY,$gyroZ';
  }
  
  static String generateInvalidData() {
    final invalidTypes = [
      'invalid,data,format',
      '1.0,2.0,3.0', // Too few
      '1.0,2.0,3.0,4.0,5.0,6.0,7.0', // Too many
      'NaN,Infinity,-Infinity,1.0,2.0,3.0',
      '',
    ];
    
    return invalidTypes[Random().nextInt(invalidTypes.length)];
  }
}
```

This comprehensive testing guide ensures your Smart Cricket Bat app is thoroughly tested across all scenarios, from unit tests to hardware integration tests.
