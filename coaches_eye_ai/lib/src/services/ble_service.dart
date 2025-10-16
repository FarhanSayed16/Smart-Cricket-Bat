import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/shot_model.dart';

/// Connection state enumeration
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// BLE Error types
enum BLEErrorType { connection, permission, data, timeout, unknown }

/// Custom BLE Exception
class BLEException implements Exception {
  final String message;
  final BLEErrorType type;

  BLEException(this.message, this.type);

  @override
  String toString() => 'BLEException($type): $message';
}

/// Bluetooth Low Energy service for connecting to Smart Bat hardware
/// Handles scanning, connecting, and receiving sensor data from ESP32 + BNO055
class BLEService {
  // UUID constants from ESP32 code
  static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String CHARACTERISTIC_UUID =
      "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String DEVICE_NAME = "Smart Bat";

  // Connection management constants
  static const int _maxReconnectAttempts = 3;
  static const Duration _baseReconnectDelay = Duration(seconds: 2);
  static const Duration _connectionTimeout = Duration(seconds: 30);
  static const Duration _scanTimeout = Duration(seconds: 10);

  // Data transmission constants
  static const int _maxDataRate = 20; // 20Hz max
  static const int _bufferSize = 1024;
  static const Duration _dataRateWindow = Duration(milliseconds: 50);

  // Stream controllers for exposing data
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<ShotModel> _shotController =
      StreamController<ShotModel>.broadcast();
  final StreamController<List<BluetoothDevice>> _scanController =
      StreamController<List<BluetoothDevice>>.broadcast();
  final StreamController<ConnectionState> _connectionStateController =
      StreamController<ConnectionState>.broadcast();

  // BLE state management
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _dataCharacteristic;
  StreamSubscription<List<int>>? _dataSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  // Connection management
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _scanTimer;

  // Data management
  final List<int> _dataBuffer = [];
  DateTime? _lastDataTime;
  int _dataCount = 0;
  bool _isBackgrounded = false;

  // Session management
  String? _currentSessionId;
  int _shotCounter = 0;

  // Public streams
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<ShotModel> get shotStream => _shotController.stream;
  Stream<List<BluetoothDevice>> get scanStream => _scanController.stream;
  Stream<ConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  // Connection state
  bool get isConnected => _connectedDevice != null;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  ConnectionState get currentConnectionState {
    if (_isConnecting) return ConnectionState.connecting;
    if (isConnected) return ConnectionState.connected;
    if (_reconnectAttempts > 0) return ConnectionState.reconnecting;
    return ConnectionState.disconnected;
  }

  /// Initialize BLE service and check permissions
  Future<bool> initialize() async {
    try {
      // Check Bluetooth permissions
      final bluetoothPermission = await Permission.bluetoothScan.request();
      final bluetoothConnectPermission = await Permission.bluetoothConnect
          .request();

      if (!bluetoothPermission.isGranted ||
          !bluetoothConnectPermission.isGranted) {
        print('Bluetooth permissions not granted');
        return false;
      }

      // Check if Bluetooth is available
      final adapterState = FlutterBluePlus.adapterState;
      if (adapterState != BluetoothAdapterState.on) {
        print('Bluetooth adapter is not on: $adapterState');
        return false;
      }

      // Listen to adapter state changes
      _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
        if (state != BluetoothAdapterState.on && isConnected) {
          _handleDisconnection();
        }
      });

      return true;
    } catch (e) {
      print('Error initializing BLE service: $e');
      return false;
    }
  }

  /// Scan for Smart Bat devices
  Future<void> scanForDevice({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      if (!await initialize()) {
        throw Exception('BLE initialization failed');
      }

      print('Starting scan for Smart Bat devices...');

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: timeout,
        withServices: [Guid(SERVICE_UUID)],
      );

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        final devices = results
            .where((result) => result.device.platformName.isNotEmpty)
            .map((result) => result.device)
            .where((device) => device.platformName.contains(DEVICE_NAME))
            .toList();

        _scanController.add(devices);
      });

      // Stop scanning after timeout
      Timer(timeout, () {
        FlutterBluePlus.stopScan();
        print('Scan completed');
      });
    } catch (e) {
      print('Error scanning for devices: $e');
      rethrow;
    }
  }

  /// Connect to a specific device with enhanced error handling and reconnection
  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_isConnecting) {
      throw BLEException(
        'Connection already in progress',
        BLEErrorType.connection,
      );
    }

    _isConnecting = true;
    _connectionStateController.add(ConnectionState.connecting);

    try {
      print('Connecting to device: ${device.platformName}');

      // Stop scanning
      await FlutterBluePlus.stopScan();

      // Connect to device with timeout
      await device.connect(timeout: _connectionTimeout);
      _connectedDevice = device;

      // Discover services
      final services = await device.discoverServices();
      print('Discovered ${services.length} services');

      // Find our service and characteristic
      final targetService = _findTargetService(services);
      if (targetService == null) {
        throw BLEException('Target service not found', BLEErrorType.connection);
      }

      _dataCharacteristic = _findDataCharacteristic(targetService);
      if (_dataCharacteristic == null) {
        throw BLEException(
          'Data characteristic not found',
          BLEErrorType.connection,
        );
      }

      // Subscribe to notifications
      await _dataCharacteristic!.setNotifyValue(true);

      // Listen to incoming data with enhanced error handling
      _dataSubscription = _dataCharacteristic!.lastValueStream.listen(
        _handleIncomingData,
        onError: (error) {
          print('Error receiving data: $error');
          _handleDisconnection();
        },
      );

      // Listen to connection state changes
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      // Reset reconnection attempts on successful connection
      _reconnectAttempts = 0;
      _connectionController.add(true);
      _connectionStateController.add(ConnectionState.connected);
      print('Successfully connected to Smart Bat');
    } catch (e) {
      print('Error connecting to device: $e');
      await _handleConnectionFailure(device);
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  /// Find the target service by UUID
  BluetoothService? _findTargetService(List<BluetoothService> services) {
    for (final service in services) {
      if (service.uuid.toString().toUpperCase() == SERVICE_UUID.toUpperCase()) {
        return service;
      }
    }
    return null;
  }

  /// Find the data characteristic by UUID
  BluetoothCharacteristic? _findDataCharacteristic(BluetoothService service) {
    for (final characteristic in service.characteristics) {
      if (characteristic.uuid.toString().toUpperCase() ==
          CHARACTERISTIC_UUID.toUpperCase()) {
        return characteristic;
      }
    }
    return null;
  }

  /// Handle connection failure with exponential backoff
  Future<void> _handleConnectionFailure(BluetoothDevice device) async {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      _connectionStateController.add(ConnectionState.reconnecting);

      final delay = Duration(
        milliseconds:
            _baseReconnectDelay.inMilliseconds *
            pow(2, _reconnectAttempts - 1).toInt(),
      );

      print(
        'Reconnection attempt $_reconnectAttempts in ${delay.inSeconds} seconds',
      );

      _reconnectTimer = Timer(delay, () async {
        try {
          await connectToDevice(device);
        } catch (e) {
          print('Reconnection attempt $_reconnectAttempts failed: $e');
        }
      });
    } else {
      _connectionStateController.add(ConnectionState.error);
      _handleDisconnection();
    }
  }

  /// Handle incoming sensor data with enhanced validation and buffering
  void _handleIncomingData(List<int> data) {
    try {
      // Rate limiting
      final now = DateTime.now();
      if (_lastDataTime != null) {
        final timeDiff = now.difference(_lastDataTime!).inMilliseconds;
        if (timeDiff < _dataRateWindow.inMilliseconds) {
          return; // Skip this packet to maintain rate limit
        }
      }
      _lastDataTime = now;
      _dataCount++;

      // Add to buffer
      _dataBuffer.addAll(data);

      // Prevent buffer overflow
      if (_dataBuffer.length > _bufferSize) {
        _dataBuffer.removeRange(0, _dataBuffer.length - _bufferSize);
      }

      // Process complete messages
      _processDataBuffer();
    } catch (e) {
      print('Error handling incoming data: $e');
      _dataBuffer.clear(); // Clear buffer on error
    }
  }

  /// Process data buffer for complete messages
  void _processDataBuffer() {
    try {
      // Convert buffer to string
      final dataString = utf8.decode(_dataBuffer);

      // Look for complete messages (assuming newline delimiter)
      final lines = dataString.split('\n');

      // Process complete lines
      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (line.isNotEmpty) {
          _parseSensorData(line);
        }
      }

      // Keep incomplete line in buffer
      if (lines.isNotEmpty) {
        _dataBuffer.clear();
        _dataBuffer.addAll(utf8.encode(lines.last));
      }
    } catch (e) {
      print('Error processing data buffer: $e');
      _dataBuffer.clear();
    }
  }

  /// Parse and validate sensor data
  void _parseSensorData(String data) {
    try {
      // Validate data format
      if (!_validateSensorData(data)) {
        print('Invalid sensor data format: $data');
        return;
      }

      // Parse sensor data (format: "accX,accY,accZ,gyroX,gyroY,gyroZ")
      final values = data
          .split(',')
          .map((e) => double.tryParse(e.trim()) ?? 0.0)
          .toList();

      if (values.length >= 6) {
        final accX = values[0];
        final accY = values[1];
        final accZ = values[2];
        final gyroX = values[3];
        final gyroY = values[4];
        final gyroZ = values[5];

        // Validate sensor values
        if (!_validateSensorValues(accX, accY, accZ, gyroX, gyroY, gyroZ)) {
          print('Invalid sensor values: $values');
          return;
        }

        // Detect shot based on acceleration and gyroscope thresholds
        final accelerationMagnitude = sqrt(
          pow(accX, 2) + pow(accY, 2) + pow(accZ, 2),
        );
        final gyroMagnitude = sqrt(
          pow(gyroX, 2) + pow(gyroY, 2) + pow(gyroZ, 2),
        );

        // Shot detection thresholds (same as simulator)
        const double accelerationThreshold = 15.0; // m/s²
        const double gyroThreshold = 200.0; // degrees/s

        if (accelerationMagnitude > accelerationThreshold ||
            gyroMagnitude > gyroThreshold) {
          _processShot(
            accelerationMagnitude,
            gyroMagnitude,
            accX,
            accY,
            accZ,
            gyroX,
            gyroY,
            gyroZ,
          );
        }
      }
    } catch (e) {
      print('Error parsing sensor data: $e');
    }
  }

  /// Validate sensor data format
  bool _validateSensorData(String data) {
    // Basic validation: should be 6 comma-separated numbers
    final parts = data.split(',');
    if (parts.length != 6) return false;

    for (final part in parts) {
      if (double.tryParse(part.trim()) == null) return false;
    }

    return true;
  }

  /// Validate sensor values are within reasonable ranges
  bool _validateSensorValues(
    double accX,
    double accY,
    double accZ,
    double gyroX,
    double gyroY,
    double gyroZ,
  ) {
    // Acceleration validation (m/s²)
    const double maxAcceleration = 50.0;
    if (accX.abs() > maxAcceleration ||
        accY.abs() > maxAcceleration ||
        accZ.abs() > maxAcceleration) {
      return false;
    }

    // Gyroscope validation (degrees/s)
    const double maxGyroscope = 1000.0;
    if (gyroX.abs() > maxGyroscope ||
        gyroY.abs() > maxGyroscope ||
        gyroZ.abs() > maxGyroscope) {
      return false;
    }

    return true;
  }

  /// Process detected shot and create ShotModel
  void _processShot(
    double accelerationMagnitude,
    double gyroMagnitude,
    double accX,
    double accY,
    double accZ,
    double gyroX,
    double gyroY,
    double gyroZ,
  ) {
    if (_currentSessionId == null) return;

    _shotCounter++;
    final shotId = '${_currentSessionId}_shot_$_shotCounter';

    // Calculate shot parameters using same logic as simulator
    final batSpeed = _calculateBatSpeed(accelerationMagnitude, gyroMagnitude);
    final powerIndex = _calculatePowerIndex(accelerationMagnitude);
    final timingScore = _calculateTimingScore(accX, accY, accZ);
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

    print(
      'Shot detected: ${shot.batSpeed.toStringAsFixed(1)} km/h, Power: ${shot.powerIndex}',
    );
    _shotController.add(shot);
  }

  /// Calculate bat speed based on sensor data (km/h)
  double _calculateBatSpeed(double acceleration, double gyro) {
    // Realistic bat speed calculation based on acceleration and angular velocity
    final baseSpeed = 80.0 + (acceleration * 2.0) + (gyro * 0.1);
    return baseSpeed.clamp(60.0, 150.0);
  }

  /// Calculate power index (0-100) based on acceleration
  int _calculatePowerIndex(double acceleration) {
    final power = (acceleration * 3.0).clamp(0.0, 100.0);
    return power.round();
  }

  /// Calculate timing score (-50 to +50 ms) based on acceleration consistency
  double _calculateTimingScore(double accX, double accY, double accZ) {
    // Timing depends on acceleration pattern consistency
    final timingVariation = (accX + accY + accZ) * 0.1;
    return timingVariation.clamp(-50.0, 50.0);
  }

  /// Calculate sweet spot accuracy (0.0-1.0)
  double _calculateSweetSpotAccuracy(double acceleration) {
    final baseAccuracy = 0.7 + (acceleration / 50.0);
    return baseAccuracy.clamp(0.0, 1.0);
  }

  /// Start session for shot tracking
  void startSession(String sessionId) {
    _currentSessionId = sessionId;
    _shotCounter = 0;
    print('Started session: $sessionId');
  }

  /// Stop current session
  void stopSession() {
    _currentSessionId = null;
    _shotCounter = 0;
    print('Stopped session');
  }

  /// Disconnect from the Smart Bat with proper cleanup
  Future<void> disconnect() async {
    try {
      print('Disconnecting from Smart Bat...');

      // Cancel reconnection timer
      _reconnectTimer?.cancel();
      _reconnectTimer = null;

      // Cancel scan timer
      _scanTimer?.cancel();
      _scanTimer = null;

      // Cancel data subscription
      await _dataSubscription?.cancel();
      _dataSubscription = null;

      // Disconnect from device
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
      }

      // Clear characteristic reference
      _dataCharacteristic = null;

      // Clear data buffer
      _dataBuffer.clear();

      // Stop current session
      stopSession();

      // Reset connection state
      _isConnecting = false;
      _reconnectAttempts = 0;

      _connectionController.add(false);
      _connectionStateController.add(ConnectionState.disconnected);
      print('Disconnected from Smart Bat');
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  /// Handle disconnection (called when device disconnects unexpectedly)
  void _handleDisconnection() {
    print('Device disconnected unexpectedly');

    // Cancel timers
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _scanTimer?.cancel();
    _scanTimer = null;

    // Clean up state
    _connectedDevice = null;
    _dataCharacteristic = null;
    _dataSubscription?.cancel();
    _dataSubscription = null;
    _dataBuffer.clear();
    _isConnecting = false;

    stopSession();

    _connectionController.add(false);
    _connectionStateController.add(ConnectionState.disconnected);
  }

  /// Handle app lifecycle changes for power management
  void handleAppLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _isBackgrounded = true;
        _pauseBLEOperations();
        break;
      case AppLifecycleState.resumed:
        _isBackgrounded = false;
        _resumeBLEOperations();
        break;
      case AppLifecycleState.detached:
        dispose();
        break;
    }
  }

  /// Pause BLE operations when app is backgrounded
  void _pauseBLEOperations() {
    print('Pausing BLE operations due to backgrounding');
    // Reduce scanning frequency
    _scanTimer?.cancel();
    // Keep connection alive but reduce data processing
  }

  /// Resume BLE operations when app is foregrounded
  void _resumeBLEOperations() {
    print('Resuming BLE operations due to foregrounding');
    // Resume normal operations
    if (!isConnected) {
      // Optionally restart scanning
    }
  }

  /// Get current connection status with enhanced information
  Map<String, dynamic> getConnectionStatus() {
    return {
      'isConnected': isConnected,
      'connectionState': currentConnectionState.toString(),
      'deviceName': _connectedDevice?.platformName ?? 'None',
      'sessionId': _currentSessionId,
      'shotCount': _shotCounter,
      'reconnectAttempts': _reconnectAttempts,
      'isConnecting': _isConnecting,
      'isBackgrounded': _isBackgrounded,
      'dataCount': _dataCount,
      'bufferSize': _dataBuffer.length,
    };
  }

  /// Get current sensor readings and statistics
  Map<String, dynamic> getCurrentSensorReadings() {
    return {
      'dataCount': _dataCount,
      'lastDataTime': _lastDataTime?.toIso8601String(),
      'bufferSize': _dataBuffer.length,
      'isBackgrounded': _isBackgrounded,
      'connectionState': currentConnectionState.toString(),
    };
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'dataRate': _dataCount > 0 ? _dataCount / 60 : 0, // packets per minute
      'bufferUtilization': _dataBuffer.length / _bufferSize,
      'reconnectAttempts': _reconnectAttempts,
      'connectionUptime': isConnected ? 'Connected' : 'Disconnected',
    };
  }

  /// Dispose resources with comprehensive cleanup
  void dispose() {
    print('Disposing BLE service...');

    // Cancel all timers
    _reconnectTimer?.cancel();
    _scanTimer?.cancel();

    // Cancel all subscriptions
    _adapterStateSubscription?.cancel();
    _dataSubscription?.cancel();

    // Disconnect if connected
    if (isConnected) {
      disconnect();
    }

    // Clear buffers
    _dataBuffer.clear();

    // Close all stream controllers
    _connectionController.close();
    _shotController.close();
    _scanController.close();
    _connectionStateController.close();

    print('BLE service disposed');
  }
}
