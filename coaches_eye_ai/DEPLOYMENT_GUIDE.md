# 🚀 Deployment Guide - Smart Cricket Bat App

## Overview

This guide covers the complete deployment process for the Smart Cricket Bat app, from development to production release on app stores.

---

## 📋 Pre-Deployment Checklist

### Code Quality
- [ ] All tests passing (Unit, Integration, Performance)
- [ ] Code analysis clean (`flutter analyze`)
- [ ] No TODO comments in production code
- [ ] Documentation updated
- [ ] Version numbers updated
- [ ] Changelog prepared

### Security
- [ ] No hardcoded secrets or API keys
- [ ] Proper error handling implemented
- [ ] Input validation in place
- [ ] BLE permissions properly configured
- [ ] Firebase security rules deployed

### Performance
- [ ] Memory leaks checked
- [ ] Battery usage optimized
- [ ] BLE scanning intervals configured
- [ ] Background processing optimized
- [ ] App size optimized

### Testing
- [ ] Unit tests coverage > 80%
- [ ] Integration tests passing
- [ ] Manual testing on real devices
- [ ] BLE connection testing with hardware
- [ ] Performance testing completed

---

## 🔧 Build Configuration

### Android Build Setup

#### 1. Update `android/app/build.gradle`

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

#### 2. Create `android/app/proguard-rules.pro`

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

#### 3. Create `android/key.properties`

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=../keystore.jks
```

### iOS Build Setup

#### 1. Update `ios/Runner/Info.plist`

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

---

## 🔐 App Signing

### Android Signing

#### 1. Generate Keystore

```bash
keytool -genkey -v -keystore keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias your_key_alias
```

#### 2. Configure Signing

Create `android/key.properties`:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=../keystore.jks
```

#### 3. Update build.gradle

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### iOS Signing

#### 1. Apple Developer Account Setup

- Create Apple Developer account
- Register app identifier
- Create provisioning profiles
- Configure certificates

#### 2. Xcode Configuration

- Open `ios/Runner.xcworkspace` in Xcode
- Select project → Signing & Capabilities
- Configure Team and Bundle Identifier
- Enable required capabilities

---

## 🏗️ Build Scripts

### Production Build Script

Create `scripts/build_release.sh`:

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

### Debug Build Script

Create `scripts/build_debug.sh`:

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

### Make Scripts Executable

```bash
chmod +x scripts/build_release.sh
chmod +x scripts/build_debug.sh
```

---

## 📱 App Store Deployment

### Google Play Store

#### 1. Prepare Release

```bash
# Build release APK
flutter build apk --release

# Build App Bundle (recommended)
flutter build appbundle --release
```

#### 2. Play Console Setup

1. **Create App Listing**
   - App name: "Coach's Eye AI"
   - Short description: "AI-powered cricket batting analysis"
   - Full description: Detailed app description
   - Screenshots: App screenshots
   - Icon: App icon (512x512)

2. **Content Rating**
   - Complete content rating questionnaire
   - Submit for rating

3. **Pricing & Distribution**
   - Set pricing (Free/Paid)
   - Select countries
   - Configure distribution

4. **App Content**
   - Privacy policy URL
   - Terms of service
   - Data safety information

#### 3. Upload Release

1. **Internal Testing**
   - Upload AAB to internal testing
   - Test with internal users
   - Fix any issues

2. **Closed Testing**
   - Upload to closed testing
   - Invite beta testers
   - Collect feedback

3. **Production Release**
   - Upload to production
   - Review and publish
   - Monitor reviews

### Apple App Store

#### 1. Prepare Release

```bash
# Build iOS release
flutter build ios --release

# Archive in Xcode
# Open ios/Runner.xcworkspace in Xcode
# Product → Archive
```

#### 2. App Store Connect Setup

1. **App Information**
   - App name: "Coach's Eye AI"
   - Bundle ID: com.coacheseyeai.smartcricketbat
   - SKU: coaches-eye-ai-ios

2. **App Store Listing**
   - Description and keywords
   - Screenshots for all device sizes
   - App preview videos
   - App icon

3. **App Review Information**
   - Contact information
   - Demo account credentials
   - Review notes

#### 3. Submit for Review

1. **TestFlight Beta**
   - Upload to TestFlight
   - Invite beta testers
   - Test thoroughly

2. **App Store Review**
   - Submit for review
   - Respond to review feedback
   - Address any rejections

3. **Release**
   - Approve for release
   - Set release date
   - Monitor app performance

---

## 🔥 Firebase Deployment

### Firebase Configuration

#### 1. Update Firebase Project

```bash
# Set Firebase project
firebase use coaches-eye-ai

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage

# Deploy Remote Config
firebase deploy --only remoteconfig
```

#### 2. Environment Configuration

Create environment-specific configurations:

**Production Environment**
```dart
class AppConfig {
  static const String firebaseProjectId = 'coaches-eye-ai-prod';
  static const String apiBaseUrl = 'https://api.coacheseyeai.com';
  static const bool debugMode = false;
  static const String logLevel = 'ERROR';
}
```

**Development Environment**
```dart
class AppConfig {
  static const String firebaseProjectId = 'coaches-eye-ai-dev';
  static const String apiBaseUrl = 'https://api-dev.coacheseyeai.com';
  static const bool debugMode = true;
  static const String logLevel = 'DEBUG';
}
```

---

## 📊 Monitoring & Analytics

### Firebase Analytics Setup

```dart
// Initialize Analytics
FirebaseAnalytics analytics = FirebaseAnalytics.instance;

// Track custom events
await analytics.logEvent(
  name: 'session_started',
  parameters: {
    'session_type': 'practice',
    'user_role': 'player',
  },
);

// Track user properties
await analytics.setUserProperty(
  name: 'user_role',
  value: 'player',
);
```

### Crashlytics Setup

```dart
// Initialize Crashlytics
FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;

// Set up error handling
FlutterError.onError = (errorDetails) {
  FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
};

// Log custom errors
crashlytics.recordError(
  'BLE connection failed',
  null,
  information: ['Device: Smart Bat', 'Error: Timeout'],
);
```

### Performance Monitoring

```dart
// Initialize Performance
FirebasePerformance performance = FirebasePerformance.instance;

// Create custom traces
Trace trace = performance.newTrace('ble_connection');
trace.start();

try {
  await bleService.connectToDevice(device);
} finally {
  trace.stop();
}
```

---

## 🚨 Release Checklist

### Pre-Release

- [ ] **Code Quality**
  - [ ] All tests passing
  - [ ] Code analysis clean
  - [ ] No TODO comments
  - [ ] Documentation updated

- [ ] **Security**
  - [ ] No hardcoded secrets
  - [ ] Proper error handling
  - [ ] Input validation
  - [ ] Permissions configured

- [ ] **Performance**
  - [ ] Memory leaks checked
  - [ ] Battery usage optimized
  - [ ] App size optimized
  - [ ] Performance monitoring

- [ ] **Testing**
  - [ ] Unit tests coverage > 80%
  - [ ] Integration tests passing
  - [ ] Manual testing completed
  - [ ] Hardware testing done

### Build Configuration

- [ ] **Signing**
  - [ ] Release signing configured
  - [ ] Keystore secured
  - [ ] Certificates valid

- [ ] **Optimization**
  - [ ] ProGuard/R8 rules applied
  - [ ] App icons and splash screens
  - [ ] Version numbers updated
  - [ ] Firebase configuration verified

### Post-Release

- [ ] **Monitoring**
  - [ ] Crashlytics enabled
  - [ ] Analytics tracking configured
  - [ ] Performance monitoring active
  - [ ] Error reporting working

- [ ] **Documentation**
  - [ ] Release notes prepared
  - [ ] User guide updated
  - [ ] API documentation current
  - [ ] Troubleshooting guide available

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to App Stores

on:
  push:
    tags:
      - 'v*'

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.10.0'
        
    - name: Install dependencies
      run: flutter pub get
      
    - name: Run tests
      run: flutter test
      
    - name: Analyze code
      run: flutter analyze
      
    - name: Build Android APK
      run: flutter build apk --release
      
    - name: Build Android App Bundle
      run: flutter build appbundle --release
      
    - name: Upload to Play Store
      uses: r0adkll/upload-google-play@v1
      with:
        serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
        packageName: com.coacheseyeai.smartcricketbat
        releaseFiles: build/app/outputs/bundle/release/app-release.aab
        track: production
        status: completed
```

### Environment Variables

Set up secrets in GitHub:
- `GOOGLE_PLAY_SERVICE_ACCOUNT`: Google Play service account JSON
- `FIREBASE_TOKEN`: Firebase CI token
- `APPLE_CERTIFICATE`: Apple certificate
- `APPLE_PROVISIONING_PROFILE`: Apple provisioning profile

---

## 📈 Post-Deployment Monitoring

### Key Metrics to Track

1. **App Performance**
   - Crash rate
   - ANR (Application Not Responding) rate
   - App startup time
   - Memory usage

2. **User Engagement**
   - Daily/Monthly active users
   - Session duration
   - Feature usage
   - Retention rates

3. **BLE Performance**
   - Connection success rate
   - Data transmission quality
   - Battery usage
   - Hardware compatibility

4. **Firebase Usage**
   - Firestore read/write operations
   - Storage usage
   - Authentication events
   - Function invocations

### Monitoring Dashboard

Create monitoring dashboard with:
- Real-time crash reports
- Performance metrics
- User analytics
- Error tracking
- BLE connection statistics

---

## 🆘 Rollback Plan

### Emergency Rollback

1. **Immediate Actions**
   - Disable app updates
   - Notify users of issues
   - Investigate root cause

2. **Rollback Process**
   - Revert to previous version
   - Update app store listings
   - Communicate with users

3. **Post-Rollback**
   - Fix identified issues
   - Test thoroughly
   - Plan re-release

### Version Management

- **Semantic Versioning**: Use MAJOR.MINOR.PATCH format
- **Release Branches**: Maintain separate release branches
- **Hotfixes**: Quick fixes for critical issues
- **Feature Flags**: Enable/disable features remotely

---

## 📞 Support & Maintenance

### Post-Deployment Support

1. **User Support**
   - Monitor app store reviews
   - Respond to user feedback
   - Provide technical support

2. **Bug Tracking**
   - Monitor crash reports
   - Track user-reported issues
   - Prioritize fixes

3. **Performance Monitoring**
   - Track app performance
   - Monitor resource usage
   - Optimize as needed

### Regular Maintenance

- **Weekly**: Review crash reports and user feedback
- **Monthly**: Update dependencies and security patches
- **Quarterly**: Performance optimization and feature updates
- **Annually**: Major version updates and platform migrations

---

This deployment guide ensures a smooth, professional release of your Smart Cricket Bat app to production. Follow these steps carefully to achieve a successful deployment and maintain high-quality user experience.
