# Firebase Setup Guide for Coach's Eye AI

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `coaches-eye-ai` (or your preferred name)
4. Enable Google Analytics (optional)
5. Click "Create project"

## Step 2: Add Android App

1. In your Firebase project, click "Add app" and select Android
2. Enter package name: `com.example.coaches_eye_ai`
3. Enter app nickname: `Coach's Eye AI`
4. Enter SHA-1 certificate fingerprint (optional for now)
5. Click "Register app"
6. Download the `google-services.json` file
7. Place it in `android/app/` directory

## Step 3: Add Web App (for web support)

1. Click "Add app" and select Web
2. Enter app nickname: `Coach's Eye AI Web`
3. Click "Register app"
4. Copy the Firebase configuration object

## Step 4: Enable Authentication

1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password" provider
5. Click "Save"

## Step 5: Enable Firestore Database

1. Go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location (choose closest to your users)
5. Click "Done"

## Step 6: Update Firebase Configuration

Replace the placeholder values in `lib/firebase_options.dart` with your actual Firebase configuration:

```dart
// Get these values from Firebase Console > Project Settings > General > Your apps

static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_WEB_API_KEY', // From Firebase Console
  appId: 'YOUR_WEB_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
);

static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY', // From Firebase Console
  appId: 'YOUR_ANDROID_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
);
```

## Step 7: Enable Required APIs

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Go to "APIs & Services" > "Library"
4. Enable these APIs:
   - Identity Toolkit API
   - Cloud Firestore API
   - Firebase Authentication API

## Step 8: Test the Setup

1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter run`
4. Try to create an account in the app

## Troubleshooting

### API Key Issues
- Ensure the API key in `firebase_options.dart` matches the one in Firebase Console
- Check that the Identity Toolkit API is enabled
- Verify API key restrictions allow your app

### Build Issues
- Make sure `google-services.json` is in `android/app/` directory
- Run `flutter clean` and `flutter pub get` after adding Firebase files
- Check that all required dependencies are in `pubspec.yaml`

### Authentication Issues
- Verify Email/Password provider is enabled in Firebase Console
- Check Firestore security rules allow read/write for authenticated users
- Ensure the project ID matches in all configuration files

## Security Rules for Firestore

Add these rules to your Firestore database:

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
        resource.data.sessionId in get(/databases/$(database)/documents/sessions/$(resource.data.sessionId)).data.playerId == request.auth.uid;
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
