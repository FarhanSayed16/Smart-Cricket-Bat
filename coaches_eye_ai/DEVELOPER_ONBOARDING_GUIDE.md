# 👨‍💻 Developer Onboarding Guide - Smart Cricket Bat App

## Welcome, Developer! 🚀

This guide will help you get up and running with the Smart Cricket Bat app development environment, understand the codebase architecture, and start contributing effectively.

---

## 📋 Prerequisites

### Required Software

- **Flutter SDK**: Latest stable version (3.10.0+)
- **Dart SDK**: Included with Flutter
- **Android Studio**: Latest version with Flutter plugin
- **VS Code**: With Flutter and Dart extensions
- **Git**: For version control
- **Firebase CLI**: For Firebase operations
- **Node.js**: For Firebase Functions (optional)

### Required Accounts

- **Google Account**: For Firebase services
- **GitHub Account**: For code repository access
- **Apple Developer Account**: For iOS development (optional)
- **Google Play Console**: For Android publishing (optional)

### Hardware Requirements

- **Development Machine**: Windows, macOS, or Linux
- **Android Device**: For testing (optional)
- **iOS Device**: For testing (optional)
- **Smart Bat Hardware**: ESP32 with BNO055 sensor (optional)

---

## 🏗️ Development Environment Setup

### 1. Flutter Installation

#### Windows
```bash
# Download Flutter SDK
# Extract to C:\flutter
# Add C:\flutter\bin to PATH

# Verify installation
flutter doctor
```

#### macOS
```bash
# Install via Homebrew
brew install flutter

# Verify installation
flutter doctor
```

#### Linux
```bash
# Download Flutter SDK
# Extract to ~/flutter
# Add ~/flutter/bin to PATH

# Verify installation
flutter doctor
```

### 2. IDE Setup

#### Android Studio
1. **Install Android Studio**
2. **Install Flutter Plugin**
   - File → Settings → Plugins
   - Search for "Flutter" and install
3. **Install Dart Plugin** (installed with Flutter)
4. **Configure SDK**
   - File → Settings → Languages & Frameworks → Flutter
   - Set Flutter SDK path

#### VS Code
1. **Install VS Code**
2. **Install Extensions**:
   - Flutter
   - Dart
   - Flutter Widget Snippets
   - Bracket Pair Colorizer
   - GitLens

### 3. Firebase Setup

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

---

## 📁 Project Structure Overview

```
coaches_eye_ai/
├── android/                 # Android-specific files
│   ├── app/
│   │   ├── build.gradle.kts
│   │   ├── google-services.json
│   │   └── src/main/
│   └── build.gradle.kts
├── ios/                     # iOS-specific files
│   ├── Runner/
│   │   ├── Info.plist
│   │   └── AppDelegate.swift
│   └── Runner.xcworkspace
├── lib/                     # Flutter source code
│   ├── main.dart           # App entry point
│   ├── firebase_options.dart
│   └── src/
│       ├── features/        # App features
│       │   ├── auth/        # Authentication
│       │   ├── dashboard/   # Main dashboard
│       │   ├── session/     # Live sessions
│       │   ├── analytics/   # Data analysis
│       │   ├── coach_dashboard/ # Coach features
│       │   ├── connection/  # BLE connection
│       │   └── test/        # Testing screens
│       ├── models/          # Data models
│       │   ├── user_model.dart
│       │   ├── session_model.dart
│       │   ├── shot_model.dart
│       │   └── profile_models.dart
│       ├── services/        # Core services
│       │   ├── ble_service.dart
│       │   ├── auth_service.dart
│       │   ├── firestore_service.dart
│       │   ├── camera_service.dart
│       │   ├── hardware_simulator.dart
│       │   ├── error_handler.dart
│       │   └── ble_test_service.dart
│       ├── providers/       # State management
│       │   └── providers.dart
│       └── common_widgets/  # Reusable components
├── test/                    # Test files
│   ├── ble_service_test.dart
│   └── widget_test.dart
├── docs/                    # Documentation
│   ├── README.md
│   ├── API_DOCUMENTATION.md
│   ├── USER_GUIDE.md
│   ├── DEPLOYMENT_GUIDE.md
│   ├── TROUBLESHOOTING_GUIDE.md
│   ├── BLE_INTEGRATION_COMPLETE.md
│   ├── PRODUCTION_BUILD_CONFIG.md
│   ├── PRODUCTION_READY_SUMMARY.md
│   ├── PROJECT_SUMMARY.md
│   ├── TESTING_GUIDE.md
│   └── FIREBASE_MANUAL_SETUP.md
├── pubspec.yaml            # Dependencies
└── README.md               # Main documentation
```

---

## 🔧 Getting Started

### 1. Clone the Repository

```bash
# Clone the repository
git clone https://github.com/your-org/smart-cricket-bat.git
cd smart-cricket-bat/coaches_eye_ai

# Install dependencies
flutter pub get
```

### 2. Firebase Configuration

```bash
# Configure Firebase for your environment
flutterfire configure

# Select your Firebase project
# Choose platforms (Android, iOS, Web)
# This will update firebase_options.dart
```

### 3. Environment Setup

#### Create Environment Files

**`.env.development`**
```env
FIREBASE_PROJECT_ID=coaches-eye-ai-dev
API_BASE_URL=https://api-dev.coacheseyeai.com
DEBUG_MODE=true
LOG_LEVEL=DEBUG
```

**`.env.production`**
```env
FIREBASE_PROJECT_ID=coaches-eye-ai-prod
API_BASE_URL=https://api.coacheseyeai.com
DEBUG_MODE=false
LOG_LEVEL=ERROR
```

#### Update Configuration

```dart
// lib/config/app_config.dart
class AppConfig {
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'coaches-eye-ai-dev',
  );
  
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-dev.coacheseyeai.com',
  );
  
  static const bool debugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: true,
  );
  
  static const String logLevel = String.fromEnvironment(
    'LOG_LEVEL',
    defaultValue: 'DEBUG',
  );
}
```

### 4. Run the App

```bash
# Run on connected device
flutter run

# Run on specific device
flutter run -d <device-id>

# Run in debug mode
flutter run --debug

# Run in release mode
flutter run --release
```

---

## 🏗️ Architecture Overview

### State Management

The app uses **Riverpod** for state management:

```dart
// providers/providers.dart
final bleServiceProvider = Provider<BLEService>((ref) => BLEService());
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

// Stream providers for reactive state
final bleConnectionProvider = StreamProvider<bool>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return bleService.connectionStream;
});

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

### Service Layer

Services handle business logic and external integrations:

```dart
// services/ble_service.dart
class BLEService {
  // BLE communication with Smart Bat hardware
  Future<void> connectToDevice(BluetoothDevice device);
  Stream<ShotModel> get shotStream;
  Stream<bool> get connectionStream;
}

// services/auth_service.dart
class AuthService {
  // Firebase Authentication
  Future<UserModel?> signInWithEmail(String email, String password);
  Future<UserModel?> signUpWithEmail(String email, String password, String displayName, String role);
}

// services/firestore_service.dart
class FirestoreService {
  // Firestore database operations
  Future<void> saveShot(ShotModel shot);
  Future<List<SessionModel>> getUserSessions(String playerId);
}
```

### Model Layer

Models represent data structures:

```dart
// models/shot_model.dart
class ShotModel {
  final String shotId;
  final String sessionId;
  final String playerId;
  final DateTime timestamp;
  final double batSpeed;
  final double power;
  final double timing;
  final bool sweetSpot;
  
  Map<String, dynamic> toJson();
  factory ShotModel.fromJson(Map<String, dynamic> json);
}
```

### Feature Layer

Features are organized by functionality:

```dart
// features/dashboard/dashboard_screen.dart
class DashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleConnection = ref.watch(bleConnectionProvider);
    final currentUser = ref.watch(currentUserProvider);
    
    return Scaffold(
      // Dashboard UI
    );
  }
}
```

---

## 🔗 BLE Integration

### Understanding BLE Service

The BLE service handles communication with the Smart Bat hardware:

```dart
// services/ble_service.dart
class BLEService {
  // UUID constants from ESP32
  static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  
  // Connection management
  Future<List<BluetoothDevice>> scanForDevices();
  Future<void> connectToDevice(BluetoothDevice device);
  Future<void> disconnect();
  
  // Data streams
  Stream<bool> get connectionStream;
  Stream<ShotModel> get shotStream;
  Stream<BLEException> get errorStream;
}
```

### Hardware Simulator

For development without hardware:

```dart
// services/hardware_simulator.dart
class HardwareSimulator {
  void startSimulation();
  void stopSimulation();
  ShotModel generateRandomShot();
  SensorData generateSensorData();
}
```

### Testing BLE Integration

```dart
// test/ble_service_test.dart
void main() {
  group('BLEService Tests', () {
    test('should scan for devices', () async {
      final bleService = BLEService();
      final devices = await bleService.scanForDevices();
      expect(devices, isA<List<BluetoothDevice>>());
    });
    
    test('should detect shots from sensor data', () {
      final testData = "20.0,15.0,25.0,300.0,250.0,200.0";
      final sensorData = bleService.parseSensorData(testData);
      final isShot = bleService.isShotDetected(sensorData);
      expect(isShot, true);
    });
  });
}
```

---

## 🔥 Firebase Integration

### Authentication

```dart
// services/auth_service.dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        return await _firestoreService.getUserProfile(credential.user!.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
}
```

### Firestore Database

```dart
// services/firestore_service.dart
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> saveShot(ShotModel shot) async {
    try {
      await _firestore.collection('shots').doc(shot.shotId).set(shot.toJson());
    } catch (e) {
      throw Exception('Failed to save shot: $e');
    }
  }
  
  Future<List<ShotModel>> getSessionShots(String sessionId) async {
    try {
      final querySnapshot = await _firestore
          .collection('shots')
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('timestamp')
          .get();
      
      return querySnapshot.docs
          .map((doc) => ShotModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get session shots: $e');
    }
  }
}
```

### Storage

```dart
// services/storage_service.dart
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  Future<String> uploadVideo(String filePath, String userId) async {
    try {
      final ref = _storage.ref('videos/$userId/${DateTime.now().millisecondsSinceEpoch}.mp4');
      final uploadTask = ref.putFile(File(filePath));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }
}
```

---

## 🧪 Testing

### Unit Tests

```dart
// test/unit/ble_service_test.dart
void main() {
  group('BLEService Unit Tests', () {
    late BLEService bleService;
    
    setUp(() {
      bleService = BLEService();
    });
    
    tearDown(() {
      bleService.dispose();
    });
    
    test('should initialize with disconnected state', () {
      expect(bleService.isConnected, false);
      expect(bleService.currentConnectionState, ConnectionState.disconnected);
    });
    
    test('should validate sensor data format', () {
      expect(DataValidator.isValidSensorData('1.0,2.0,3.0,4.0,5.0,6.0'), true);
      expect(DataValidator.isValidSensorData('invalid,data'), false);
    });
  });
}
```

### Integration Tests

```dart
// integration_test/app_test.dart
void main() {
  group('App Integration Tests', () {
    testWidgets('should navigate to dashboard after login', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Test login flow
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
      
      await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(Key('password_field')), 'password123');
      
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      
      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/ble_service_test.dart

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/
```

---

## 🚀 Development Workflow

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/new-feature

# Make changes and commit
git add .
git commit -m "feat: add new feature"

# Push branch
git push origin feature/new-feature

# Create pull request
# Review and merge
```

### Code Style

Follow Flutter/Dart style guidelines:

```dart
// Use proper naming conventions
class BLEService {
  static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  
  Future<void> connectToDevice(BluetoothDevice device) async {
    // Implementation
  }
}

// Use proper documentation
/// Bluetooth Low Energy service for connecting to Smart Bat hardware
/// Handles scanning, connecting, and receiving sensor data from ESP32 + BNO055
class BLEService {
  // Implementation
}
```

### Code Analysis

```bash
# Analyze code
flutter analyze

# Format code
dart format .

# Check for issues
flutter doctor
```

---

## 🔧 Development Tools

### Debugging

#### Flutter Inspector
- Use Flutter Inspector in Android Studio/VS Code
- Inspect widget tree and properties
- Debug layout issues

#### Logging
```dart
// Use proper logging
import 'dart:developer' as developer;

void debugLog(String message) {
  if (kDebugMode) {
    developer.log(message, name: 'SmartCricketBat');
  }
}
```

#### Breakpoints
- Set breakpoints in IDE
- Use `debugger()` statement
- Inspect variables and state

### Performance Monitoring

```dart
// Monitor performance
import 'dart:developer' as developer;

void monitorPerformance() {
  developer.Timeline.startSync('operation_name');
  // Your code here
  developer.Timeline.finishSync();
}
```

### Memory Management

```dart
// Proper disposal
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  StreamSubscription? _subscription;
  
  @override
  void initState() {
    super.initState();
    _subscription = someStream.listen((data) {
      // Handle data
    });
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

---

## 📱 Platform-Specific Development

### Android Development

#### Permissions
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

#### Native Code
```kotlin
// android/app/src/main/kotlin/com/coacheseyeai/smartcricketbat/MainActivity.kt
package com.coacheseyeai.smartcricketbat

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    // Custom native code here
}
```

### iOS Development

#### Permissions
```xml
<!-- ios/Runner/Info.plist -->
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app uses Bluetooth to connect to the Smart Bat to analyze your cricket shots.</string>
<key>NSCameraUsageDescription</key>
<string>This app uses the camera to record cricket training sessions for analysis.</string>
```

#### Native Code
```swift
// ios/Runner/AppDelegate.swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## 🔍 Common Development Tasks

### Adding a New Feature

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/new-feature
   ```

2. **Create Feature Structure**
   ```
   lib/src/features/new_feature/
   ├── new_feature_screen.dart
   ├── new_feature_widget.dart
   └── new_feature_service.dart
   ```

3. **Implement Feature**
   ```dart
   // new_feature_screen.dart
   class NewFeatureScreen extends ConsumerWidget {
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       return Scaffold(
         appBar: AppBar(title: Text('New Feature')),
         body: NewFeatureWidget(),
       );
     }
   }
   ```

4. **Add Tests**
   ```dart
   // test/features/new_feature_test.dart
   void main() {
     group('NewFeature Tests', () {
       test('should work correctly', () {
         // Test implementation
       });
     });
   }
   ```

5. **Update Documentation**
   - Update API documentation
   - Update user guide if needed
   - Update README if needed

### Debugging Issues

1. **Check Logs**
   ```bash
   flutter logs
   ```

2. **Use Debug Mode**
   ```bash
   flutter run --debug
   ```

3. **Check Firebase Console**
   - Check Firestore data
   - Check Authentication users
   - Check Storage files

4. **Test on Real Device**
   ```bash
   flutter run -d <device-id>
   ```

### Performance Optimization

1. **Profile App**
   ```bash
   flutter run --profile
   ```

2. **Check Memory Usage**
   ```dart
   import 'dart:developer' as developer;
   
   void checkMemory() {
     developer.Timeline.startSync('memory_check');
     // Your code
     developer.Timeline.finishSync();
   }
   ```

3. **Optimize Images**
   - Use appropriate image formats
   - Compress images
   - Use cached images

4. **Optimize Widgets**
   - Use const constructors
   - Avoid unnecessary rebuilds
   - Use proper keys

---

## 📚 Learning Resources

### Flutter Documentation
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Widget Catalog](https://flutter.dev/docs/development/ui/widgets)

### Firebase Documentation
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)

### BLE Development
- [Flutter Blue Plus](https://pub.dev/packages/flutter_blue_plus)
- [Bluetooth Low Energy Guide](https://developer.android.com/guide/topics/connectivity/bluetooth/ble-overview)
- [ESP32 BLE Documentation](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/bluetooth/esp_gattc.html)

### Testing
- [Flutter Testing Guide](https://flutter.dev/docs/testing)
- [Widget Testing](https://flutter.dev/docs/cookbook/testing/widget)
- [Integration Testing](https://flutter.dev/docs/cookbook/testing/integration)

---

## 🤝 Contributing Guidelines

### Code Standards

1. **Follow Dart Style Guide**
2. **Write Comprehensive Tests**
3. **Document Public APIs**
4. **Use Meaningful Commit Messages**
5. **Keep Functions Small and Focused**

### Pull Request Process

1. **Create Feature Branch**
2. **Write Tests**
3. **Update Documentation**
4. **Submit Pull Request**
5. **Address Review Feedback**
6. **Merge After Approval**

### Code Review Checklist

- [ ] **Code follows style guidelines**
- [ ] **Tests are comprehensive**
- [ ] **Documentation is updated**
- [ ] **No breaking changes**
- [ ] **Performance is acceptable**
- [ ] **Security considerations addressed**

---

## 🆘 Getting Help

### Internal Resources

- **Team Slack**: #smart-cricket-bat-dev
- **Code Reviews**: GitHub pull requests
- **Documentation**: This guide and API docs
- **Architecture Decisions**: ADR documents

### External Resources

- **Flutter Community**: [flutter.dev/community](https://flutter.dev/community)
- **Stack Overflow**: [stackoverflow.com/questions/tagged/flutter](https://stackoverflow.com/questions/tagged/flutter)
- **GitHub Issues**: Project repository issues
- **Firebase Support**: [firebase.google.com/support](https://firebase.google.com/support)

### Mentorship

- **Pair Programming**: Work with senior developers
- **Code Reviews**: Learn from feedback
- **Technical Discussions**: Participate in team discussions
- **Learning Sessions**: Attend team learning sessions

---

## 🎯 Next Steps

### Immediate Tasks

1. **Set up development environment**
2. **Run the app locally**
3. **Explore the codebase**
4. **Write your first test**
5. **Make your first contribution**

### Learning Path

1. **Week 1**: Environment setup and codebase exploration
2. **Week 2**: Understanding architecture and services
3. **Week 3**: BLE integration and hardware communication
4. **Week 4**: Firebase integration and data management
5. **Week 5**: Testing and debugging techniques
6. **Week 6**: Performance optimization and best practices

### Long-term Goals

- **Master Flutter development**
- **Understand BLE communication**
- **Become proficient with Firebase**
- **Contribute to open source**
- **Mentor other developers**

---

**Welcome to the team! 🎉**

This guide should get you started with the Smart Cricket Bat app development. Don't hesitate to ask questions and seek help when needed. Happy coding!
