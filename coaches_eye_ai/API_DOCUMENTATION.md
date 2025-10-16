# 📚 API Documentation - Smart Cricket Bat App

## Overview

This document provides comprehensive API documentation for all services, models, and providers in the Smart Cricket Bat application.

---

## 🔗 BLE Service API

### `BLEService`

The Bluetooth Low Energy service handles communication with the Smart Bat hardware.

#### Constants

```dart
// UUID constants from ESP32 code
static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
static const String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
static const String DEVICE_NAME = "Smart Bat";

// Connection management constants
static const int _maxReconnectAttempts = 3;
static const Duration _baseReconnectDelay = Duration(seconds: 2);
static const Duration _connectionTimeout = Duration(seconds: 30);
static const Duration _scanTimeout = Duration(seconds: 10);

// Data transmission constants
static const int _maxDataRate = 20; // 20Hz max
static const int _bufferSize = 1024; // 1KB buffer
```

#### Properties

```dart
// Connection state
bool get isConnected => _currentConnectionState == ConnectionState.connected;
ConnectionState get currentConnectionState => _currentConnectionState;
BluetoothDevice? get connectedDevice => _connectedDevice;

// Data streams
Stream<bool> get connectionStream => _connectionController.stream;
Stream<ShotModel> get shotStream => _shotController.stream;
Stream<List<BluetoothDevice>> get scanResultsStream => _scanController.stream;
Stream<BLEException> get errorStream => _errorController.stream;
```

#### Methods

##### Device Management

```dart
/// Check if Bluetooth is available and enabled
Future<bool> isBluetoothAvailable() async

/// Request necessary permissions for BLE operations
Future<bool> requestPermissions() async

/// Scan for Smart Bat devices
Future<List<BluetoothDevice>> scanForDevices() async

/// Connect to a specific device
Future<void> connectToDevice(BluetoothDevice device) async

/// Disconnect from current device
Future<void> disconnect() async

/// Dispose of resources
void dispose()
```

##### Data Processing

```dart
/// Handle incoming sensor data from ESP32
void _handleIncomingData(List<int> data)

/// Parse sensor data string from ESP32
SensorData? _parseSensorData(String dataString)

/// Detect if sensor data represents a cricket shot
bool _isShotDetected(SensorData data)

/// Calculate shot metrics from sensor data
ShotModel _calculateShotMetrics(SensorData data)
```

#### Error Handling

```dart
/// Handle BLE errors with appropriate recovery
void _handleBLEError(BLEException error)

/// Implement exponential backoff for reconnection
Future<void> _attemptReconnection() async

/// Validate sensor data ranges
bool _isValidSensorData(SensorData data)
```

#### Usage Example

```dart
final bleService = BLEService();

// Listen to connection state
bleService.connectionStream.listen((isConnected) {
  print('BLE Connected: $isConnected');
});

// Listen to shot data
bleService.shotStream.listen((shot) {
  print('Shot detected: ${shot.batSpeed} m/s');
});

// Scan and connect
final devices = await bleService.scanForDevices();
if (devices.isNotEmpty) {
  await bleService.connectToDevice(devices.first);
}
```

---

## 🔐 Authentication Service API

### `AuthService`

Handles Firebase Authentication operations for user management.

#### Properties

```dart
/// Get the current authenticated user
User? get currentUser => _auth.currentUser;

/// Stream of authentication state changes
Stream<User?> get authStateChanges => _auth.authStateChanges();
```

#### Methods

##### User Authentication

```dart
/// Sign in with email and password
Future<UserModel?> signInWithEmail(String email, String password) async

/// Sign up with email and password
Future<UserModel?> signUpWithEmail(
  String email,
  String password,
  String displayName,
  String role,
) async

/// Sign out current user
Future<void> signOut() async

/// Send password reset email
Future<void> sendPasswordResetEmail(String email) async

/// Update user password
Future<void> updatePassword(String newPassword) async
```

##### Profile Management

```dart
/// Update user profile
Future<void> updateUserProfile(UserModel user) async

/// Delete user account
Future<void> deleteUserAccount() async

/// Get user profile from Firestore
Future<UserModel?> getUserProfile(String uid) async
```

#### Error Handling

```dart
/// Handle Firebase Auth exceptions
Exception _handleAuthException(FirebaseAuthException e)
```

#### Usage Example

```dart
final authService = AuthService();

// Sign in
try {
  final user = await authService.signInWithEmail('user@example.com', 'password');
  print('Signed in: ${user?.displayName}');
} catch (e) {
  print('Sign in failed: $e');
}

// Listen to auth state changes
authService.authStateChanges.listen((user) {
  if (user != null) {
    print('User signed in: ${user.email}');
  } else {
    print('User signed out');
  }
});
```

---

## 🗄️ Firestore Service API

### `FirestoreService`

Handles all Firestore database operations for data persistence.

#### Methods

##### User Management

```dart
/// Create a new user profile in Firestore
Future<void> createUserProfile(UserModel user) async

/// Get user profile by UID
Future<UserModel?> getUserProfile(String uid) async

/// Update user profile
Future<void> updateUserProfile(UserModel user) async

/// Delete user profile
Future<void> deleteUserProfile(String uid) async
```

##### Session Management

```dart
/// Start a new practice session
Future<String> startNewSession(String playerId) async

/// Update session data
Future<void> updateSession(SessionModel session) async

/// Get session by ID
Future<SessionModel?> getSession(String sessionId) async

/// Get user's sessions
Future<List<SessionModel>> getUserSessions(String playerId) async

/// Delete session
Future<void> deleteSession(String sessionId) async
```

##### Shot Data Management

```dart
/// Save shot data to Firestore
Future<void> saveShot(ShotModel shot) async

/// Get shots for a session
Future<List<ShotModel>> getSessionShots(String sessionId) async

/// Get user's shot history
Future<List<ShotModel>> getUserShots(String playerId) async

/// Delete shot data
Future<void> deleteShot(String shotId) async
```

##### Analytics and Statistics

```dart
/// Get user statistics
Future<Map<String, dynamic>> getUserStatistics(String playerId) async

/// Get session analytics
Future<Map<String, dynamic>> getSessionAnalytics(String sessionId) async

/// Get progress over time
Future<List<Map<String, dynamic>>> getProgressData(String playerId) async
```

#### Usage Example

```dart
final firestoreService = FirestoreService();

// Create user profile
final user = UserModel(
  uid: 'user123',
  email: 'user@example.com',
  displayName: 'John Doe',
  role: 'player',
);
await firestoreService.createUserProfile(user);

// Start session
final sessionId = await firestoreService.startNewSession('user123');

// Save shot data
final shot = ShotModel(
  shotId: 'shot123',
  sessionId: sessionId,
  playerId: 'user123',
  timestamp: DateTime.now(),
  batSpeed: 25.5,
  power: 8.2,
  timing: 0.95,
  sweetSpot: true,
);
await firestoreService.saveShot(shot);
```

---

## 📷 Camera Service API

### `CameraService`

Handles video recording and camera operations for session recording.

#### Methods

##### Camera Management

```dart
/// Initialize camera
Future<void> initializeCamera() async

/// Start video recording
Future<void> startRecording() async

/// Stop video recording
Future<String?> stopRecording() async

/// Take a photo
Future<String?> takePhoto() async

/// Dispose camera resources
void dispose()
```

##### File Management

```dart
/// Save video to Firebase Storage
Future<String> uploadVideo(String filePath) async

/// Save photo to Firebase Storage
Future<String> uploadPhoto(String filePath) async

/// Delete local file
Future<void> deleteLocalFile(String filePath) async
```

#### Usage Example

```dart
final cameraService = CameraService();

// Initialize camera
await cameraService.initializeCamera();

// Start recording
await cameraService.startRecording();

// Stop recording and get file path
final videoPath = await cameraService.stopRecording();

// Upload to Firebase
if (videoPath != null) {
  final downloadUrl = await cameraService.uploadVideo(videoPath);
  print('Video uploaded: $downloadUrl');
}
```

---

## 🎯 Hardware Simulator API

### `HardwareSimulator`

Provides simulated sensor data for testing and development.

#### Properties

```dart
/// Whether simulator is running
bool get isRunning => _isRunning;

/// Current shot count
int get shotCount => _shotCount;

/// Simulated session duration
Duration get sessionDuration => _sessionDuration;
```

#### Methods

##### Simulation Control

```dart
/// Start simulation
void startSimulation()

/// Stop simulation
void stopSimulation()

/// Generate random shot data
ShotModel generateRandomShot()

/// Generate realistic sensor data
SensorData generateSensorData()

/// Reset simulation state
void reset()
```

##### Configuration

```dart
/// Set shot frequency (shots per minute)
void setShotFrequency(int frequency)

/// Set shot intensity range
void setShotIntensityRange(double min, double max)

/// Enable/disable random variations
void setRandomVariations(bool enabled)
```

#### Usage Example

```dart
final simulator = HardwareSimulator();

// Configure simulation
simulator.setShotFrequency(30); // 30 shots per minute
simulator.setShotIntensityRange(15.0, 35.0); // 15-35 m/s bat speed

// Start simulation
simulator.startSimulation();

// Listen to generated shots
Timer.periodic(Duration(seconds: 1), (timer) {
  if (simulator.isRunning) {
    final shot = simulator.generateRandomShot();
    print('Simulated shot: ${shot.batSpeed} m/s');
  }
});
```

---

## 📊 Data Models API

### `ShotModel`

Represents a cricket shot with all relevant metrics.

#### Properties

```dart
final String shotId;
final String sessionId;
final String playerId;
final DateTime timestamp;
final double batSpeed;        // m/s
final double power;           // 0-10 scale
final double timing;          // 0-1 scale
final bool sweetSpot;         // true if hit sweet spot
final Map<String, double> sensorData; // Raw sensor values
```

#### Methods

```dart
/// Convert to JSON for Firestore
Map<String, dynamic> toJson()

/// Create from JSON
factory ShotModel.fromJson(Map<String, dynamic> json)

/// Calculate shot quality score
double calculateQualityScore()

/// Get shot type classification
String getShotType()
```

### `SessionModel`

Represents a practice session with aggregated data.

#### Properties

```dart
final String sessionId;
final String playerId;
final DateTime date;
final int durationInMinutes;
final int totalShots;
final double averageBatSpeed;
final double averagePower;
final double averageTiming;
final int sweetSpotHits;
final List<String> shotIds;
```

#### Methods

```dart
/// Convert to JSON
Map<String, dynamic> toJson()

/// Create from JSON
factory SessionModel.fromJson(Map<String, dynamic> json)

/// Calculate session score
double calculateSessionScore()

/// Get improvement metrics
Map<String, double> getImprovementMetrics()
```

### `UserModel`

Represents a user profile with authentication and profile data.

#### Properties

```dart
final String uid;
final String email;
final String displayName;
final String role;            // 'player' or 'coach'
final DateTime createdAt;
final DateTime lastLogin;
final Map<String, dynamic> preferences;
final List<String> sessionIds;
```

#### Methods

```dart
/// Convert to JSON
Map<String, dynamic> toJson()

/// Create from JSON
factory UserModel.fromJson(Map<String, dynamic> json)

/// Update last login
void updateLastLogin()

/// Add session reference
void addSession(String sessionId)
```

---

## 🔄 State Management API

### Riverpod Providers

#### BLE Service Providers

```dart
/// BLE service provider
final bleServiceProvider = Provider<BLEService>((ref) => BLEService());

/// BLE connection state provider
final bleConnectionProvider = StreamProvider<bool>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return bleService.connectionStream;
});

/// BLE shot data provider
final bleShotStreamProvider = StreamProvider<ShotModel>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return bleService.shotStream;
});

/// BLE scan results provider
final bleScanProvider = StreamProvider<List<BluetoothDevice>>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return bleService.scanResultsStream;
});
```

#### Authentication Providers

```dart
/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Current user provider
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.asyncMap((user) {
    if (user != null) {
      return authService.getUserProfile(user.uid);
    }
    return null;
  });
});
```

#### Firestore Providers

```dart
/// Firestore service provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

/// User sessions provider
final userSessionsProvider = FutureProvider.family<List<SessionModel>, String>((ref, playerId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getUserSessions(playerId);
});

/// Session shots provider
final sessionShotsProvider = FutureProvider.family<List<ShotModel>, String>((ref, sessionId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getSessionShots(sessionId);
});
```

#### Usage Example

```dart
class DashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleConnection = ref.watch(bleConnectionProvider);
    final currentUser = ref.watch(currentUserProvider);
    final bleService = ref.watch(bleServiceProvider);

    return Scaffold(
      body: Column(
        children: [
          // Connection status
          bleConnection.when(
            data: (isConnected) => Text('BLE: ${isConnected ? "Connected" : "Disconnected"}'),
            loading: () => CircularProgressIndicator(),
            error: (error, stack) => Text('Error: $error'),
          ),
          
          // User info
          currentUser.when(
            data: (user) => Text('Welcome ${user?.displayName}'),
            loading: () => CircularProgressIndicator(),
            error: (error, stack) => Text('Error: $error'),
          ),
          
          // Connect button
          ElevatedButton(
            onPressed: () async {
              final devices = await bleService.scanForDevices();
              if (devices.isNotEmpty) {
                await bleService.connectToDevice(devices.first);
              }
            },
            child: Text('Connect to Bat'),
          ),
        ],
      ),
    );
  }
}
```

---

## 🚨 Error Handling API

### `ErrorHandler`

Centralized error handling for the application.

#### Methods

```dart
/// Handle BLE errors
void handleBLEError(BLEException error)

/// Handle Firebase errors
void handleFirebaseError(Exception error)

/// Handle camera errors
void handleCameraError(Exception error)

/// Get user-friendly error message
String getUserFriendlyMessage(dynamic error)

/// Get retry suggestion
String getRetrySuggestion(dynamic error)

/// Log error for debugging
void logError(dynamic error, StackTrace stackTrace)
```

#### Error Types

```dart
enum BLEErrorType {
  connection,    // Connection failed
  permission,    // Permission denied
  data,         // Data parsing error
  timeout,      // Operation timeout
  unknown,      // Unknown error
}
```

#### Usage Example

```dart
final errorHandler = ErrorHandler();

try {
  await bleService.connectToDevice(device);
} on BLEException catch (e) {
  errorHandler.handleBLEError(e);
  final message = errorHandler.getUserFriendlyMessage(e);
  final suggestion = errorHandler.getRetrySuggestion(e);
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Connection Error'),
      content: Text('$message\n\n$suggestion'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}
```

---

## 📈 Performance Monitoring API

### `PerformanceMonitor`

Monitors app performance and provides metrics.

#### Methods

```dart
/// Start monitoring an operation
void startOperation(String operationName)

/// End monitoring an operation
void endOperation(String operationName)

/// Get average duration for an operation
Duration? getAverageDuration(String operationName)

/// Get performance metrics
Map<String, dynamic> getMetrics()

/// Reset all metrics
void reset()
```

#### Usage Example

```dart
final monitor = PerformanceMonitor();

// Monitor BLE connection
monitor.startOperation('ble_connection');
try {
  await bleService.connectToDevice(device);
} finally {
  monitor.endOperation('ble_connection');
}

// Get metrics
final metrics = monitor.getMetrics();
print('BLE connection average: ${metrics['ble_connection']}');
```

---

## 🔧 Configuration API

### App Configuration

```dart
class AppConfig {
  // BLE Configuration
  static const String bleServiceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String bleCharacteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String bleDeviceName = "Smart Bat";
  
  // Shot Detection Thresholds
  static const double accelerationThreshold = 15.0; // m/s²
  static const double gyroscopeThreshold = 200.0;    // degrees/s
  
  // Data Processing
  static const int maxDataRate = 20; // Hz
  static const int bufferSize = 1024; // bytes
  
  // Connection Management
  static const int maxReconnectAttempts = 3;
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration scanTimeout = Duration(seconds: 10);
  
  // Firebase Configuration
  static const String firebaseProjectId = "coaches-eye-ai";
  static const String firebaseStorageBucket = "coaches-eye-ai.firebasestorage.app";
}
```

---

## 📝 Usage Guidelines

### Best Practices

1. **Error Handling**: Always wrap service calls in try-catch blocks
2. **Resource Management**: Dispose services when no longer needed
3. **State Management**: Use Riverpod providers for reactive state
4. **Performance**: Monitor operations and optimize as needed
5. **Testing**: Use the hardware simulator for development

### Common Patterns

```dart
// Service initialization
final bleService = BLEService();
final authService = AuthService();
final firestoreService = FirestoreService();

// Stream subscriptions
StreamSubscription? connectionSubscription;
StreamSubscription? shotSubscription;

void initializeServices() {
  connectionSubscription = bleService.connectionStream.listen((isConnected) {
    // Handle connection state changes
  });
  
  shotSubscription = bleService.shotStream.listen((shot) {
    // Handle shot data
    firestoreService.saveShot(shot);
  });
}

void dispose() {
  connectionSubscription?.cancel();
  shotSubscription?.cancel();
  bleService.dispose();
}
```

---

This API documentation provides comprehensive coverage of all services, models, and utilities in the Smart Cricket Bat application. For implementation details, refer to the actual source code files.
