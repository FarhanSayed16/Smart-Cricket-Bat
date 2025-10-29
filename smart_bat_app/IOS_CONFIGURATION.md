# iOS Configuration for Smart Cricket Bat App

## Overview
This document outlines the iOS-specific configuration and setup for the Smart Cricket Bat application.

## Required iOS Permissions

### Info.plist Configuration
The following permissions are required in `ios/Runner/Info.plist`:

```xml
<!-- Camera Permission -->
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to record cricket shot videos for analysis.</string>

<!-- Microphone Permission -->
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record audio with cricket shot videos.</string>

<!-- Bluetooth Permission -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth access to connect to the Smart Cricket Bat device.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth access to connect to the Smart Cricket Bat device.</string>

<!-- Location Permission -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access for Bluetooth device scanning.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access for Bluetooth device scanning.</string>

<!-- Photo Library Permission -->
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to save cricket shot videos.</string>
```

### Background Modes
```xml
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
    <string>background-processing</string>
    <string>remote-notification</string>
</array>
```

## Firebase Configuration

### GoogleService-Info.plist
1. Download the iOS configuration file from Firebase Console
2. Place it in `ios/Runner/GoogleService-Info.plist`
3. Ensure the bundle ID matches your app's bundle identifier

### Firebase App Delegate
Add to `ios/Runner/AppDelegate.swift`:
```swift
import UIKit
import Flutter
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## BLE Configuration

### iOS-Specific BLE Settings
- **Scan Timeout**: 10 seconds (iOS limitation)
- **Connection Timeout**: 15 seconds
- **Service Discovery Timeout**: 5 seconds
- **Auto-reconnect**: Disabled (iOS best practice)

### Required Device Capabilities
```xml
<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>armv7</string>
    <string>bluetooth-le</string>
</array>
```

## Push Notifications

### APNs Configuration
1. Enable Push Notifications capability in Xcode
2. Configure APNs certificates in Firebase Console
3. Add background modes for remote notifications

### Notification Payload
```json
{
  "aps": {
    "alert": {
      "title": "Smart Cricket Bat",
      "body": "New session data available"
    },
    "badge": 1,
    "sound": "default"
  },
  "data": {
    "type": "session_reminder",
    "sessionId": "session_123"
  }
}
```

## App Store Requirements

### Minimum iOS Version
- **Target**: iOS 12.0+
- **Recommended**: iOS 14.0+

### App Store Guidelines Compliance
- **Privacy Policy**: Required for data collection
- **Terms of Service**: Required for user agreements
- **App Review**: Submit with test account credentials
- **Screenshots**: Required for all device sizes

### Required App Information
- **App Name**: Smart Cricket Bat
- **Bundle ID**: com.example.smart_bat_app
- **Category**: Sports
- **Age Rating**: 4+ (suitable for all ages)

## Testing Requirements

### Device Testing
- **iPhone**: Test on multiple screen sizes
- **iPad**: Ensure proper layout scaling
- **iOS Versions**: Test on iOS 12, 14, 15, 16+

### BLE Testing
- **Device Compatibility**: Test with ESP32 hardware
- **Connection Stability**: Test connection reliability
- **Background Behavior**: Test BLE in background

### Camera Testing
- **Video Recording**: Test video capture quality
- **Storage**: Test video storage and retrieval
- **Permissions**: Test permission flow

## Performance Optimization

### iOS-Specific Optimizations
- **Memory Management**: Proper disposal of resources
- **Battery Usage**: Optimize BLE scanning intervals
- **Background Processing**: Efficient background tasks
- **Image Processing**: Optimize video processing

### App Size Optimization
- **Asset Optimization**: Compress images and videos
- **Code Stripping**: Remove unused code
- **Dependency Management**: Minimize dependencies

## Security Considerations

### Data Protection
- **Keychain**: Store sensitive data securely
- **App Transport Security**: Enforce HTTPS
- **Certificate Pinning**: Secure API communications

### Privacy Compliance
- **Data Collection**: Transparent data usage
- **User Consent**: Clear permission requests
- **Data Retention**: Implement data deletion

## Deployment Checklist

### Pre-Release
- [ ] All permissions properly configured
- [ ] Firebase services working
- [ ] BLE functionality tested
- [ ] Push notifications working
- [ ] App Store assets prepared
- [ ] Privacy policy and terms ready

### App Store Submission
- [ ] App metadata completed
- [ ] Screenshots uploaded
- [ ] App review information provided
- [ ] Test account credentials shared
- [ ] App Store review submitted

### Post-Release
- [ ] Monitor crash reports
- [ ] Track user feedback
- [ ] Update app as needed
- [ ] Maintain Firebase services

## Troubleshooting

### Common iOS Issues
1. **BLE Scanning**: Location permission required
2. **Background BLE**: Proper background modes needed
3. **Camera Access**: Permission flow must be clear
4. **Firebase**: Proper configuration files required

### Debug Tools
- **Xcode Console**: For debugging logs
- **Firebase Console**: For analytics and crashes
- **TestFlight**: For beta testing

## Support Resources
- **Apple Developer Documentation**: https://developer.apple.com/documentation/
- **Firebase iOS Documentation**: https://firebase.google.com/docs/ios
- **Flutter iOS Documentation**: https://docs.flutter.dev/deployment/ios
