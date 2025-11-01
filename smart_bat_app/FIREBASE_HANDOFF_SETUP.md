# Firebase Setup (Handoff Guide)

This app is ready to connect to your own Firebase project. No credentials from the previous account remain. Follow these steps end‑to‑end.

## 0) Prereqs
- Install Flutter SDK and Android Studio/Xcode
- Sign in to a Google account with access to Firebase Console
- Install Firebase CLI: `npm i -g firebase-tools`
- Install FlutterFire CLI: `dart pub global activate flutterfire_cli`

## 1) Create Firebase project
1. Open Firebase Console: https://console.firebase.google.com
2. Click “Add project” → name it (e.g., SmartBat)
3. Disable Google Analytics (optional) → Create project

## 2) Add apps to the project
Do Android first; add iOS/macOS later if needed.

### Android
1. In Firebase Console → Project Overview → Add app → Android
2. Android package name: use your real app id (current placeholder: `com.example.smart_bat_app`)
3. Download `google-services.json`
4. Place it at: `smart_bat_app/android/app/google-services.json`
5. Add SHA‑1 and SHA‑256 fingerprints (for Google Sign‑In):
   - Get debug keys: `keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -storepass android -keypass android -alias androiddebugkey`
   - Add both SHA‑1 and SHA‑256 in Firebase Console → Android app settings
6. Click “Next” until done.

### iOS (optional now, required for iPhone)
1. Add app → iOS
2. iOS bundle ID: use your app bundle id
3. Download `GoogleService-Info.plist`
4. Place it at: `smart_bat_app/ios/Runner/GoogleService-Info.plist`
5. In Xcode, ensure the plist is included in the Runner target (Build Phases → Copy Bundle Resources)

### macOS (optional)
- Same as iOS, use the macOS bundle id, download and add the plist to `smart_bat_app/macos/Runner/`

## 3) Generate `firebase_options.dart`
Use FlutterFire to generate typed options for all platforms you added:

```bash
cd smart_bat_app
flutterfire configure \
  --project=<YOUR_FIREBASE_PROJECT_ID> \
  --platforms=android,ios,macos,web,windows
```
- This regenerates `lib/firebase_options.dart` with your project values.

Note: The project contains placeholder values (`REPLACE_ME`) that must be overwritten by the command above.

## 4) Enable Firebase products
Open Firebase Console → Build → enable as needed:
- Authentication: enable Email/Password, Anonymous, and Google providers
- Firestore Database: create database in Production mode
- Storage: create default bucket (auto)
- Cloud Messaging: follow instructions to enable FCM (Android automatically works once app runs on device)

## 5) Security rules (optional initial lock‑down)
You can deploy rules using Firebase CLI.

From `smart_bat_app/`:
```bash
firebase use <YOUR_FIREBASE_PROJECT_ID>
firebase deploy --only firestore:rules,storage
```
Files:
- `firestore.rules`
- `storage.rules`

## 6) Android build and run
```bash
cd smart_bat_app
flutter clean
flutter pub get
flutter build apk --release
flutter run -d <your_device_id>
```
If you changed the Android applicationId, update it in `android/app/build.gradle.kts` and re‑download `google-services.json` for that package name.

## 7) Google Sign‑In on Android
- Ensure SHA‑1 and SHA‑256 are added in Firebase app settings
- If you use a release keystore, add its SHA‑1/256 too
- In Firebase Console → Authentication → Sign‑in method → Google → enable

## 8) Push Notifications (FCM)
- For Android, FCM works once `firebase_messaging` is initialized in the app
- For iOS/macOS, enable Push in Apple Developer account and APNs in Firebase (add APNs key/cert)

## 9) Web (optional)
- If you add web, FlutterFire configure will include it. Host config goes to `web/index.html` via generated options

## 10) Troubleshooting
- If app crashes on start: check `lib/firebase_options.dart` is regenerated and not placeholder
- Android build fails: verify `android/app/google-services.json` exists and matches your package name
- iOS build fails: ensure `GoogleService-Info.plist` is present in `ios/Runner/` and added to the target
- Google Sign‑In fails: verify OAuth client IDs and SHA‑1/256 fingerprints in Firebase Console

You’re done. All Firebase connections now use your own project.
