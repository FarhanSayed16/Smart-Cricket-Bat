# 🔥 Firebase Manual Setup Guide - Coach's Eye AI (Free Tier)

## 📋 **Overview**

This guide will help you manually set up Firebase for your Smart Cricket Bat application using the **Firebase Free Tier (Spark Plan)**. Since automatic setup didn't work, we'll configure everything manually through the Firebase Console.

---

## 🎯 **Firebase Free Tier Features Available**

### ✅ **What's Included in Free Tier:**
- **Authentication**: Unlimited users
- **Firestore Database**: 1GB storage, 50K reads/day, 20K writes/day
- **Storage**: 1GB storage, 10GB/month downloads
- **Functions**: 125K invocations/month, 40K GB-seconds compute
- **Analytics**: Unlimited events
- **Performance Monitoring**: Unlimited traces
- **Crashlytics**: Unlimited crash reports
- **Remote Config**: 5 parameters, 1K requests/day
- **Cloud Messaging**: Unlimited messages

### ❌ **What's NOT Available in Free Tier:**
- **App Check**: Requires Blaze plan
- **Advanced Analytics**: Some features require Blaze
- **Custom Domains**: Requires Blaze plan
- **Multiple Environments**: Limited in free tier

---

## 🚀 **Step-by-Step Manual Setup**

### **Step 1: Create Firebase Project**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Create a project"**
3. Enter project name: `coaches-eye-ai`
4. Click **"Continue"**
5. **Disable Google Analytics** (to stay in free tier)
6. Click **"Create project"**
7. Wait for project creation to complete
8. Click **"Continue"**

### **Step 2: Add Android App**

1. In Firebase Console, click **"Add app"** → **Android**
2. Enter package name: `com.example.coaches_eye_ai` (or your actual package name)
3. Enter app nickname: `Coach's Eye AI Android`
4. Enter SHA-1 certificate fingerprint (optional for now)
5. Click **"Register app"**
6. Download `google-services.json`
7. Place `google-services.json` in `android/app/` folder
8. Click **"Next"** → **"Next"** → **"Continue to console"**

### **Step 3: Add Web App**

1. In Firebase Console, click **"Add app"** → **Web**
2. Enter app nickname: `Coach's Eye AI Web`
3. **Enable Firebase Hosting** (optional)
4. Click **"Register app"**
5. Copy the Firebase config object
6. Click **"Continue to console"**

### **Step 4: Enable Authentication**

1. Go to **Authentication** → **Sign-in method**
2. Click **"Email/Password"**
3. **Enable** Email/Password authentication
4. Click **"Save"**

### **Step 5: Create Firestore Database**

1. Go to **Firestore Database**
2. Click **"Create database"**
3. Choose **"Start in test mode"** (for development)
4. Select location: **us-central1** (recommended)
5. Click **"Done"**

#### **Set Up Security Rules:**

1. Go to **Firestore Database** → **Rules**
2. Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Sessions are accessible by the player who created them
    match /sessions/{sessionId} {
      allow read, write: if request.auth != null && 
        resource.data.playerId == request.auth.uid;
    }
    
    // Shots are accessible by the player who created them
    match /shots/{shotId} {
      allow read, write: if request.auth != null && 
        resource.data.playerId == request.auth.uid;
    }
    
    // Player profiles
    match /playerProfiles/{playerId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == playerId || 
         resource.data.coachId == request.auth.uid);
    }
    
    // Coach profiles
    match /coachProfiles/{coachId} {
      allow read, write: if request.auth != null && request.auth.uid == coachId;
    }
    
    // Coach invite codes
    match /coachInviteCodes/{code} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

3. Click **"Publish"**

### **Step 6: Enable Firebase Storage**

1. Go to **Storage**
2. Click **"Get started"**
3. Choose **"Start in test mode"** (for development)
4. Select location: **us-central1** (recommended)
5. Click **"Done"**

#### **Set Up Storage Rules:**

1. Go to **Storage** → **Rules**
2. Replace the default rules with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User-specific files - users can only access their own files
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Cricket analysis files - users can only access their own analysis
    match /analysis/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Cricket videos - users can only access their own videos
    match /videos/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public shared analysis - readable by all, writable by authenticated users
    match /public-analysis/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Profile images - readable by all, writable by owner
    match /profile-images/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Thumbnails and previews - readable by all
    match /thumbnails/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Temporary files - users can create and read their own temp files
    match /temp/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

3. Click **"Publish"**

### **Step 7: Enable Firebase Analytics (Optional)**

1. Go to **Analytics** → **Dashboard**
2. Click **"Get started"**
3. Choose **"Enable Google Analytics"**
4. Select **"Default Analytics account"**
5. Click **"Enable Analytics"**

### **Step 8: Enable Firebase Performance (Optional)**

1. Go to **Performance**
2. Click **"Get started"**
3. Follow the setup instructions
4. This will help monitor your app's performance

### **Step 9: Enable Firebase Crashlytics (Optional)**

1. Go to **Crashlytics**
2. Click **"Get started"**
3. Follow the setup instructions
4. This will help track app crashes

### **Step 10: Skip Firebase Functions (Optional)**

**Functions are not required for basic cricket analysis.** You can skip this step unless you need server-side processing.

---

## 📱 **Flutter App Integration**

### **1. Update `pubspec.yaml`**

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase Core
  firebase_core: ^2.24.2
  
  # Firebase Services
  cloud_firestore: ^4.13.6
  firebase_auth: ^4.15.3
  firebase_storage: ^11.2.6
  firebase_analytics: ^10.7.4
  firebase_performance: ^0.9.2+4
  firebase_crashlytics: ^3.4.9
  firebase_remote_config: ^4.3.8
  firebase_messaging: ^14.7.10
  
  # Other dependencies
  image_picker: ^1.0.4
  video_player: ^2.8.1
  permission_handler: ^11.0.1
  path_provider: ^2.1.1
  shared_preferences: ^2.2.2
```

### **2. Generate Firebase Options**

Run this command to generate `firebase_options.dart`:

```bash
flutterfire configure
```

This will create the `firebase_options.dart` file with your project configuration.

### **3. Update `main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase services
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  FirebasePerformance performance = FirebasePerformance.instance;
  FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;
  FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  // Set up error handling
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coach\'s Eye AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}
```

### **4. Test Firebase Integration**

Create a test file to verify Firebase is working:

```dart
// test_firebase.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseTest {
  static Future<void> testFirestore() async {
    try {
      await FirebaseFirestore.instance
          .collection('test')
          .add({'message': 'Hello Firebase!', 'timestamp': DateTime.now()});
      print('✅ Firestore test successful');
    } catch (e) {
      print('❌ Firestore test failed: $e');
    }
  }
  
  static Future<void> testStorage() async {
    try {
      final ref = FirebaseStorage.instance.ref('test/file.txt');
      await ref.putString('Hello Storage!');
      print('✅ Storage test successful');
    } catch (e) {
      print('❌ Storage test failed: $e');
    }
  }
  
  static Future<void> testAnalytics() async {
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'test_event',
        parameters: {'test': 'value'},
      );
      print('✅ Analytics test successful');
    } catch (e) {
      print('❌ Analytics test failed: $e');
    }
  }
}
```

---

## 🔧 **Configuration Files**

### **Essential Files You Need:**

1. **`android/app/google-services.json`** - Android configuration
2. **`firebase_options.dart`** - Flutter configuration
3. **`pubspec.yaml`** - Dependencies

### **Your Firebase Project Details:**

After setup, you'll have:
- **Project ID**: `coaches-eye-ai`
- **Storage Bucket**: `coaches-eye-ai.firebasestorage.app`
- **Web App ID**: Generated automatically
- **Android App ID**: Generated automatically

---

## ✅ **Verification Checklist**

After completing the setup:

- [ ] Firebase project created
- [ ] Android app added with `google-services.json`
- [ ] Web app added
- [ ] Authentication enabled (Email/Password)
- [ ] Firestore database created with security rules
- [ ] Storage enabled with security rules
- [ ] Analytics enabled (optional)
- [ ] Performance monitoring enabled (optional)
- [ ] Crashlytics enabled (optional)
- [ ] Flutter dependencies added
- [ ] `firebase_options.dart` generated
- [ ] Firebase services initialized in `main.dart`
- [ ] Test functions working
- [ ] App running without errors

---

## 🆘 **Troubleshooting**

### **Common Issues:**

1. **"Firebase not initialized"**
   - Ensure `firebase_options.dart` is up to date
   - Check `google-services.json` is in `android/app/`
   - Run `flutter clean` and `flutter pub get`

2. **"Permission denied"**
   - Check Firestore security rules
   - Ensure user is authenticated
   - Verify rules are published

3. **"Storage not enabled"**
   - Enable Storage in Firebase Console first
   - Check storage rules are published

4. **"Functions not found"**
   - Functions are optional for basic apps
   - Skip if not needed

5. **"Analytics not working"**
   - Analytics is optional
   - Check if Google Analytics is enabled

### **Support Resources:**

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)

---

## 🎉 **You're All Set!**

Once you complete the manual steps above, your Firebase project will be fully configured for your Smart Cricket Bat application. The free tier provides more than enough resources for development and testing.

**Next Steps:**
1. Complete manual setup in Firebase Console
2. Update Flutter app with dependencies
3. Test Firebase integration
4. Start building your cricket analysis features!

---

## 📊 **Estimated Setup Time**

- **Firebase Console Setup**: 15-20 minutes
- **Flutter Integration**: 10-15 minutes
- **Testing**: 5-10 minutes
- **Total**: 30-45 minutes

**Your Firebase project will be 100% manually configured!** 🚀
