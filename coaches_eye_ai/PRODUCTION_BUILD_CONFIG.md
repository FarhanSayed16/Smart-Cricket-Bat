# Production Build Configuration for Smart Cricket Bat App

## Android Release Configuration

### 1. Update android/app/build.gradle

```gradle
android {
    compileSdkVersion 34
    ndkVersion "25.1.8937393"

    defaultConfig {
        applicationId "com.coacheseyeai.smartcricketbat"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        
        // Production optimizations
        multiDexEnabled true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }

    buildTypes {
        release {
            // Production build settings
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            
            // Performance optimizations
            debuggable false
            jniDebuggable false
            renderscriptDebuggable false
            zipAlignEnabled true
            
            // Build config fields
            buildConfigField "boolean", "DEBUG_MODE", "false"
            buildConfigField "String", "API_BASE_URL", '"https://api.coacheseyeai.com"'
        }
        
        debug {
            // Debug build settings
            debuggable true
            minifyEnabled false
            shrinkResources false
            
            buildConfigField "boolean", "DEBUG_MODE", "true"
            buildConfigField "String", "API_BASE_URL", '"https://api-dev.coacheseyeai.com"'
        }
    }

    // Signing configuration
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
}

// Load keystore properties
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

### 2. Create android/app/proguard-rules.pro

```proguard
# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# BLE specific rules
-keep class com.boskokg.flutter_blue_plus.** { *; }
-keep class com.boskokg.flutter_blue_plus_example.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Optimize
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify
```

### 3. Update android/app/src/main/AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Production permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    
    <!-- Bluetooth permissions -->
    <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <!-- Camera permissions -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    
    <!-- Storage permissions -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    
    <!-- Hardware features -->
    <uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    
    <application
        android:label="Coach's Eye AI"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:allowBackup="false"
        android:hardwareAccelerated="true"
        android:largeHeap="true"
        android:usesCleartextTraffic="false">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
                
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <!-- Firebase services -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="coaches_eye_ai_channel" />
            
        <!-- Don't delete the meta-data below -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

## iOS Release Configuration

### 1. Update ios/Runner/Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>Coach's Eye AI</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>coaches_eye_ai</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    
    <!-- Bluetooth permissions -->
    <key>NSBluetoothPeripheralUsageDescription</key>
    <string>This app uses Bluetooth to connect to the Smart Bat to analyze your cricket shots.</string>
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>This app uses Bluetooth to connect to the Smart Bat to analyze your cricket shots.</string>
    
    <!-- Camera permissions -->
    <key>NSCameraUsageDescription</key>
    <string>This app uses the camera to record cricket training sessions for analysis.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>This app uses the microphone to record audio during training sessions.</string>
    
    <!-- Location permissions -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app uses location services to improve Bluetooth device discovery.</string>
    
    <!-- Photo library permissions -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>This app accesses your photo library to save training session videos.</string>
    
    <!-- Background modes -->
    <key>UIBackgroundModes</key>
    <array>
        <string>bluetooth-central</string>
        <string>background-processing</string>
    </array>
    
    <!-- Required device capabilities -->
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
        <string>bluetooth-le</string>
    </array>
    
    <!-- Supported orientations -->
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    
    <!-- Launch screen -->
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    
    <!-- Main storyboard -->
    <key>UIMainStoryboardFile</key>
    <string>Main</string>
    
    <!-- Don't delete the meta-data below -->
    <key>flutterEmbedding</key>
    <integer>2</integer>
</dict>
</plist>
```

## Flutter Build Configuration

### 1. Create build.yaml

```yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          # Configure JSON serialization
          explicit_to_json: true
          include_if_null: false
          
      # Configure build optimizations
      build_runner:
        options:
          delete_conflicting_outputs: true
```

### 2. Update pubspec.yaml

```yaml
name: coaches_eye_ai
description: Smart Cricket Bat Training App
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter
  
  # Core dependencies
  cupertino_icons: ^1.0.8
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  firebase_storage: ^12.3.2
  firebase_analytics: ^11.3.2
  firebase_crashlytics: ^4.1.3
  
  # State management
  flutter_riverpod: ^2.6.1
  
  # BLE and hardware
  flutter_blue_plus: ^1.31.8
  permission_handler: ^11.3.1
  
  # Utilities
  uuid: ^4.5.1
  intl: ^0.19.0
  shared_preferences: ^2.3.2
  path_provider: ^2.1.4
  path: ^1.9.0
  
  # UI and media
  fl_chart: ^0.69.0
  image_picker: ^1.1.2
  camera: ^0.10.5+9
  video_player: ^2.8.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  
  # Code generation
  build_runner: ^2.4.7
  json_annotation: ^4.8.1
  json_serializable: ^6.7.1
  
  # Testing
  mockito: ^5.4.4
  integration_test:
    sdk: flutter

flutter:
  uses-material-design: true
  
  # Assets
  assets:
    - assets/images/
    - assets/icons/
    - assets/animations/
  
  # Fonts
  fonts:
    - family: Roboto
      fonts:
        - asset: assets/fonts/Roboto-Regular.ttf
        - asset: assets/fonts/Roboto-Bold.ttf
          weight: 700
```

## Build Scripts

### 1. Create scripts/build_release.sh

```bash
#!/bin/bash

# Production build script for Smart Cricket Bat App

set -e

echo "🚀 Starting production build process..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Run tests
echo "🧪 Running tests..."
flutter test

# Analyze code
echo "🔍 Analyzing code..."
flutter analyze

# Build Android release
echo "📱 Building Android release..."
flutter build apk --release --target-platform android-arm64

# Build iOS release (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Building iOS release..."
    flutter build ios --release --no-codesign
fi

# Build web release
echo "🌐 Building web release..."
flutter build web --release

echo "✅ Production build completed successfully!"
echo "📦 Output files:"
echo "   - Android APK: build/app/outputs/flutter-apk/app-release.apk"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "   - iOS App: build/ios/Release-iphoneos/Runner.app"
fi
echo "   - Web App: build/web/"
```

### 2. Create scripts/build_debug.sh

```bash
#!/bin/bash

# Debug build script

set -e

echo "🔧 Starting debug build process..."

# Clean and get dependencies
flutter clean
flutter pub get

# Build debug APK
flutter build apk --debug

echo "✅ Debug build completed!"
```

## Release Checklist

### Pre-Release Checklist

- [ ] **Code Quality**
  - [ ] All tests passing
  - [ ] Code analysis clean (flutter analyze)
  - [ ] No TODO comments in production code
  - [ ] Documentation updated

- [ ] **Security**
  - [ ] No hardcoded secrets or API keys
  - [ ] Proper error handling implemented
  - [ ] Input validation in place
  - [ ] BLE permissions properly configured

- [ ] **Performance**
  - [ ] Memory leaks checked
  - [ ] Battery usage optimized
  - [ ] BLE scanning intervals configured
  - [ ] Background processing optimized

- [ ] **Testing**
  - [ ] Unit tests coverage > 80%
  - [ ] Integration tests passing
  - [ ] Manual testing on real devices
  - [ ] BLE connection testing with hardware

- [ ] **Build Configuration**
  - [ ] Release signing configured
  - [ ] ProGuard/R8 rules applied
  - [ ] App icons and splash screens
  - [ ] Version numbers updated

### Post-Release Checklist

- [ ] **Monitoring**
  - [ ] Firebase Crashlytics enabled
  - [ ] Analytics tracking configured
  - [ ] Performance monitoring active
  - [ ] Error reporting working

- [ ] **Documentation**
  - [ ] Release notes prepared
  - [ ] User guide updated
  - [ ] API documentation current
  - [ ] Troubleshooting guide available

## Environment Configuration

### 1. Create .env files

**.env.production**
```
FIREBASE_PROJECT_ID=coaches-eye-ai-prod
API_BASE_URL=https://api.coacheseyeai.com
DEBUG_MODE=false
LOG_LEVEL=ERROR
```

**.env.development**
```
FIREBASE_PROJECT_ID=coaches-eye-ai-dev
API_BASE_URL=https://api-dev.coacheseyeai.com
DEBUG_MODE=true
LOG_LEVEL=DEBUG
```

### 2. Create config.dart

```dart
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

This comprehensive build configuration ensures your Smart Cricket Bat app is production-ready with proper security, performance optimizations, and release management.
