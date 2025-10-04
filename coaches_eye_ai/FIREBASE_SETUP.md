# Firebase Configuration Guide

## Setup Instructions

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: "coaches-eye-ai"
4. Enable Google Analytics (optional)
5. Create project

### 2. Enable Authentication

1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password" provider
5. Save changes

### 3. Enable Firestore Database

1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location for your database
5. Click "Done"

### 4. Add Android App

1. In Firebase Console, click "Add app" → Android
2. Enter package name: `com.example.coaches_eye_ai`
3. Enter app nickname: "Coach's Eye AI Android"
4. Download `google-services.json`
5. Place it in `android/app/` directory

### 5. Add iOS App (if needed)

1. In Firebase Console, click "Add app" → iOS
2. Enter bundle ID: `com.example.coachesEyeAi`
3. Enter app nickname: "Coach's Eye AI iOS"
4. Download `GoogleService-Info.plist`
5. Place it in `ios/Runner/` directory

### 6. Update Package Names

Update the following files with your actual package names:

**android/app/build.gradle:**
```gradle
defaultConfig {
    applicationId "com.yourcompany.coaches_eye_ai"
    // ... other config
}
```

**ios/Runner/Info.plist:**
```xml
<key>CFBundleIdentifier</key>
<string>com.yourcompany.coachesEyeAi</string>
```

### 7. Firestore Security Rules

For development, use these permissive rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

For production, implement proper security rules based on user roles.

### 8. Test Configuration

Run the app and check:
- Authentication works (sign up/sign in)
- Firestore writes/reads work
- No Firebase connection errors in console

## Environment Variables (Optional)

Create a `.env` file for sensitive configuration:

```env
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
```

## Troubleshooting

### Common Issues:

1. **"Firebase not initialized"**
   - Ensure `google-services.json` is in correct location
   - Check package name matches Firebase project

2. **"Permission denied"**
   - Check Firestore security rules
   - Ensure user is authenticated

3. **"Network error"**
   - Check internet connection
   - Verify Firebase project is active

4. **"App not registered"**
   - Ensure SHA-1 fingerprint is added to Firebase project
   - For debug: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`

## Production Checklist

- [ ] Update package names to production values
- [ ] Implement proper Firestore security rules
- [ ] Enable App Check for security
- [ ] Set up proper error monitoring
- [ ] Configure Firebase Analytics
- [ ] Test on real devices
- [ ] Set up CI/CD pipeline
