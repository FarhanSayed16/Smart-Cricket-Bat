# 🏏 Smart Cricket Bat - Coach's Eye AI

A Flutter application that uses AI to analyze cricket batting techniques and provide coaching insights.

## 📱 **Features**

- **Video Analysis**: Record and analyze cricket batting swings
- **AI-Powered Insights**: Get detailed analysis of batting technique
- **Coaching Tips**: Receive personalized coaching recommendations
- **Progress Tracking**: Monitor improvement over time
- **User Authentication**: Secure user accounts with Firebase
- **Cloud Storage**: Store videos and analysis data securely

## 🚀 **Getting Started**

### **Prerequisites**

- Flutter SDK (latest stable version)
- Android Studio / VS Code
- Firebase account (free tier)
- Git

### **Installation**

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Smart-Cricket-Bat/coaches_eye_ai
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Follow the [Firebase Manual Setup Guide](FIREBASE_MANUAL_SETUP.md)
   - Complete manual setup in Firebase Console
   - Configure Flutter app with Firebase services

4. **Run the app**
   ```bash
   flutter run
   ```

## 🔥 **Firebase Configuration**

### **Manual Setup Required**
Since automatic Firebase setup didn't work, you need to complete the setup manually:

- 🔧 **Create Firebase Project**: Set up project in Firebase Console
- 🔧 **Add Android App**: Configure with `google-services.json`
- 🔧 **Add Web App**: Configure web app
- 🔧 **Enable Authentication**: Email/Password authentication
- 🔧 **Create Firestore Database**: Set up database with security rules
- 🔧 **Enable Storage**: Configure file storage with security rules
- 🔧 **Enable Analytics**: Optional analytics tracking
- 🔧 **Enable Performance**: Optional performance monitoring
- 🔧 **Enable Crashlytics**: Optional crash reporting

**Detailed instructions**: See [FIREBASE_MANUAL_SETUP.md](FIREBASE_MANUAL_SETUP.md)

## 📁 **Project Structure**

```
coaches_eye_ai/
├── android/                 # Android-specific files
│   └── app/
│       └── google-services.json # Firebase Android config
├── ios/                     # iOS-specific files
├── lib/                     # Flutter source code
│   ├── main.dart           # App entry point
│   ├── firebase_options.dart # Firebase configuration
│   └── src/                # Source code
│       ├── features/        # App features
│       ├── models/          # Data models
│       ├── services/        # Firebase services
│       └── providers/       # State management
├── FIREBASE_MANUAL_SETUP.md # Firebase setup guide
├── pubspec.yaml            # Flutter dependencies
└── README.md               # This file
```

## 🛠 **Development**

### **Firebase Services Used**

- **Authentication**: User login/signup
- **Firestore**: Database for user data and analysis results
- **Storage**: Video file storage
- **Analytics**: User behavior tracking
- **Performance**: App performance monitoring
- **Crashlytics**: Error reporting
- **Remote Config**: Dynamic app configuration

### **Key Dependencies**

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.2.6
  firebase_analytics: ^10.7.4
  firebase_performance: ^0.9.2+4
  firebase_crashlytics: ^3.4.9
  firebase_remote_config: ^4.3.8
  firebase_messaging: ^14.7.10
  
  # UI & State Management
  provider: ^6.1.1
  flutter_riverpod: ^2.4.9
  
  # Video & Camera
  camera: ^0.10.5+5
  video_player: ^2.8.1
  
  # File Handling
  path_provider: ^2.1.1
  file_picker: ^6.1.1
```

## 📊 **Firebase Free Tier Limits**

### **What's Available**
- **Authentication**: Unlimited users
- **Firestore**: 1GB storage, 50K reads/day, 20K writes/day
- **Storage**: 1GB storage, 10GB/month downloads
- **Functions**: 125K invocations/month
- **Analytics**: Unlimited events
- **Performance**: Unlimited traces
- **Crashlytics**: Unlimited crash reports

### **What's NOT Available**
- **App Check**: Requires paid plan
- **Custom Domains**: Requires paid plan
- **Advanced Analytics**: Some features require paid plan

## 🧪 **Testing**

### **Run Tests**
```bash
flutter test
```

### **Test Firebase Integration**
```bash
# Test Firestore connection
flutter test test/firestore_test.dart

# Test Storage connection
flutter test test/storage_test.dart
```

## 🚀 **Deployment**

### **Android**
```bash
flutter build apk --release
```

### **iOS**
```bash
flutter build ios --release
```

### **Web**
```bash
flutter build web --release
```

## 🔧 **Configuration**

### **Environment Variables**
Create a `.env` file (not included in repo):
```env
FIREBASE_PROJECT_ID=coaches-eye-ai
FIREBASE_STORAGE_BUCKET=coaches-eye-ai.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=419313572643
```

### **Firebase Configuration**
- **Project ID**: `coaches-eye-ai`
- **Storage Bucket**: `coaches-eye-ai.firebasestorage.app`
- **Region**: `us-central1`

## 📝 **API Documentation**

### **Firestore Collections**
- `users/{userId}` - User profiles and settings
- `sessions/{sessionId}` - Cricket practice sessions
- `shots/{shotId}` - Individual shot analysis
- `analysis/{analysisId}` - AI analysis results

### **Storage Structure**
- `users/{userId}/videos/` - User video files
- `users/{userId}/analysis/` - Analysis results
- `public/thumbnails/` - Video thumbnails

## 🐛 **Troubleshooting**

### **Common Issues**

1. **Firebase not initialized**
   - Check `firebase_options.dart` is up to date
   - Verify `google-services.json` is in `android/app/`

2. **Permission denied errors**
   - Check Firestore security rules
   - Ensure user is authenticated

3. **Storage upload failures**
   - Enable Storage in Firebase Console
   - Check storage security rules

4. **Build errors**
   - Run `flutter clean && flutter pub get`
   - Check Flutter and Dart versions

### **Debug Commands**
```bash
# Check Firebase project status
firebase projects:list

# Check deployed rules
firebase firestore:rules:test

# View Firebase logs
firebase functions:log
```

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 **Support**

- **Documentation**: [Firebase Manual Setup Guide](FIREBASE_MANUAL_SETUP.md)
- **Issues**: Create an issue in this repository
- **Firebase Console**: [Project Dashboard](https://console.firebase.google.com/project/coaches-eye-ai)

## 🎯 **Roadmap**

- [ ] Advanced AI analysis algorithms
- [ ] Social sharing features
- [ ] Coach-player collaboration
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Offline mode support

---

**Built with ❤️ using Flutter and Firebase**