# KnoQ Application — Phased Master Plan (Checklist)

**Project:** KnoQ Smart Cricket Bat — Mobile Application  
**Stack:** Flutter + Node.js API + PostgreSQL + Firebase Auth + BLE  
**Created:** April 2026  
**Status:** 🟡 In Progress  

> **How to use this document:**  
> - `[ ]` = Not started  
> - `[/]` = In progress  
> - `[x]` = Completed  
> - Update this file as you complete each task  
> - Each phase MUST be completed before starting the next (unless marked "parallel-safe")  
> - Sub-phases within a phase can often be done in order listed  

---

## PHASE 0: Environment & Tooling Setup

### 0.1 Development Machine Setup
- [x] Install Flutter SDK (latest stable channel)
- [x] Run `flutter doctor` — resolve all issues
- [x] Install Android Studio + Android SDK (API 26 minimum, API 34 target)
- [x] Configure Android emulator (Pixel 7 recommended, API 33+)
- [x] Install VS Code (or Android Studio) with Flutter/Dart extensions
- [x] Install Git, configure GitHub/GitLab account
- [x] Install Node.js (for Firebase CLI)
- [x] Install Firebase CLI: `npm install -g firebase-tools`
- [x] Run `firebase login` and authenticate

### 0.2 Physical Hardware Setup
- [ ] Confirm ESP32 dev board is flashed with `KnoQ_SmartBat.ino` firmware
- [ ] Confirm piezo sensors wired (S1→GPIO34, S2→GPIO35, S3→GPIO36)
- [ ] Confirm IMU wired (SDA→GPIO21, SCL→GPIO22)
- [ ] Verify serial output at 115200 baud — see hit data on Serial Monitor
- [ ] Verify BLE advertising — scan with nRF Connect app, find "KnoQ-Bat-V1"
- [ ] Test a real BLE connection — subscribe to TX characteristic, see JSON on hit
- [ ] Note the ESP32 MAC address for development/testing

### 0.3 Firebase Project Setup (Auth + Services Only)
- [ ] Create Firebase project: "knoq-dev" (development environment)
- [ ] Enable Firebase Authentication (Email/Password + Google Sign-In)
- [ ] Enable Firebase Storage (for profile images only)
- [ ] Enable Firebase Analytics
- [ ] Enable Firebase Crashlytics
- [ ] Enable Firebase Cloud Messaging (FCM)
- [ ] Enable Firebase Remote Config
- [ ] Download `google-services.json` → place in `android/app/`
- [ ] Create second Firebase project: "knoq-prod" (production — do NOT use yet)

### 0.3b Backend Setup (Node.js + PostgreSQL)
- [x] Create Node.js + Express project in a separate repo (e.g., `knoq-api/`)
- [x] Install dependencies: `express`, `firebase-admin`, `pg` (node-postgres), `cors`, `helmet`, `dotenv`
- [x] Set up project structure: `routes/`, `middleware/`, `controllers/`, `db/`, `utils/`
- [x] Create PostgreSQL database on Supabase (free tier for dev)
- [x] Run schema migrations — CREATE TABLE for all PostgreSQL tables (users, academies, devices, sessions, shots, coach_notes) with all constraints and indexes as defined in the V2 spec PostgreSQL schema section
- [x] Create all indexes (users, sessions, shots, coach_notes, academies)
- [x] Implement Firebase Admin SDK JWT verification middleware
- [x] Implement RBAC middleware (checks user role from PostgreSQL on every request)
- [x] Create health check endpoint: `GET /health` → returns 200
- [x] Deploy to Render or Railway (free tier for dev)
- [x] Set environment variables: `DATABASE_URL`, `FIREBASE_SERVICE_ACCOUNT_KEY`
- [x] Verify: API is accessible, `/health` returns 200
- [x] Create `.env.example` with all required environment variables
- [x] Optional: Set up Redis on Upstash for rate limiting (can defer to V1.5)

### 0.4 Flutter Project Initialization
- [x] Create Flutter project: `flutter create knoq_app`
- [x] Set minimum SDK to Android API 26 in `android/app/build.gradle`
- [x] Set `compileSdkVersion` to 34
- [x] Run `flutterfire configure` to generate `firebase_options.dart`
- [x] Add `.gitignore` entries for Firebase keys, build artifacts, `.env`
- [x] Create initial Git repository, make first commit
- [x] Push to remote repository (GitHub/GitLab)

### 0.5 Dependency Installation
- [x] Add to `pubspec.yaml` — Core:
  ```yaml
  firebase_core, firebase_auth, firebase_storage
  firebase_analytics, firebase_crashlytics, firebase_messaging
  firebase_remote_config, dio
  ```
- [x] Add to `pubspec.yaml` — State & Navigation:
  ```yaml
  flutter_riverpod, riverpod_annotation, go_router
  ```
- [x] Add to `pubspec.yaml` — BLE:
  ```yaml
  flutter_blue_plus, permission_handler
  ```
- [x] Add to `pubspec.yaml` — Local Storage:
  ```yaml
  hive, hive_flutter, path_provider
  ```
- [x] Add to `pubspec.yaml` — UI:
  ```yaml
  fl_chart, google_fonts, flutter_svg, shimmer, share_plus
  ```
- [x] Add to `pubspec.yaml` — Utilities:
  ```yaml
  uuid, connectivity_plus, wakelock_plus, intl, url_launcher
  ```
- [x] Add dev dependencies:
  ```yaml
  build_runner, riverpod_generator, hive_generator, mocktail
  ```
- [x] Run `flutter pub get` — resolve all dependency conflicts
- [x] Run `flutter pub outdated` — ensure no critical outdated packages

### 0.6 Project Folder Structure Creation
- [x] Create `lib/core/constants/` directory
- [x] Create `lib/core/errors/` directory
- [x] Create `lib/core/extensions/` directory
- [x] Create `lib/core/network/` directory (API client + auth interceptor)
- [x] Create `lib/core/utils/` directory
- [x] Create `lib/core/widgets/` directory
- [x] Create `lib/features/auth/data/`, `domain/`, `presentation/`, `providers/`
- [x] Create `lib/features/ble/data/`, `domain/`, `providers/`
- [x] Create `lib/features/session/data/`, `domain/`, `presentation/`, `providers/`
- [x] Create `lib/features/analytics/data/`, `domain/`, `presentation/`, `providers/`
- [x] Create `lib/features/insights/data/`, `domain/`, `presentation/`
- [x] Create `lib/features/coach/presentation/`, `providers/`
- [x] Create `lib/features/home/presentation/`, `widgets/`
- [x] Create `lib/features/profile/presentation/`
- [x] Create `lib/routing/`
- [x] Create `lib/services/`
- [x] Create `test/features/`, `test/core/`
- [x] Create `integration_test/`

### 0.7 Build Flavors Setup
- [x] Configure `android/app/build.gradle` with flavor dimensions:
  - `dev` (applicationIdSuffix `.dev`)
  - `staging` (applicationIdSuffix `.staging`)
  - `prod` (no suffix)
- [x] Create `lib/main_dev.dart` (dev entry point)
- [x] Create `lib/main_prod.dart` (prod entry point)
- [x] Create `lib/core/constants/env_config.dart` (per-flavor constants incl. API base URL)
- [x] Verify: `flutter run --flavor dev --target lib/main_dev.dart` works
- [x] Place `google-services.json` for dev flavor in `android/app/src/dev/`

### 0.8 Git & Branch Strategy
- [x] Create `main` branch (production-ready code only)
- [x] Create `develop` branch (active development)
- [x] Establish branch naming: `feature/`, `bugfix/`, `hotfix/`
- [x] Add branch protection rules (no direct push to main)
- [x] Create `.gitignore` with Flutter, Firebase, IDE entries
- [x] Make initial commit with empty project structure

---

## PHASE 1: Design System & Shared UI Components

### 1.1 Theme Configuration (Dual Theme — Light Primary)
- [x] Create `lib/core/constants/app_colors.dart` with DUAL color system:
  - **Light theme tokens:**
    - Primary: `#00C853`, Secondary: `#1565C0`
    - Background: `#FAFAFA`, Surface: `#FFFFFF`, SurfaceVariant: `#F0F0F0`
    - OnBackground/OnSurface: `#1A1A1A`, OnSurfaceVariant: `#6B6B6B`
    - Outline: `#E0E0E0`, Error: `#D32F2F`, Warning: `#F57C00`
  - **Dark theme tokens:**
    - Primary: `#66FFA6`, Secondary: `#64B5F6`
    - Background: `#0D0D0D`, Surface: `#1A1A1A`, SurfaceVariant: `#252525`
    - OnBackground/OnSurface: `#FFFFFF`, OnSurfaceVariant: `#9E9E9E`
    - Outline: `#333333`, Error: `#FF5252`, Warning: `#FFB300`
  - Zone colors (base — used in light theme): Sweet `#00C853`, Top `#2196F3`, Left `#FF9800`, Right `#9C27B0`, Bottom `#F44336`
  - Dark-elevated zone colors: Sweet `#69F0AE`, Top `#64B5F6`, Left `#FFB74D`, Right `#CE93D8`, Bottom `#EF5350`
  - **RULE:** In dark theme, use dark-elevated zone colors instead of base zone colors for all zone highlights, badges, and chart segments. In light theme, use base zone colors.
- [x] Create `lib/core/constants/app_typography.dart`:
  - Import Google Font (Inter or Outfit)
  - Define: headlineLarge (32px bold), headlineMedium (24px), titleLarge (20px semibold), bodyLarge (16px), bodyMedium (14px), labelSmall (12px)
- [x] Create `lib/core/constants/app_spacing.dart`:
  - Define spacing scale: xs(4), sm(8), md(16), lg(24), xl(32), xxl(48)
  - Define border radius: sm(8), md(12), lg(16), xl(24)
- [x] Create `lib/app.dart` with MaterialApp + BOTH light and dark ThemeData
  - Light theme is default on first launch
  - On first launch, follow device system setting automatically
  - themeMode reads from Hive `app_settings` box (light/dark/system)
- [x] **RULE: Never hardcode color hex in widgets — always use `Theme.of(context).colorScheme`**
- [x] Verify both light and dark themes render correctly on device/emulator

### 1.2 Shared Constants
- [x] Create `lib/core/constants/ble_constants.dart`:
  - Service UUID: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
  - TX UUID: `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`
  - RX UUID: `6E400002-B5A3-F393-E0A9-E50E24DCCA9E`
  - Device name: `KnoQ-Bat-V1`
  - Scan timeout: 10 seconds
  - Reconnect attempts: 3
  - Reconnect delay: 2 seconds
- [x] Create `lib/core/constants/api_endpoints.dart`:
  - API base URL per flavor (dev: localhost:3000, staging: api-staging.knoq.in, prod: api.knoq.in)
  - All endpoint paths as constants: `/users/me`, `/sessions`, `/academy/lookup`, etc.
- [x] Create `lib/core/network/api_client.dart`:
  - Dio instance with base URL from env config
  - JSON content type headers
  - Error handling interceptor
- [x] Create `lib/core/network/auth_interceptor.dart`:
  - Automatically attaches Firebase JWT to every API request
  - Refreshes token if expired before sending request

### 1.3 Shared Widgets — Foundation
- [x] Create `lib/core/widgets/knoq_button.dart`:
  - Primary button (filled green)
  - Secondary button (outlined)
  - Danger button (red)
  - Loading state (spinner replaces text)
  - Disabled state
  - Minimum 48×48dp touch target
- [x] Create `lib/core/widgets/knoq_text_field.dart`:
  - Standard text input with label, hint, error text
  - Password variant with show/hide toggle
  - Validator support
- [x] Create `lib/core/widgets/loading_overlay.dart`:
  - Full-screen semi-transparent overlay with centered spinner
  - Optional message text
- [x] Create `lib/core/widgets/shimmer_skeleton.dart`:
  - Shimmer loading placeholder (card, list item, chart variants)
- [x] Create `lib/core/widgets/empty_state.dart`:
  - Illustration + title + subtitle + optional CTA button
  - Reusable across all screens
- [x] Create `lib/core/widgets/error_state.dart`:
  - Error icon + message + "Retry" button
  - Reusable across all screens

### 1.4 Shared Widgets — Domain-Specific
- [x] Create `lib/core/widgets/zone_badge.dart`:
  - Small colored badge with zone name ("Sweet", "Top", "Left", "Right", "Bottom")
  - Uses zone color from app_colors
  - Icon + text variant
- [x] Create `lib/core/widgets/bat_zone_diagram.dart`:
  - SVG bat outline divided into 5 zones
  - Accept `activeZone` parameter → highlight that zone in zone color
  - Accept `zoneDistribution` map → show fill intensity per zone
  - Idle state: all zones neutral gray
  - Hit state: active zone illuminates, fades after 2 seconds
  - Sweet spot hit: pulse animation on center zone
- [x] Create `lib/core/widgets/power_arc.dart`:
  - Circular arc gauge (0–100)
  - Large number in center showing current value
  - Color: green (>70), orange (40–70), red (<40)
  - Animate from 0 to value in 300ms
  - Accept `label` parameter ("Power", "Avg Power", etc.)
- [x] Create `lib/core/widgets/stat_card.dart`:
  - Card with: icon, label, large value, optional trend arrow (↑↓)
  - Used on home screen, analytics, session summary

### 1.5 Utility Classes
- [x] Create `lib/core/utils/validators.dart`:
  - `validateEmail(String)` → null or error message
  - `validatePassword(String)` → null or error message (min 8, 1 upper, 1 number)
  - `validateName(String)` → null or error message (min 2 chars)
  - `validateAcademyCode(String)` → null or error message (6 chars, alphanumeric)
- [x] Create `lib/core/utils/formatters.dart`:
  - `formatPercentage(double)` → "72%"
  - `formatPower(int)` → "72%"
  - `formatSwingSpeed(double)` → "120.5 °/s"
  - `formatDuration(Duration)` → "7m 30s"
  - `formatDate(DateTime)` → "21 Apr 2026"
  - `formatTimeAgo(DateTime)` → "2 hours ago"
- [x] Create `lib/core/errors/app_exceptions.dart`:
  - `BleConnectionException`
  - `BlePermissionException`
  - `SessionSaveException`
  - `AuthException`
  - `NetworkException`
- [x] Create `lib/core/errors/error_handler.dart`:
  - Global error handler that logs to Crashlytics
  - Maps exceptions to user-friendly error messages

### 1.6 Swing Speed Widget
- [x] Create `lib/core/widgets/swing_speed_display.dart`:
  - Accepts `swing: double?` parameter
  - If swing is null or 0 → renders nothing (SizedBox.shrink)
  - If swing > 0 → shows "Swing: {value}°/s" text
  - Styled consistently with power arc (smaller text, secondary metric)

### 1.7 Design Verification
- [ ] Create a temporary "Design Gallery" screen that renders ALL shared widgets
- [ ] Verify all colors, fonts, spacings look correct in LIGHT theme
- [ ] Verify all colors, fonts, spacings look correct in DARK theme
- [ ] Verify all touch targets are minimum 48×48dp
- [ ] Verify text is readable at all sizes (14sp minimum)
- [ ] Take screenshots for reference (both themes)
- [ ] Delete gallery screen after verification (or keep in dev flavor only)

---

## PHASE 2: Authentication & User Management

### 2.1 Data Models
- [x] Create `lib/features/auth/domain/user_model.dart`:
  - Fields: id, firebaseUid, name, email, role, academyId, battingHand, age, createdAt, lastLoginAt, assignedCoachId, profileImageUrl, fcmToken, appVersion, onboardingComplete, deletionRequestedAt
  - `fromJson(Map)` factory constructor (API response)
  - `toJson()` method (API request body)
  - `copyWith()` method

### 2.2 Repositories
- [x] Create `lib/features/auth/data/auth_repository.dart`:
  - `signInWithEmail(email, password)` → Firebase User
  - `signUpWithEmail(email, password)` → Firebase User
  - `signInWithGoogle()` → Firebase User
  - `signOut()`
  - `resetPassword(email)`
  - `sendEmailVerification()`
  - `deleteAccount(password)` → confirm password, then call `DELETE /users/me` on API
  - `getCurrentUser()` → Firebase User?
  - `authStateChanges()` → Stream<User?>
- [x] Create `lib/features/auth/data/user_repository.dart` (calls Node.js API):
  - `registerUser(data)` → `POST /auth/register` → creates user in PostgreSQL
  - `getCurrentUserProfile()` → `GET /users/me` → UserModel from API
  - `updateProfile(fields)` → `PATCH /users/me`
  - `deleteUserData()` → `DELETE /users/me` → API deletes all data from PostgreSQL

### 2.3 Providers (Riverpod)
- [x] Create `lib/features/auth/providers/auth_provider.dart`:
  - `authRepositoryProvider` → singleton AuthRepository
  - `userRepositoryProvider` → singleton UserRepository
  - `authStateProvider` → StreamProvider<User?> from Firebase auth state
  - `currentUserProvider` → FutureProvider<UserModel?> fetches from `GET /users/me` API
  - `authNotifierProvider` → StateNotifier for login/register/logout actions

### 2.4 Login Screen
- [x] Create `lib/features/auth/presentation/login_screen.dart`:
  - Email text field with validation
  - Password text field with show/hide toggle
  - "Log In" primary button (with loading state)
  - "Continue with Google" button
  - "Forgot password?" link
  - "Don't have an account? Register" link
  - Error display (inline under field or toast)
  - Handle: wrong password, user not found, network error, email not verified
- [x] Test login with email/password → routes to correct home based on role
- [x] Test login with Google → creates user doc if first time
- [x] Test error states: wrong password, no internet, unverified email

### 2.5 Registration Screen
- [x] Create `lib/features/auth/presentation/register_screen.dart`:
  - Name text field (required)
  - Email text field with validation
  - Password text field with strength indicator
  - Confirm password field
  - "Register" primary button (with loading state)
  - "Continue with Google" button
  - "Already have an account? Log in" link
  - On success: send email verification → show "Check your email" screen
- [x] Handle: email already in use, weak password, network error
- [x] Verify email verification email is sent

### 2.6 Forgot Password Screen
- [x] Create `lib/features/auth/presentation/forgot_password_screen.dart`:
  - Email text field
  - "Send Reset Link" button
  - Success: show "Check your email for reset instructions"
  - Error: user not found, network error

### 2.7 Email Verification Check
- [x] Create email verification check in auth flow:
  - After login, check `user.emailVerified`
  - If not verified → show "Verify your email" screen with "Resend" button
  - Block access to session features until verified
  - On "Resend" → call `sendEmailVerification()`
  - Periodic check (every 3 seconds) or manual "I've verified" button

### 2.8 Onboarding Flow
- [x] Create `lib/features/auth/presentation/onboarding_screen.dart`:
  - Page 1: Welcome — KnoQ logo animation + 3 value prop bullets + "Get Started"
  - Page 2: About You — Name (required), Age (number picker 8–60, required), Batting hand (Left/Right toggle, required), Profile photo (optional camera/gallery)
  - Page 3: Join Academy — Academy code text field (optional), "I don't have a code" skip link, On valid code show academy name for confirmation
  - Progress dots at bottom
  - "Next" button per page, "Skip" only on page 3
  - On completion: call `PATCH /users/me` with name, age, battingHand, onboardingComplete=true (POST /auth/register was already called during registration — onboarding only updates the existing user profile)
- [x] Implement academy code validation:
  - Call `GET /academy/lookup?code=ENTERED_CODE` on Node.js API
  - If found (200): show academy name, confirm join → call `POST /academy/join`
  - If not found (404): show error "Invalid code"
- [x] Handle profile photo upload to Firebase Storage
- [x] Test: complete onboarding → ends up on Player Home
- [x] Test: skip academy code → standalone player mode

### 2.9 Auth State & Routing Integration
- [x] Wire auth state to GoRouter redirect (see Phase 8)
- [x] Implement: not logged in → force `/login`
- [x] Implement: logged in + no onboarding → force `/onboarding`
- [x] Implement: logged in + onboarding done → route to role-specific home
- [x] Implement: super admin on mobile → block with message
- [x] Implement: logout → clear local state, navigate to `/login`

### 2.10 Account Deletion
- [x] Add "Delete Account" option in Settings (implement in Phase 9)
- [x] Flow: confirm with password → call `DELETE /users/me` → API deletes all PostgreSQL data + Firebase Auth → clear Hive → navigate to login
- [x] Set 30-day grace period (store `deletionRequestedAt`, actual deletion via scheduled job on backend)

---

## PHASE 3: BLE Service Layer

### 3.1 Permission Handling
- [x] Create `lib/features/session/presentation/permission_check_screen.dart`:
  - Check platform version (Android API level)
  - For Android < 12: request `ACCESS_FINE_LOCATION`
  - For Android 12+: request `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`
  - Check Location services enabled (Android < 12)
  - Check Bluetooth adapter ON
  - Show explanation dialog before each permission request
  - Handle "denied" → show explanation + retry
  - Handle "permanently denied" → show "Go to Settings" button with `openAppSettings()`
  - Handle Bluetooth OFF → show "Turn on Bluetooth" prompt
  - Handle Location OFF → show "Enable Location" prompt
  - All permissions granted → auto-navigate to BLE Scan screen
- [x] Add to `AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.BLUETOOTH_SCAN"
      android:usesPermissionFlags="neverForLocation" />
  <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
  ```
- [x] Test on Android 11 (API 30) — location permission flow
- [x] Test on Android 13 (API 33) — Bluetooth permission flow
- [x] Test: Bluetooth OFF → prompt → user enables → auto-proceed

### 3.2 BLE State Machine
- [x] Create `lib/features/ble/domain/ble_state.dart`:
  - Enum: `disconnected`, `scanning`, `connecting`, `connected`, `reconnecting`, `error`
  - Include error message field for error state
  - Include device info for connected state
- [x] Create `lib/features/ble/data/ble_repository.dart`:
  - `startScan(timeout: 10s)` → Stream<ScanResult> filtered by device name "KnoQ-Bat-V1"
  - `stopScan()`
  - `connect(device)` → negotiate MTU (request 512, fallback 23)
  - `disconnect()`
  - `discoverServices()` → find Nordic UART service and TX/RX characteristics
  - `subscribeToTx()` → Stream<List<int>> raw BLE notifications
  - `sendCommand(String json)` → write to RX characteristic
  - `getConnectionState()` → Stream<BluetoothConnectionState>
  - Store connected device MAC address for reconnection
- [x] Create `lib/features/ble/providers/ble_provider.dart`:
  - `BleNotifier` (StateNotifier<BleState>):
    - `scan()` → update state through scanning → found → connecting → connected
    - `connect(device)` → connect + discover + subscribe
    - `disconnect()` → clean up subscriptions
    - `reconnect()` → attempt reconnect to last known device (3 retries, 2s apart)
    - `sendCalibrate()` → send `{"cmd": "calibrate"}`
    - `sendResetSession()` → send `{"cmd": "reset_session"}`
  - `shotStreamProvider` → StreamProvider<ShotData> from parsed BLE data

### 3.3 Shot Data Parsing
- [x] Create `lib/features/ble/domain/shot_data.dart`:
  - Fields: hit (int), zone (String), power (int), **swing (double? — NULLABLE)**, sweetPct (int), avgPower (int), totalHits (int)
  - `fromJson(Map)` factory — swing parsed as nullable, treat 0 as null
  - Validation: power 0–100, zone in valid set, hit > 0
  - **Note:** `swing` comes from MPU-9250 gyroscope. May be 0, null, or absent if IMU is not connected/wired
- [x] Create `lib/features/ble/data/shot_parser.dart`:
  - Maintain string buffer for JSON assembly (handles MTU fragmentation)
  - Append incoming BLE bytes to buffer
  - Split on newline `\n` delimiter
  - For each complete line: try JSON parse
  - If valid shot JSON → emit ShotData
  - If valid summary JSON → emit SessionSummary
  - If malformed → log error to Crashlytics, skip, do NOT crash
  - Handle: missing fields (use defaults), extra fields (ignore), wrong types (skip)
- [x] Write unit tests for shot_parser:
  - [x] Test: valid shot JSON → correct ShotData
  - [x] Test: valid summary JSON → correct SessionSummary
  - [x] Test: malformed JSON → skipped, no crash
  - [x] Test: missing fields → skipped or defaults
  - [x] Test: fragmented JSON (split across 2 packets) → assembled correctly
  - [x] Test: empty string → ignored
  - [x] Test: multiple JSON objects in one packet → all parsed
  - [x] Test: swing = 0 → parsed as null
  - [x] Test: swing field missing → parsed as null
  - [x] Test: swing = 120.5 → parsed as 120.5
  - [x] Test: swing = negative value (e.g. -45.2) → parsed as null (gyro can output negative °/s depending on orientation — meaningless for KnoQ)

### 3.4 Mock BLE Service
- [x] Create `lib/features/ble/data/mock_ble_service.dart`:
  - Simulates scan: returns fake "KnoQ-Bat-V1" device after 2 seconds
  - Simulates connect: transitions to connected after 1 second
  - Simulates shot stream: emits random valid ShotData every 3–5 seconds
  - Configurable: `nullSwingMode` — emits shots with swing=null to test graceful degradation
  - Simulates disconnect: randomly disconnects after N shots (configurable)
  - Simulates reconnect: succeeds after 1 retry
  - Toggle: enable/disable in dev flavor via environment config
- [x] Verify: full session flow works with mock BLE (no real hardware needed)

### 3.5 BLE Scan Screen
- [x] Create `lib/features/session/presentation/ble_scan_screen.dart`:
  - Animated radar/ripple scanning animation
  - List of discovered devices (filtered to "KnoQ-Bat-V1")
  - Tap device to connect
  - Connection progress indicator
  - States:
    - Scanning: radar animation + "Searching for KnoQ bat..."
    - Device found: show device card with signal strength + "Connect" button
    - Connecting: spinner + "Connecting to KnoQ-Bat-V1..."
    - Connected: success animation → auto-navigate to Live Session
    - Not found: "No devices found. Is your bat powered on?" + "Retry" button
    - Error: error message + "Retry" button
  - Auto-reconnect to last known device if user has connected before
  - Back button: stop scan, go back to home
- [ ] Test: scan finds device → connect → navigate to live session
- [ ] Test: no device found → empty state rendered
- [ ] Test: connection fails → error state with retry

---

## PHASE 4: Live Session — Core Feature

### 4.1 Session Data Model
- [x] Create `lib/features/session/domain/session_model.dart`:
  - Fields matching PostgreSQL schema: sessionId, playerId, academyId, deviceId, startTime, endTime, status, totalHits, sweetSpotHits, sweetSpotPct, avgPower, peakPower, **avgSwing (double? nullable)**, **peakSwing (double? nullable)**, zoneDistribution, consistencyScore, **coachNote (String? nullable)**, appVersion, firmwareVersion, syncStatus, insights
  - `fromJson()`, `toJson()`, `copyWith()`
- [x] Create `lib/features/session/domain/session_stats.dart`:
  - Computed live from accumulated shots:
    - `totalHits` → shot count
    - `sweetSpotPct` → sweet zone shots / total × 100
    - `avgPower` → sum of power / total
    - `peakPower` → max power seen
    - `avgSwing` → avg of non-null swing values (null if no swing data)
    - `peakSwing` → max of non-null swing values (null if no swing data)
    - `hasSwingData` → true if ≥50% of shots have valid swing
    - `zoneDistribution` → map of zone → count
    - `consistencyScore` → entropy + stddev formula
  - `addShot(ShotData)` method → recalculates all stats (handles null swing gracefully)
  - Write unit tests for session_stats (including null swing scenarios)

### 4.2 Hive Write-Ahead Log (Crash Recovery)
- [x] Create `lib/features/session/data/local_session_store.dart`:
  - Initialize Hive box: `active_session`
  - `startSession(meta)` → write session meta + set `is_active = true`
  - `addShot(shotData)` → append shot to Hive list (< 1ms write)
  - `endSession()` → set `is_active = false`
  - `hasActiveSession()` → check `is_active` flag
  - `recoverSession()` → return meta + all shots from Hive
  - `clearSession()` → delete all data from active_session box
- [x] On app launch: check `hasActiveSession()` → show recovery dialog if true
- [x] Test: simulate crash (kill app during mock BLE session) → reopen → recovery dialog → restore shots

### 4.3 Live Session Provider
- [x] Create `lib/features/session/providers/session_provider.dart`:
  - `LiveSessionNotifier` (StateNotifier<LiveSessionState>):
    - State: sessionMeta, shots list, liveStats (SessionStats), isActive, lastShotZone
    - `startSession(deviceId)` → initialize, write meta to Hive
    - `onShotReceived(ShotData)` → add to shots list, update stats, write to Hive
    - `endSession()` → mark Hive inactive, compute final stats
    - `getSessionModel()` → build complete SessionModel from accumulated data
  - Listens to `shotStreamProvider` from BLE
  - Auto-increments shot count, validates sequence numbers

### 4.4 Live Session Screen
- [x] Create `lib/features/session/presentation/live_session_screen.dart`:
  - **Top section:** BLE status indicator (green dot = connected, red = disconnected)
  - **Bat zone diagram:** shows last hit zone, fades after 2s
  - **Power arc:** large, centered, updates per shot with animation
  - **Swing speed display:** shown ONLY if swing data is non-null/non-zero (use SwingSpeedDisplay widget)
  - **Last shot card:** zone badge + power + swing speed (if available), slides in from bottom on hit
  - **Running stats bar:** total hits | sweet% | avg power (always visible)
  - **Shot history mini-list:** last 5 shots, scrolling, most recent on top
  - **End Session button:** prominent, bottom of screen
  - **Reconnecting banner:** shown when BLE disconnects during session
- [x] Implement haptic feedback on shot received (`HapticFeedback.mediumImpact()`)
- [x] Implement sweet spot hit effect: green flash overlay (0.3s)
- [x] Implement WakelockPlus: enable on session start, disable on session end
- [x] Implement PopScope: back button → show "End session?" confirmation dialog
- [x] Implement BLE disconnect handling:
  - Show yellow "Reconnecting..." banner
  - Continue accepting shots if BLE reconnects
  - Show "Connection lost. Tap to retry" if all retries fail
  - Session stays alive regardless of BLE state
- [x] Test: receive 10 shots from bat → verify all UI elements update correctly
- [x] Test: disconnect during session → banner appears → reconnect → banner disappears
- [x] Test: press back → confirmation dialog → cancel → stays on session
- [x] Test: end session → navigates to session summary

### 4.5 Session End & Summary
- [x] Create `lib/features/session/presentation/session_summary_screen.dart`:
  - Header: "Session Complete" with date/time and duration
  - Stats row: total hits, sweet spot %, avg power, peak power
  - Avg swing speed (shown ONLY if swing data was available during session)
  - Zone distribution pie/donut chart (using fl_chart)
  - Power over time line chart (x = shot #, y = power)
  - Top 1–2 coaching insights cards (computed from insight engine — Phase 6)
  - "Save Session" button → `POST /sessions` + `POST /sessions/:id/shots` API call
  - "Share" button → screenshot of summary → share_plus
  - Handle save failure: "Save failed. Saved locally. Will sync when online."
- [x] Handle 0 hits: do not save, show "No shots recorded" with "Go Home" button
- [x] Implement session save to backend API:
  - `POST /sessions` with session data → get session ID back
  - `POST /sessions/:id/shots` with batch of all shots
  - On success: clear Hive active_session → navigate to home
  - On failure: mark as "pending" in `pending_sync` Hive box → navigate to home
- [x] Test: complete session → summary renders charts → save succeeds
- [x] Test: save with no internet → saves locally → shows offline badge

---

## PHASE 5: Session Repository & History

### 5.1 Session Repository
- [x] Create `lib/features/session/data/session_repository.dart` (calls Node.js API):
  - `saveSession(SessionModel, List<ShotData>)` → `POST /sessions` + `POST /sessions/:id/shots`
  - `getSessions({limit, page})` → `GET /sessions?limit=20&page=1` → paginated, ordered by startTime DESC
  - `getSession(sessionId)` → `GET /sessions/:id` → single session with shots
  - `getRecentSessions(limit: 5)` → `GET /sessions?limit=5` → for home screen
  - `deleteSession(sessionId)` → `DELETE /sessions/:id`

### 5.2 Session History Screen
- [x] Create `lib/features/session/presentation/shot_history_screen.dart`:
  - Full list of shots in a session
  - Each row: shot # → zone badge → power bar → swing speed
  - Filter buttons: All | Sweet only | Weak (<40%) | Strong (>75%)
  - Tap shot → expand with raw values (S1, S2, S3) — debug info

### 5.3 Session List Screen
- [x] Create `lib/features/session/presentation/session_list_screen.dart`:
  - Paginated list (20 per page, "Load more" button or infinite scroll)
  - Each card: date, duration, total hits, sweet%, avg power, zone mini-chart
  - Tap session → navigate to session detail (summary view)
  - Pull to refresh
  - Loading state: shimmer skeleton
  - Empty state: "No sessions yet. Start practicing!"
  - Error state: "Could not load sessions. Pull to refresh."
- [x] Cache last 5 sessions in Hive for offline viewing

---

## PHASE 6: Coaching Insights Engine

### 6.1 Insight Model
- [x] Create `lib/features/insights/domain/insight_model.dart`:
  - Fields: type (String), title (String), detail (String), action (String), severity (info/warning/positive)
  - Factory constructors for each insight type

### 6.2 Consistency Score Calculation
- [x] Implement `consistencyScore` in `lib/features/session/domain/session_stats.dart`:
  - Formula: `consistencyScore = 100 - (zoneEntropyScore + powerStdDevNormalized)`
  - `zoneEntropyScore`: 0 = all hits in same zone, 50 = evenly spread across all zones
  - `powerStdDevNormalized`: stdDev of power values normalized to 0–50 range
  - Output range: 0–100. Above 70 = consistent. Below 40 = inconsistent.
  - Unit test: verify score = 100 when all shots same zone + same power, score < 40 when fully random distribution

### 6.3 Insight Engine Implementation
- [x] Create `lib/features/insights/data/insight_engine.dart`:
  - Input: SessionModel (with stats and zone distribution)
  - Output: List<InsightModel> (max 3, sorted by priority)
  - Implement rules:
    - [x] Zone bias — left > 40%
    - [x] Zone bias — right > 40%
    - [x] Zone bias — bottom > 25%
    - [x] Zone bias — top > 30%
    - [x] Sweet spot — > 70% (positive)
    - [x] Sweet spot — 50-70% (encouraging)
    - [x] Sweet spot — 30-50% (improvement needed)
    - [x] Sweet spot — < 30% (priority fix)
    - [x] Power — avg > 80% (redirect to accuracy)
    - [x] Power — avg < 40% (follow-through)
    - [x] Power — stdDev > 25 (inconsistency)
    - [x] Swing — stdDev > 40°/s (inconsistent swing tempo) — **ONLY if hasValidSwingData**
    - [x] Swing — high swing + low sweet% (speed vs accuracy) — **ONLY if hasValidSwingData**
    - [x] Fatigue — totalHits > 50 AND last-quarter power < first-quarter × 0.8
  - `hasValidSwingData` check: ≥50% of shots must have non-null swing > 0
  - **CRITICAL:** Skip ALL swing-based insights silently if swing data is absent. Do NOT show "0°/s"
  - Priority ranking: fatigue > low sweet% > zone bias > power inconsistency > swing > positive
- [x] Write comprehensive unit tests:
  - [x] Test: all sweet (>70%) → positive insight
  - [x] Test: heavy left bias → left zone insight
  - [x] Test: 3 issues → only top 3 returned
  - [x] Test: < 5 shots → empty list (no insights)
  - [x] Test: fatigue detected → fatigue insight is #1 priority
  - [x] Test: edge case — exactly 40% left → no trigger (must be >40%)
  - [x] Test: empty session → empty list
  - [x] Test: all shots have swing=null → NO swing insights generated
  - [x] Test: 60% shots have swing data + high stdDev → swing inconsistency insight
  - [x] Test: 30% shots have swing data → hasValidSwingData=false → no swing insights

### 6.4 Trend Insights (Cross-Session)
- [x] Implement cross-session trend analysis (needs ≥3 sessions):
  - [x] Sweet% improving over last 3 → "Great progress!" insight
  - [x] Avg power declining over last 3 → "Check for fatigue" insight
  - [x] Consistency improving over last 3 → "Becoming more consistent" insight
- [x] Store computed insights in session record in PostgreSQL (via API) for coach viewing

### 6.5 Coaching Insights Screen
- [x] Create `lib/features/insights/presentation/coaching_insights_screen.dart`:
  - Show insights for the selected session (or latest session)
  - Each insight: card with icon + title + detail + suggested action
  - Color-coded: green (positive), orange (improvement), red (priority)
  - "View all sessions" link → session history
  - Empty state: "Need 5+ shots for insights"

---

## PHASE 7: Analytics Dashboard

### 7.1 Analytics Repository
- [x] Create `lib/features/analytics/data/analytics_repository.dart` (calls Node.js API):
  - `getAnalytics(timeRange)` → `GET /analytics?range=7d` → AnalyticsModel
  - `getPlayerAnalytics(playerId, timeRange)` → `GET /analytics/player/:id?range=7d` (coach/admin only)
  - Time ranges: "session" (latest), "7d", "30d", "all"
  - API aggregates across multiple sessions and returns:
    - Total sessions, total hits, overall sweet%, overall avg power
    - Overall avg swing speed (null if no swing data across sessions)
    - Zone distribution (aggregate across all sessions in range)
    - Power trend (avg power per session over time)
    - Swing speed trend (avg swing per session over time, null entries for sessions without swing)
    - Sweet% trend (per session over time)
    - Consistency trend
    - Best session, worst session
    - Strongest zone, weakest zone

### 7.2 Analytics Model
- [x] Create `lib/features/analytics/domain/analytics_model.dart`:
  - Fields: totalSessions, totalHits, overallSweetPct, overallAvgPower, overallPeakPower, **overallAvgSwing (double? nullable)**, zoneTotals, powerTrend, **swingTrend (list of nullable per-session values)**, sweetTrend, consistencyTrend, strongestZone, weakestZone

### 7.3 Analytics Dashboard Screen
- [x] Create `lib/features/analytics/presentation/analytics_dashboard_screen.dart`:
  - **Time range selector:** segmented button (This Session / 7 Days / 30 Days / All Time)
  - **Summary stats row:** total sessions, total hits, avg power, sweet%
  - **Zone distribution donut chart** (fl_chart PieChart):
    - 5 slices with zone colors
    - Center text: total hits
    - Tappable segments → show percentage + count in tooltip
  - **Power trend line chart** (fl_chart LineChart):
    - X-axis: session date or session #
    - Y-axis: avg power 0–100
    - Horizontal reference line at overall average
    - Sweet spot hits highlighted as green dots (for single session view)
  - **Swing speed trend line chart** (ONLY shown if swing data exists across sessions):
    - Line chart showing avg swing °/s per session
    - Sessions with no swing data → skip that point (gap in line)
    - If zero sessions have swing data → hide this chart entirely
  - **Sweet spot % trend line:**
    - Line chart showing sweet% per session
    - Green zone (>70%), orange (40–70%), red (<40%)
  - **Consistency score gauge:**
    - Circular gauge 0–100
    - Color-coded same as power arc (Using CircularProgressIndicator style)
  - **Strongest/Weakest zone badges:**
    - Two cards: "Strongest: Sweet (72 hits)" and "Weakest: Bottom (5 hits)"
  - Loading state: chart skeletons with shimmer
  - Empty state: "Play 3+ sessions to see trends"
  - Error state: "Could not load analytics. Pull to refresh."
- [x] Cache analytics computation in Hive (invalidate when new session saved) by integrating custom offline fallback computation engine.
- [x] Test: with 1 session → shows session-level data
- [x] Test: with 5 sessions → shows trends across sessions
- [x] Test: change time range → charts update
- [x] Test: empty (0 sessions) → empty state

---

## PHASE 8: Player Home & Navigation

### 8.1 GoRouter Setup
- [x] Create `lib/routing/app_router.dart`:
  - Define all routes (see Plan V2 Section 25)
  - Public routes: `/login`, `/register`, `/forgot-password`
  - Protected routes: `/home`, `/session/*`, `/analytics`, `/insights`, `/profile`, `/settings`
  - Coach routes: `/coach`, `/coach/player/:id`, `/coach/compare`
  - Implement redirect logic:
    - Not logged in → `/login`
    - No onboarding → `/onboarding`
    - Coach accessing player routes → allowed
    - Player accessing coach routes → `/unauthorized`
    - Logged in on login page → redirect to role home
- [x] Create `lib/routing/route_guards.dart`:
  - Role checking helper functions
  - Onboarding completion check
- [x] Wire GoRouter to `app.dart` MaterialApp.router (Already done previously)

### 8.2 Player Home Screen
- [x] Create `lib/features/home/presentation/player_home_screen.dart`:
  - **Welcome header:** "Hey, {name}!" + profile avatar
  - **Quick stats cards:** lifetime avg power, total hits
  - **Start Session button:** large, prominent, primary green
    - On tap → navigate to permission check → BLE scan → live session
  - **Device status pill:** "KnoQ-Bat-V1 — Connected" (green) or "Not connected" (gray)
  - **Pending sync badge:** "1 session pending sync" (if any in Hive queue)
  - **Recent sessions list:** last 3 sessions as small cards
    - Each: date, hits, sweet%, power → tap to view detail
  - **Bottom navigation bar:** Home | Analytics | Insights | Profile (Migrated to MainScaffold)
  - Loading state: shimmer skeleton for stats + session list
  - Empty state: "Welcome! Start your first session"
  - Error state: "Could not load data. Pull to refresh."
- [x] Auto-attempt BLE reconnect if previously connected device is in range

### 8.3 Bottom Navigation
- [x] Implement bottom navigation bar with 4 tabs:
  - **Home** (house icon) → Player Home
  - **Analytics** (chart icon) → Analytics Dashboard
  - **Insights** (lightbulb icon) → Coaching Insights (dynamically fetching latest session)
  - **Profile** (person icon) → Profile Screen
- [ ] Coach version: different bottom nav:
  - **Dashboard** → Coach Dashboard
  - **Compare** → Compare Players
  - **Profile** → Coach Profile
- [x] Persist navigation state across tab switches (use ShellRoute)

### 8.4 Session Recovery on Launch
- [x] On app launch (in `main.dart` or home screen `initState`):
  - Check Hive `active_session.is_active`
  - If true → show dialog: "You have an unsaved session with X shots. Recover?"
  - "Recover" → load shots from Hive → navigate to Session Summary **in recovery mode**
    - Recovery mode: the session has NO sessionId yet (never saved to API)
    - Save button must first call `POST /sessions` to create the session and get a sessionId back
    - Then call `POST /sessions/:id/shots` with all recovered shots using the returned sessionId
    - Only after both succeed → clear Hive active_session box
  - "Discard" → clear Hive active_session box
  - If false → normal launch

---

## PHASE 9: Profile & Settings

### 9.1 Profile Screen
- [X] Create `lib/features/profile/presentation/profile_screen.dart`:
  - Profile photo (tappable → camera/gallery to change)
  - Name, email (read-only), age, batting hand
  - Academy name (if joined) or "No academy — Join one"
  - **Lifetime stats section:**
    - Total sessions played
    - Total hits
    - Best sweet spot % (session record)
    - Best power (single shot record)
    - Member since date
  - "Edit Profile" button → inline editing mode
  - On save → call `PATCH /users/me` on API + update local Hive cache

### 9.2 Settings Screen
- [X] Create `lib/features/profile/presentation/settings_screen.dart`:
  - **Device Management:**
    - Last connected device (name + MAC)
    - "Forget Device" button
    - "Calibrate Bat" button → sends `{"cmd": "calibrate"}` via BLE
  - **Academy:**
    - Current academy name (or "Join Academy" → enter code flow)
    - Leave academy option (requires confirmation)
  - **Notifications:**
    - Toggle: Session reminders
    - Toggle: Coach feedback alerts
    - Toggle: Weekly summary
  - **Appearance:**
    - Theme: Light / Dark / System default (stored in Hive, persists across sessions)
  - **Data & Privacy:**
    - "Export My Data" → future
    - "Delete Account" → confirmation flow → deletes everything
    - Privacy policy link
    - Terms of service link
  - **About:**
    - App version
    - Firmware version (last connected)
    - "Rate the app" → Play Store link
    - "Contact support" → email

---

## PHASE 10: Coach Features

### 10.1 Coach Provider
- [x] Create `lib/features/coach/providers/coach_provider.dart`:
  - `assignedPlayersProvider` → list of players assigned to the logged-in coach
  - `playerDetailProvider(playerId)` → full player data + recent sessions
  - `playerSessionsProvider(playerId)` → paginated session history
  - `addCoachNoteProvider` → add note to a session

### 10.2 Coach Dashboard
- [x] Create `lib/features/coach/presentation/coach_dashboard_screen.dart`:
  - List of all assigned players
  - Each player card: photo, name, last active date, sweet%, avg power, trend arrow
  - Sort options: name (A–Z), last active, sweet% (high→low), avg power
  - Search bar (filter by name)
  - Tap player → Player Detail screen
  - Loading: shimmer cards
  - Empty: "No players assigned. Contact your academy admin."
  - Error: "Could not load players. Pull to refresh."

### 10.3 Player Detail (Coach View)
- [x] Create `lib/features/coach/presentation/player_detail_screen.dart`:
  - Player info header: photo, name, age, batting hand, academy
  - Analytics summary: sweet%, avg power, consistency, total sessions
  - Trend charts (sweet%, power over time)
  - Session history list (paginated)
  - Tap session → coach session detail view
  - "Add Note" FAB → note input dialog
  - "Compare" button → navigate to compare screen
  - "Export PDF" button → generate PDF report (Phase 12)

### 10.4 Session Detail (Coach View)
- [x] Create `lib/features/coach/presentation/session_detail_coach_screen.dart`:
  - Same as player session summary but with coach additions:
  - Coach note section: text area + tag selector (footwork, timing, power, stance, grip)
  - "Save Note" button → `POST /coach-notes` on API
  - View auto-generated insights for this session
  - Previous coach notes for this player (recent 5)

### 10.5 Compare Players
- [x] Create `lib/features/coach/presentation/compare_players_screen.dart`:
  - Select 2 players from dropdown/search
  - Side-by-side comparison:
    - Sweet%, avg power, consistency, total sessions
    - Zone distribution (two pie charts side by side)
    - Power trend overlay (two lines on one chart)
  - Highlight which player is stronger in each metric

---

## PHASE 11: Offline Sync System

### 11.1 Sync Service
- [x] Create `lib/services/sync_service.dart`:
  - On app launch: check Hive `pending_sync` box for queued items
  - On connectivity change (connectivity_plus): trigger sync if online
  - On session end (save failure): add to pending queue
  - Process queue: one session at a time, in order
  - On sync success: remove from queue, update session `syncStatus` to "synced"
  - On sync failure: increment retry count, exponential backoff (2s, 4s, 8s, 16s, 32s)
  - After 5 failures: mark as "failed", notify user
  - Background sync: run when app is in foreground + online

### 11.2 Sync UI
- [x] Show sync badge on Player Home: "1 session pending sync" (orange badge)
- [x] Show sync indicator: syncing spinner in app bar during active sync
- [x] Show "All synced" confirmation when queue is empty
- [x] In session history: show sync status icon per session (✅ synced, 🕐 pending, ❌ failed)
- [x] "Failed" sessions: tap to retry manual sync

### 11.3 Offline Caching
- [x] Cache user profile in Hive on login (update on each fetch)
- [x] Cache last 5 sessions in Hive on fetch (update when new data)
- [x] Cache last computed analytics in Hive
- [x] On offline launch: load all UI from Hive cache
- [x] Show "Offline" indicator in app bar
- [x] Show "Last updated: X minutes ago" on cached data

---

## PHASE 12: Notifications & Extras

### 12.1 FCM Push Notifications
- [x] Initialize FCM in `lib/services/notification_service.dart`
- [x] Save FCM token to user document on login + token refresh
- [x] Handle foreground notifications (show in-app banner)
- [x] Handle background notifications (system notification)
- [x] Handle notification tap → navigate to relevant screen
- [x] Notification types:
  - [x] "Session saved" → navigate to session detail
  - [x] "Coach left feedback" → navigate to session with note
  - [x] "Weekly summary" → navigate to analytics
  - [x] "Practice reminder" → navigate to home (start session)

### 12.2 PDF Export (Coach)
- [x] Implement PDF generation using `pdf` package:
  - Player name, academy, date range
  - Summary stats table
  - Zone distribution chart (render as PDF drawing)
  - Power trend chart (render as series of dots/lines)
  - Session history table
  - Coach notes
  - KnoQ branding footer
- [x] "Export PDF" button on coach player detail → generate → share
- [x] Test: PDF generates correctly with 10+ sessions of data

### 12.3 Share Session Summary
- [x] "Share" button on session summary screen
- [x] Capture summary screen as image (screenshot)
- [x] Share via share_plus (WhatsApp, Instagram story, etc.)
- [x] Image includes: KnoQ branding + session stats + zone chart

### 12.4 Firebase Analytics Integration
- [x] Create `lib/services/analytics_service.dart`
- [x] Implement all events from Plan V2 Section 27:
  - [x] Auth events: sign_up, login, onboarding_complete, logout
  - [x] Session events: session_started, shot_received, session_ended, session_saved
  - [x] BLE events: ble_scan_started, ble_connected, ble_disconnected
  - [x] Feature events: analytics_viewed, insight_viewed, profile_edited
  - [x] Coach events: player_viewed, note_added, players_compared, report_exported
- [x] Verify events appear in Firebase Analytics dashboard

### 12.5 Crashlytics Integration
- [x] Create `lib/services/crash_reporting_service.dart`
- [x] Set up global error handler: `FlutterError.onError`, `PlatformDispatcher.instance.onError`
- [x] Log non-fatal exceptions (malformed BLE JSON, API call failures)
- [x] Set user identifier on login for crash attribution
- [ ] Verify crash reports appear in Firebase Crashlytics console

---

## PHASE 13: Testing & Quality Assurance

### 13.1 Unit Tests
- [ ] `test/features/insights/insight_engine_test.dart` — all rules + edge cases
- [ ] `test/features/ble/shot_parser_test.dart` — valid, malformed, fragmented JSON
- [ ] `test/features/session/session_stats_test.dart` — averages, percentages, empty
- [ ] `test/features/auth/validators_test.dart` — email, password, academy code
- [ ] `test/features/analytics/analytics_model_test.dart` — aggregation logic
- [ ] Run: `flutter test` → all pass
- [ ] Coverage: `flutter test --coverage` → >80% on business logic files

### 13.2 Widget Tests
- [ ] `test/core/widgets/bat_zone_diagram_test.dart` — renders correct zone
- [ ] `test/core/widgets/power_arc_test.dart` — correct color at boundaries
- [ ] `test/core/widgets/zone_badge_test.dart` — correct color per zone
- [ ] `test/core/widgets/stat_card_test.dart` — displays correct values
- [ ] `test/core/widgets/empty_state_test.dart` — renders CTA
- [ ] Golden tests for key components: bat diagram, power arc

### 13.3 Integration Tests
- [ ] `integration_test/auth_flow_test.dart`:
  - Register → verify email → onboard → arrive at home
- [ ] `integration_test/session_flow_test.dart`:
  - Home → scan (mock BLE) → connect → receive 10 shots → end → summary → save
- [ ] `integration_test/coach_flow_test.dart`:
  - Coach login → dashboard → select player → view session → add note
- [ ] `integration_test/offline_flow_test.dart`:
  - Session with no internet → saves locally → sync when online

### 13.4 Manual QA Testing
- [ ] Test on physical Android device (not just emulator)
- [ ] Test with real ESP32 bat → receive actual shot data
- [ ] Test BLE range — walk 10m away → verify connection holds
- [ ] Test BLE disconnect recovery — power off bat → power on → auto-reconnect
- [ ] Test session with 50+ shots → verify no performance degradation
- [ ] Test session with 100+ shots → verify charts render quickly
- [ ] Test screen rotation → verify layout adapts (or lock to portrait)
- [ ] Test on slow network (throttle to 3G) → verify offline fallback works
- [ ] Test on airplane mode → BLE works, API saves locally to Hive
- [ ] Test kill app during session → reopen → recovery dialog appears
- [ ] Test OEM devices (if available):
  - [ ] Samsung (One UI)
  - [ ] Xiaomi (MIUI)
  - [ ] OnePlus (OxygenOS)
  - [ ] Oppo/Vivo (ColorOS/FunTouch)

### 13.5 Performance Testing
- [ ] App cold start: measure time → must be < 3 seconds
- [ ] BLE data → UI update: measure latency → must be < 100ms
- [ ] Session save (50 shots): measure time → must be < 2 seconds
- [ ] Analytics chart render (5 sessions, 200 total shots): → must be < 500ms
- [ ] Memory usage during 100-shot session: → must not grow unbounded
- [ ] Battery drainage during 30-min session: → document and optimize

---

## PHASE 14: API RBAC Testing & Storage Rules

### 14.1 API RBAC Middleware Testing
- [ ] Write API integration tests to verify RBAC enforcement:
  - [ ] Player can read own sessions via `GET /sessions` ✅
  - [ ] Player cannot read other player's sessions (API returns 403) ❌
  - [ ] Coach can read assigned player's sessions ✅
  - [ ] Coach cannot read unassigned player's sessions (API returns 403) ❌
  - [ ] Coach can create coach notes via `POST /coach-notes` ✅
  - [ ] Player cannot create coach notes (API returns 403) ❌
  - [ ] Player cannot change own role via `PATCH /users/me` (API ignores role field) ❌
  - [ ] Admin can read all users in academy via `GET /academy/players` ✅
  - [ ] Admin cannot read users in other academy (API returns 403) ❌
- [ ] Verify: expired JWT returns 401 on all endpoints
- [ ] Verify: missing JWT returns 401 on all endpoints
- [ ] Verify: invalid JWT returns 401 on all endpoints

### 14.2 PostgreSQL Index Verification
- [ ] Verify all indexes from schema creation exist:
  - `idx_sessions_player_time` (sessions by player + time)
  - `idx_sessions_academy_time` (sessions by academy + time)
  - `idx_sessions_player_status` (sessions by player + status)
  - `idx_coach_notes_player` (notes by player + time)
  - `idx_users_academy_role` (users by academy + role)
- [ ] Run `EXPLAIN ANALYZE` on critical queries to verify index usage

### 14.3 Firebase Storage Rules
- [ ] Create storage rules:
  - Users can only upload/read their own profile images
  - Path: `profile_images/{uid}/*`
  - Max file size: 5MB
  - Allowed types: image/jpeg, image/png
- [ ] Deploy: `firebase deploy --only storage`

---

## PHASE 15: Security Hardening

### 15.1 Client-Side Security
- [ ] Verify no API calls bypass the auth interceptor (all requests carry JWT)
- [ ] Verify no API keys or secrets are hardcoded in source
- [ ] Ensure no sensitive data in console logs in production build
- [ ] Implement certificate pinning (future — flag for now)
- [ ] Verify ProGuard/R8 minification is enabled for release builds

### 15.2 Auth Security
- [ ] Rate limiting: Firebase Auth has built-in limiting; API has optional Redis rate limiting on Upstash
- [ ] Password requirements: min 8 chars, 1 uppercase, 1 number
- [ ] Google OAuth: only allowed email domains? (no restriction for V1)
- [ ] Session management: tokens auto-refresh via Firebase SDK

### 15.3 Data Security
- [ ] No raw sensor data (S1, S2, S3) in production PostgreSQL — only processed metrics
- [ ] Hive local data: consider encryption for sensitive data (hive_flutter encryption)
- [ ] Clear local data on account deletion
- [ ] Clear local data on logout

### 15.4 Privacy Compliance (India DPDP Act)
- [ ] Create Privacy Policy document → host on Vercel (alongside web dashboard) or Firebase Hosting
- [ ] Add Privacy Policy link to registration screen + settings
- [ ] Add consent checkbox on registration: "I agree to the Privacy Policy"
- [ ] Implement "Request Data Export" in settings (future V1.5)
- [ ] Implement "Delete All My Data" in settings (already in Phase 9)

---

## PHASE 16: Performance Optimization

### 16.1 App Size
- [ ] Check APK size after release build: `flutter build apk --analyze-size`
- [ ] Target: < 25MB APK
- [ ] Remove unused assets and packages
- [ ] Enable code shrinking (R8) and resource shrinking

### 16.2 API & Database Optimization
- [ ] Add pagination to ALL API list endpoints (max 20 per page)
- [ ] API uses `LIMIT` and `OFFSET` in PostgreSQL — never fetch unbounded
- [ ] Cache frequently accessed data in Hive (user profile, last 5 sessions)
- [ ] Minimize API calls per screen: batch where possible
- [ ] Consider Redis caching on API for frequently read data (player stats, academy overview)

### 16.3 BLE Optimization
- [ ] Keep BLE connection lean: subscribe only to TX, no polling
- [ ] Disconnect BLE when session ends (don't keep alive unnecessarily)
- [ ] Handle MTU correctly to minimize packet fragmentation


## PHASE 17: Production Build & Play Store

### 17.1 Pre-Launch Checklist
- [ ] Switch from Firebase dev project to production project
- [ ] Update `google-services.json` for production
- [ ] Set `debugShowCheckedModeBanner: false`
- [ ] Remove all `print()` statements (use Logger or remove)
- [ ] Remove mock BLE service from production flavor
- [ ] Enable Crashlytics and Analytics for production
- [ ] Set app version to `1.0.0` in `pubspec.yaml`

### 17.2 App Branding
- [ ] Design app icon (1024×1024 PNG) → generate all sizes
- [ ] Add app icon to `android/app/src/main/res/`
- [ ] Design splash screen (branded loading screen)
- [ ] Implement splash screen with flutter_native_splash or manual
- [ ] Set app display name: "KnoQ"
- [ ] Set package name: `com.knoq.app` (or chosen domain)

### 17.3 Build & Sign
- [ ] Generate release keystore: `keytool -genkey -v -keystore knoq-release.jks ...`
- [ ] Configure `key.properties` (NOT committed to Git)
- [ ] Configure `android/app/build.gradle` for signed release build
- [ ] Build release APK: `flutter build apk --flavor prod --target lib/main_prod.dart`
- [ ] Build release App Bundle: `flutter build appbundle --flavor prod --target lib/main_prod.dart`
- [ ] Test release build on physical device
- [ ] Verify: no debug banners, no console logs, Crashlytics works, analytics works

### 17.4 Play Store Listing
- [ ] Create Google Play Developer account (₹1,700 one-time fee)
- [ ] Create app listing: "KnoQ — Smart Cricket Coach"
- [ ] Write app description (short + full)
- [ ] Take 5+ screenshots of key screens (phone frame mockups)
- [ ] Create feature graphic (1024×500)
- [ ] Set content rating (Everyone / PEGI 3)
- [ ] Set target audience: Sports enthusiasts, cricket players
- [ ] Create privacy policy URL → add to listing
- [ ] Choose distribution: countries (India first)
- [ ] Upload App Bundle
- [ ] Submit for review

### 17.5 Internal Testing Track
- [ ] Set up Internal Testing track on Play Console
- [ ] Add team members as testers
- [ ] Upload first build to internal track
- [ ] Test install flow from Play Store
- [ ] Verify: full flow works (register → session → analytics)
- [ ] Fix any issues found
- [ ] Promote to Closed Beta → invite 10-20 pilot academy users

---

## PHASE 18: Academy Admin Web Dashboard (React)
 
> **Stack:** React + TypeScript + Tailwind CSS + shadcn/ui + Axios + Firebase Auth + react-router-dom + @tanstack/react-query
> **Hosted:** Vercel (free tier, auto-deploy from GitHub)
> **URL:** dashboard.knoq.in
> **Calls:** Same Node.js API as Flutter app — same Firebase JWT auth
 
---
 
### 18.1 Project Setup & Infrastructure
 
- [ ] Create React + TypeScript project: `npx create-vite@latest knoq-dashboard --template react-ts`
- [ ] Install core dependencies:
  ```
  react-router-dom, axios, firebase (auth only),
  @tanstack/react-query, @tanstack/react-query-devtools
  ```
- [ ] Install UI framework: **Tailwind CSS v3** + **shadcn/ui**
  - shadcn/ui gives production-quality Table, Modal, Button, Badge, Chart components instantly
  - Run: `npx shadcn-ui@latest init`
- [ ] Install additional UI packages:
  ```
  lucide-react (icons), recharts (charts),
  react-dropzone (file uploads), date-fns (date formatting),
  react-hot-toast (notifications)
  ```
- [ ] Set up project folder structure:
  ```
  src/
  ├── pages/           → one file per route/page
  ├── components/      → reusable UI components
  ├── api/             → all API call functions
  ├── hooks/           → custom React hooks
  ├── auth/            → Firebase auth context + protected routes
  ├── lib/             → axios client, utilities
  └── types/           → TypeScript interfaces matching PostgreSQL schema
  ```
- [ ] Create `src/firebase.ts`:
  - Initialize Firebase app using **same Firebase project** as Flutter app
  - Get config from: Firebase Console → Project Settings → General → Your apps → Web app → Config
  - Store all values in `.env` file (never hardcode):
    ```
    VITE_FIREBASE_API_KEY=...
    VITE_FIREBASE_AUTH_DOMAIN=...
    VITE_FIREBASE_PROJECT_ID=...
    ```
- [ ] Create `src/lib/axios.ts`:
  - Axios instance with base URL from env (`VITE_API_BASE_URL`)
  - Request interceptor: attach Firebase JWT to every request
    ```typescript
    instance.interceptors.request.use(async (config) => {
      const token = await auth.currentUser?.getIdToken();
      if (token) config.headers.Authorization = `Bearer ${token}`;
      return config;
    });
    ```
  - Response interceptor: handle 401 (force logout), 403 (show access denied)
- [ ] Implement Firebase Auth context (`src/auth/AuthContext.tsx`):
  - `onAuthStateChanged` listener
  - Fetch user role from `GET /users/me` on login
  - Store: `user`, `role`, `academyId`, `loading` in context
- [ ] Create protected route wrapper — redirect to `/login` if not authenticated
- [ ] Create role guard — redirect to `/unauthorized` if wrong role
- [ ] Implement persistent sidebar layout with top navbar
  - Sidebar collapses on mobile
  - Active route highlighted
  - User avatar + name + logout in top navbar
- [ ] Set up routing with react-router-dom:
  ```
  /login                    → Login page
  /dashboard                → Overview (default after login)
  /players                  → Player management
  /coaches                  → Coach management
  /devices                  → Device management
  /analytics                → Academy analytics
  /session-replay/:id       → Session replay viewer
  /ai-lab                   → AI/ML data control centre
  /ai-lab/tag/:clipId       → Clip tagging interface
  /reports                  → Reports & exports
  /notifications            → Notification centre
  /settings                 → Academy settings
  /super-admin              → Super admin (KnoQ team only)
  /super-admin/academies    → All academies
  /super-admin/firmware     → Firmware management
  /super-admin/health       → System health
  /unauthorized             → Access denied page
  ```
- [ ] Theme: Light mode default + dark mode toggle (Tailwind `dark:` classes)
  - Store preference in localStorage
  - Toggle in top navbar
- [ ] Verify: `npm run dev` → login works → API returns data → sidebar renders
---
 
### 18.2 Overview Page (`/dashboard`)
 
- [ ] Stats cards row (fetch from `GET /analytics/academy/:id`):
  - Total players
  - Total coaches
  - Total sessions this month
  - Total shots recorded (lifetime)
  - Active bats right now (devices with session in last 10 minutes)
- [ ] Sessions per day chart (Recharts LineChart — last 30 days)
- [ ] Academy-wide sweet spot % trend (last 8 weeks)
- [ ] Player activity heatmap (GitHub-style — who practiced which day)
- [ ] At-risk players card: players with no session in last 7 days (red list)
  - Each player shown with name + last session date + "Send reminder" button
- [ ] Top 5 performers this month (sweet%, avg power)
- [ ] Most improved this month (biggest improvement vs last month)
- [ ] Quick actions bar: "Invite Player", "Invite Coach", "Register Bat"
- [ ] Loading: skeleton cards shimmer
- [ ] Error: "Could not load overview. Retry" with retry button
---
 
### 18.3 Player Management (`/players`)
 
- [ ] Full data table (shadcn/ui DataTable with TanStack Table):
  - Columns: Photo, Name, Age, Batting Hand, Coach Assigned, Sessions, Sweet%, Last Active, Status, Actions
  - Sortable columns: name, sessions, sweet%, last active
  - Filter: by coach, by status (active/inactive), search by name
  - Pagination: 20 per page
- [ ] "Invite Player" button → modal:
  - Enter email → calls `POST /academy/invite` with role='player'
  - Player registers with that email → auto-joins academy
- [ ] Per-player actions (row dropdown):
  - View profile (navigates to player detail)
  - Assign coach → dropdown of coaches in academy
  - Deactivate player
  - Remove from academy
- [ ] Player detail page (nested route `/players/:id`):
  - Profile header: photo, name, age, batting hand, academy, coach
  - Lifetime stats: sessions, hits, best sweet%, best power, member since
  - Analytics charts: sweet% trend, power trend, zone distribution
  - Session history table (paginated, click row → session replay)
  - Coach notes timeline
  - "Export PDF Report" button
- [ ] Bulk actions: select multiple → deactivate / assign coach / export CSV
---
 
### 18.4 Coach Management (`/coaches`)
 
- [ ] Data table: Name, Email, Players Assigned, Sessions Reviewed, Joined Date, Status, Actions
- [ ] "Invite Coach" button → modal:
  - Enter email + name → calls `POST /academy/invite` with role='coach'
  - System sends invite email → coach registers → auto-assigned to academy
- [ ] Per-coach view:
  - List of assigned players with their stats
  - Coach activity (how many sessions reviewed, notes added this month)
  - Reassign players between coaches
- [ ] Deactivate coach → reassign their players prompt
---
 
### 18.5 Device Management (`/devices`)
 
- [ ] Data table: Device Name, MAC Address, Firmware Version, Battery Level, Last Seen, Assigned To, Status, Actions
- [ ] "Register New Bat" button → modal: enter MAC address + name
- [ ] Per-device status indicators:
  - Battery level badge (green >50%, orange 20–50%, red <20%)
  - Firmware version (yellow badge if outdated, red if 2+ versions behind)
  - "Active now" green pulse if session in last 10 minutes
- [ ] Device actions:
  - Assign to player (dropdown)
  - Unassign
  - Push firmware update (calls `POST /devices/:id/update-firmware`)
  - View diagnostic log
- [ ] Fleet summary bar at top:
  - X bats total | X active now | X need charging | X need firmware update
---
 
### 18.6 Session Replay Viewer (`/session-replay/:id`)
 
> This is the most important screen for coaches. Allows full review of any session from the web.
 
- [ ] Session header: player name, date, duration, total hits, sweet%, avg power
- [ ] Main layout — two panels:
  - **Left panel:** Video clip player
    - Plays the 4-second clip for the selected shot
    - Pose skeleton overlay toggleable (show/hide joints)
    - Playback speed: 0.25x, 0.5x, 1x
    - Loop toggle
  - **Right panel:** Shot data
    - Shot number (e.g. "Shot 14 of 30")
    - Visual bat zone diagram with hit zone highlighted
    - Power arc (same as mobile app style)
    - Swing speed (if available)
    - Technique score: X/100 with breakdown
    - AI feedback text (from rule-based engine)
    - Coach note input (textarea + save button → `POST /coach-notes`)
    - Previous coach notes for this player (last 3, expandable)
- [ ] Shot navigation:
  - Previous / Next buttons
  - Shot list panel (scrollable, all shots in session as mini-cards)
  - Filter shots: All | Sweet spot only | Poor technique (<50) | Edge/toe hits
- [ ] Timeline scrubber: click any point on session timeline to jump to that shot
- [ ] Session-level coach note (applies to whole session, not a specific shot)
- [ ] "Export session report" button → PDF with key shots + coach notes
---
 
### 18.7 Analytics Page (`/analytics`)
 
- [ ] Time range selector: 7 days / 30 days / 90 days / All time
- [ ] Academy-wide aggregate metrics:
  - Total sessions, total hits, avg sweet%, avg power, avg consistency
- [ ] Charts:
  - Sessions per day (bar chart)
  - Academy-wide sweet% trend (line chart)
  - Academy-wide power trend (line chart)
  - Zone distribution across all players (donut chart)
  - Shot type distribution (if AI classification active — donut chart)
- [ ] Player comparison table:
  - All players ranked by sweet% / power / consistency / sessions
  - Toggle between metrics
  - Highlight top 3 (gold/silver/bronze badges)
- [ ] Leaderboards:
  - Most improved this month (delta vs last month)
  - Most consistent (highest consistency score avg)
  - Most active (most sessions)
  - Best sweet spot % (current month)
- [ ] Export: "Download Academy Report" → CSV or PDF with all metrics
---
 
### 18.8 AI Lab (`/ai-lab`) — Data Control Centre
 
> This section is for KnoQ team and coaches to manage the AI training pipeline.
 
- [ ] **Data Collection Overview:**
  - Total video clips stored: X
  - Tagged clips: X (X%)
  - Untagged clips: X
  - Clips per shot type (bar chart — highlights shot types with < 100 clips in red)
  - Clips per delivery type (bar chart)
  - Target: 100 clips per shot type per delivery type (progress bars)
  - Estimated model readiness: "Ready to train pull shot model (127 clips)"
- [ ] **Clip Browser:**
  - Grid of all recorded clips (thumbnail + metadata)
  - Filter: Untagged only | By shot type | By academy | By player | By date
  - Sort: Newest first | Oldest first | Untagged first
  - Each clip card shows: player name, date, power, zone, tag status badge
  - Click clip → opens tagging modal
- [ ] **Clip Tagging Interface (`/ai-lab/tag/:clipId`):**
  - Full-screen tagging layout
  - Left: video player (loop, 0.25x speed, pose overlay toggle)
  - Right: tagging form
    ```
    Delivery Type: [Yorker] [Full] [Good Length] [Short] [Bouncer]
    Ball Line:     [Wide Off] [Off Stump] [Middle] [Leg] [Wide Leg]
    Shot Played:   [Drive] [Pull] [Hook] [Defend] [Sweep] [Cut] [Flick] [Other]
    Shot Selection:[Perfect] [Good] [Risky] [Wrong]
    Technique:     ★★★★★ (1-5 stars)
    Notes:         [text input for coach observations]
    ```
  - Keyboard shortcuts for speed: Q/W/E/R/T for delivery, A/S/D/F for shot, 1-5 for rating
  - "Save & Next" button → saves tag → loads next untagged clip automatically
  - Progress bar: "You've tagged 47 clips today"
  - Assign tagging tasks: admin can assign X clips to a specific coach
  - Tag history: who tagged this clip + when (audit trail)
- [ ] **Model Management:**
  - Current deployed model: version, accuracy, date trained
  - Model versions table: version | accuracy | clips used | deployed | actions
  - Accuracy breakdown by shot type (which shots is it confused about)
  - Recent predictions log: show last 20 predictions vs actual label
  - "Upload new model" button (admin uploads `.tflite` file)
  - "Deploy to production" button → triggers API to serve new model to Flutter apps
  - Rollback: revert to previous model version
- [ ] **AI Training Data Export:**
  - Select filters: date range, academy, shot types, minimum quality rating (≥3 stars)
  - Preview count: "This will export 847 clips"
  - Export options:
    - Pose landmarks CSV (33 joints × frames — ready for Google Colab)
    - Sensor data JSON (bat metrics per shot)
    - Labels CSV (shot type, delivery type, technique score per clip)
    - Full dataset ZIP (everything together — drag to Colab and train)
  - Download button → generates and downloads ZIP
  - Export history log (who exported what and when)
---
 
### 18.9 Reports & Exports (`/reports`)
 
- [ ] **Academy Report:**
  - Select date range + metrics to include
  - Preview PDF in browser before downloading
  - Includes: academy stats, player table, top performers, trend charts, KnoQ branding
- [ ] **Per-Player Reports:**
  - Select player + date range
  - PDF: player profile, session history, zone distribution, coach notes
- [ ] **Raw Data Export:**
  - Sessions CSV (all sessions in academy for selected period)
  - Shots CSV (all individual shots — useful for manual analysis)
  - Coach notes CSV
- [ ] **Scheduled Reports (V1.5):**
  - Weekly academy summary email (placeholder — set up in V1.5)
---
 
### 18.10 Notification Centre (`/notifications`)
 
- [ ] Compose notification:
  - Target: All players | Specific player | All coaches | Specific coach | Entire academy
  - Type: Practice reminder | Session feedback available | General announcement
  - Message input (max 200 characters)
  - Schedule: Send now | Schedule for time
  - Preview what it will look like on phone
  - Send → calls `POST /notifications/send` → API triggers FCM
- [ ] Sent notifications history:
  - Table: message, target, sent time, delivered count, opened count
- [ ] Automated notification rules (toggle on/off):
  - "Notify player when coach adds a note" — ON/OFF
  - "Weekly summary to all players every Sunday" — ON/OFF
  - "Notify admin when player hasn't practiced in 7 days" — ON/OFF
  - "Notify coach when assigned player completes a session" — ON/OFF
---
 
### 18.11 Academy Settings (`/settings`)
 
- [ ] Academy profile: name, city, state, logo upload
- [ ] Join code: display current code + "Regenerate" button → `POST /admin/regenerate-code`
- [ ] Plan details: current plan, expiry date, player/coach limits
- [ ] Danger zone: "Archive Academy" (Super Admin only)
---
 
### 18.12 Super Admin Panel (`/super-admin`) — KnoQ Internal Only
 
> Visible only to users with `role = 'super'`. Hidden from all other roles.
 
- [ ] **Platform Overview:**
  - Total academies (active / inactive)
  - Total players, coaches, sessions (all time + this month)
  - Total shots recorded (all time)
  - Storage used (Firebase Storage total)
  - API health: green/red status per endpoint (ping every 60s)
  - Error rate last 24hrs (from Crashlytics or API logs)
  - Active sessions right now (live count)
- [ ] **Academy Management:**
  - Full table of all academies: name, city, plan, players, coaches, sessions, created date, status
  - Create new academy: name, owner email, city, plan, expiry
  - Edit any academy: change plan, extend expiry, set player/coach limits
  - "View as Admin" → impersonate that academy's admin view (for support)
  - Deactivate / reactivate academy
  - Delete academy (hard delete — requires typing academy name to confirm)
- [ ] **Firmware Management:**
  - Current firmware version deployed
  - Upload new firmware file (.bin)
  - Release notes input
  - Push OTA update to:
    - All devices globally
    - Specific academy's devices
    - Specific device by MAC address
  - Update history: version | date | pushed to | success count | fail count
  - Rollback to previous firmware version
- [ ] **System Health:**
  - API response time graph (last 24hrs)
  - Database query performance (slow queries log)
  - Storage usage trend (GB over time)
  - FCM delivery rate
  - Recent error log (last 50 errors from API)
- [ ] **User Management (global):**
  - Search any user by email across all academies
  - View their profile, sessions, academy
  - Force logout (invalidate tokens)
  - Delete user (with confirmation)
  - Change user role (super admin only)
---
 
### 18.13 Deploy & Verify
 
- [ ] Set up `.env` with all environment variables (API URL, Firebase config)
- [ ] Build: `npm run build` → verify zero TypeScript errors
- [ ] Connect GitHub repo to Vercel for auto-deploy
- [ ] Set environment variables in Vercel dashboard (same as `.env`)
- [ ] Configure custom domain: `dashboard.knoq.in`
- [ ] Test login as: Academy Admin, Coach, Super Admin
- [ ] Verify all API calls use correct endpoints and return data
- [ ] Verify dark mode toggle works and persists across page refresh
- [ ] Verify all role guards work (admin cannot access `/super-admin`)
---
 
## PHASE 19: Post-Launch — V1.5 Enhancements
 
> Build these after the first 5 academies are using the product and you have real feedback.
 
### 19.1 Coach Notes Enhancement
- [ ] Rich text notes (bold, italic, bullet points — use a lightweight editor like Tiptap)
- [ ] Predefined tag system: footwork, timing, power, stance, grip, shot selection, mental
- [ ] Coach notes timeline view per player (all notes in chronological order)
- [ ] Push notification to player when coach adds note (FCM)
- [ ] Player can reply to coach note (simple text reply — creates conversation thread)
### 19.2 PDF Export Enhancement
- [ ] Weekly academy summary PDF — auto-generated every Sunday, emailed to admin
- [ ] Monthly progress PDF per player — emailed to player + coach
- [ ] Branded PDF with academy logo (uploaded in settings)
- [ ] Comparison section in PDF: player vs academy average per metric
### 19.3 Drill Assignments (Coach → Player)
- [ ] Coach creates drill in web dashboard or app:
  - Name, description, target zone, target power range, shot count goal, deadline
- [ ] Drill appears in player's app as a challenge card on home screen
- [ ] Player completes session → app automatically checks if drill criteria met:
  - X shots in target zone with power > target → drill complete
- [ ] Completion badge shown in player app
- [ ] Coach notified via FCM when player completes drill
- [ ] Drill history and completion rate visible in coach dashboard
### 19.4 Advanced Analytics (App + Dashboard)
- [ ] Heatmap visualization: bat face with gradient intensity showing where hits cluster
- [ ] Session-to-session improvement badges: "+12% sweet spot this week"
- [ ] Personal best tracking with celebration animation (confetti on new PB)
- [ ] Fatigue curve: power vs shot number with trend line (shows when player gets tired)
- [ ] Optimal session length recommendation: "Your performance drops after 45 shots"
- [ ] Consistency trend: is the player getting more or less consistent over time
### 19.5 Data Export (Player + Coach + Admin)
- [ ] Player: export own data as CSV/JSON from Settings → "Export My Data"
- [ ] Coach: export player data as CSV from player detail screen
- [ ] Admin: export full academy data from Reports page (already in Phase 18.9)
- [ ] All exports include: session metadata + shot data + coach notes
### 19.6 Localization
- [ ] Set up Flutter localization (intl package + ARB files)
- [ ] English default — complete all strings in `en.arb`
- [ ] Hindi (`hi.arb`) — translate all strings (hire translator or use team)
- [ ] Marathi (`mr.arb`) — Maharashtra market is primary
- [ ] Language selector in Settings screen
- [ ] Web dashboard: English only in V1.5, Hindi in V2
### 19.7 Scheduled Reports & Email Automation
- [ ] Backend: Node.js cron job (node-cron) runs every Sunday midnight
- [ ] Generates weekly summary for each academy → sends email via SendGrid
- [ ] Email content: sessions this week, top performer, sweet% trend, coach tip
- [ ] Admin can opt out in Academy Settings
---

## PHASE 20: V2 — Camera, AI & Advanced Features
 
> Start building Phase 20 in parallel with Phase 18/19 data collection.
> The AI features depend on having labelled training data — start collecting NOW.
> **Companion doc:** `docs/KNOQ_AIML_ROADMAP.md` — full technical spec for all four AI components.
>
> **Legend:** 🤖 = Antigravity can code this | 👤 = You must do manually | 🤝 = Collaborative

---
 
### 20.1 Data Collection Infrastructure (Start Immediately)
 
> This must start during Phase 18, not after. Every session recorded now is future training data.
 
- [ ] 🤖 **App side — camera recording:**
  - Add `camera` package to pubspec, request camera permission
  - Camera starts recording automatically when BLE session starts
  - Records full session video (bowler's end, phone on tripod)
  - On session end: video saved to local storage first, then uploads to Firebase Storage
  - Firebase Storage path: `sessions/{sessionId}/full_video.mp4`
  - Add `video_url` column to sessions table in PostgreSQL
- [ ] 🤖 **Clip extraction pipeline:**
  - After session save: for each shot timestamp, extract 4-second clip (2s before + 2s after impact)
  - Strategy: send extraction job to backend API → Node.js uses ffmpeg to cut clips
  - Each clip stored: `sessions/{sessionId}/clips/shot_{N}.mp4`
  - Add `clip_url` column to shots table in PostgreSQL
  - 👤 Install ffmpeg on Railway/Render server (one-time server config)
- [ ] 🤖 **Database schema for AI:**
  - Create `shot_analysis` table (session_id, shot_number, clip_url, delivery_type, shot_type, scores, pose_landmarks, feedback, tagging metadata)
  - Create `ai_models` table (model_name, version, accuracy, tflite_url, is_deployed)
  - Create indexes for fast query
- [ ] 🤖 **Tagging system (built in Phase 18.8 AI Lab):**
  - All clips automatically appear in AI Lab clip browser as untagged
  - 🤝 Coaches and KnoQ team tag clips using the tagging interface
  - 👤 Target: tag 100 clips per shot type before starting model training
- [ ] 🤖 **Data quality rules:**
  - Clips where player is not visible → auto-detect and flag (basic frame brightness check)
  - 🤝 Clips with bad camera angle → coaches mark as "unusable" during tagging
  - Only clips with quality rating ≥ 3 stars used for training

---

### 20.2 BLE + Camera Synchronization
 
- [ ] 🤖 **Timestamp alignment strategy:**
  - BLE receives shot → app records `DateTime.now().millisecondsSinceEpoch` as `ble_timestamp`
  - Camera video has its own timeline starting from recording start
  - Impact frame = `ble_timestamp - session_start_timestamp` = frame offset in video
  - Convert frame offset to video timecode: `frame_number = offset_ms / (1000 / fps)`
- [ ] 🤖 **Verification UI:**
  - Show extracted clip to user after session — if impact is not in center of clip → allow manual adjustment (drag timeline left/right to re-align)
  - Store adjusted offset in `shots.video_offset_ms`

---

### 20.3 Pose Estimation Integration (MediaPipe)
 
- [ ] 🤖 Add `google_mlkit_pose_detection` to pubspec.yaml
- [ ] 🤖 Run MediaPipe on each extracted clip (on-device, after session ends — batch processing)
- [ ] 🤖 Extract 33 landmark coordinates per frame for ~15 frames around impact
- [ ] 🤖 Store landmarks as JSONB in PostgreSQL: `shot_analysis.pose_landmarks`
- [ ] 🤖 Display pose skeleton overlay on session replay (app + web dashboard)
  - Toggle on/off in replay view
  - Color-code joints: correct position = green, incorrect = red (rule-based check)
- [ ] 🤖 Identify key moments from pose sequence:
  - Backlift initiation frame
  - Downswing start frame
  - Impact frame (synced with BLE timestamp)
  - Follow-through completion frame
- [ ] 🤖 Compute derived cricket metrics from raw landmarks:
  - `head_over_front_knee`, `front_elbow_height`, `hip_rotation_angle`
  - `stride_length`, `weight_transfer`, `follow_through_completeness`
  - Store frame indices per shot for model training

---

### 20.4 Rule-Based Technique Evaluation (V1 AI — No ML needed)
 
> This gives immediate AI-style feedback before any model is trained.
> Ships with manual tags + bat sensor data + pose landmarks.
 
- [ ] 🤝 **Define correct pose criteria for each shot type:**
  - 👤 Work with a cricket coach to validate thresholds
  - 🤖 Encode as structured config (not hardcoded if/else)
  - Shot types with checklists: cover_drive, straight_drive, pull, hook, cut, sweep, defensive_front, defensive_back, slog, yorker_dig_out
  - Each checklist = 4–6 pose markers with ideal ranges + weights (see `KNOQ_AIML_ROADMAP.md` §4)
- [ ] 🤖 **Implement `technique_evaluator.dart`:**
  - Input: pose landmarks + shot type + delivery type + bat sensor data
  - Output: shot_selection_score (0–100), technique_score (0–100), per-joint breakdown, feedback strings
  - Shot selection logic: delivery → appropriate shot mapping table
  - Technique scoring: weighted average of pose marker checks per shot type
- [ ] 🤖 **Manual tagging UI in Flutter app:**
  - After session, player tags each shot: delivery type (5 buttons) + shot type (8 buttons)
  - Simple bottom sheet UX, takes <5 seconds per shot
  - Tags stored in `shot_analysis.delivery_type` and `shot_analysis.shot_type`
  - These manual tags power V1 feedback AND become training data for V2 models
- [ ] 🤖 Show per-joint feedback in session replay: "Front elbow was too low on shot #14"
- [ ] 🤖 Write unit tests for each shot type with correct and incorrect pose data

---

### 20.5 Shot Classification Model (First Trained ML Model)
 
> Only start training after you have 500+ tagged clips. Until then, manual tags work fine.
 
- [ ] 🤖 **Data preparation (Python script — runs in Google Colab):**
  - Export tagged clips + pose landmarks from PostgreSQL via AI Lab export
  - Build dataset: `X.npy` shape (N, 15, 99) — 15 frames × 33 joints × 3 coords
  - Build labels: `y.npy` shape (N,) — shot type integer (0–9)
  - Split: 80% train, 10% validation, 10% test
- [ ] 🤝 **Model training (Google Colab — free GPU):**
  - 🤖 Write the training notebook (LSTM architecture, ~50 lines)
  - 👤 Upload dataset to Colab, run training, evaluate results
  - Architecture: 2-layer LSTM (128→64) + Dense(32) + Softmax(10)
  - Target accuracy: >80% on validation set before deploying
  - Export as `.tflite` for on-device inference
- [ ] 🤖 **Flutter integration:**
  - Add `tflite_flutter` package to pubspec.yaml
  - Load `shot_classifier.tflite` from assets or Firebase Storage
  - Run inference on pose landmarks after each session (replaces manual shot type tag)
  - Display detected shot type on each shot card in session history
- [ ] 🤖 **API + analytics integration:**
  - Store shot type in `shot_analysis.shot_type`
  - Analytics: "Your most played shot is cover drive (34%)"
  - Web dashboard session replay shows shot type badges

---

### 20.6 Delivery Detection (Ball Tracking)
 
**V1 — Manual tagging (ships immediately):**
- [ ] 🤖 Bottom sheet after each shot: "What was that delivery?" — 5 buttons
- [ ] 🤖 Tags stored in `shot_analysis.delivery_type`
- [ ] 🤖 Used immediately by shot selection evaluator

**V2 — Automatic ball detection (after 500+ labelled clips):**
- [ ] 🤖 Write fine-tuning script for YOLOv8-nano on cricket ball footage
- [ ] 👤 Label ball position in 500+ clips using LabelImg or Roboflow (free tools)
- [ ] 🤝 Train model: track ball trajectory across frames → classify pitch point
- [ ] 🤖 Deploy as FastAPI endpoint on Railway (cloud GPU inference)
- [ ] 🤖 Flutter app sends clip to API → gets delivery type back → stores in PostgreSQL

---

### 20.7 AI Coaching Engine (Full Pipeline — V2)
 
> Replaces the rule-based engine once you have 2000+ labelled clips with expert ratings.
 
- [ ] 🤖 **Technique scoring model:**
  - Architecture: multi-input neural network (pose branch + sensor branch → merge → score)
  - 👤 Training data: coach ratings (1–5 stars) from AI Lab as ground truth
  - 🤝 Train in Colab, convert to TFLite or deploy as cloud API
- [ ] 🤖 **Personalized feedback generation:**
  - V1 (template-based): "Your {front_foot} was {X}cm short of the ball on {N} drives"
  - V2 (LLM-based): send structured shot data to GPT-4 API → natural language coaching tip
- [ ] 🤖 **Post-session AI report:**
  - After processing complete (~30–60 seconds post-session):
  - Push notification: "Your session analysis is ready"
  - Shows: session summary + shot type breakdown + top 3 technique issues + improvement vs last session

---

### 20.8 Voice Coaching (Real-Time Feedback)
 
> Runs DURING the session using bat sensor data only (no video processing needed).
 
- [ ] 🤖 **Implementation:**
  - BLE shot received → immediate rule-based check on sensor data
  - Within 500ms: determine if feedback is warranted
  - Flutter TTS package plays audio through phone speaker
- [ ] 🤖 **Feedback triggers (sensor data only — fast):**
  - Power < 30% → "More power — full follow through"
  - Timing = early AND power < 40% → "Too early — wait for the ball"
  - Sweet spot + power > 75% → "Perfect hit!"
  - 3 consecutive toe/edge hits → "Focus on watching the ball"
- [ ] 🤖 **Settings UI:** toggle ON/OFF, volume, voice (male/female), language (English/Hindi)

---

### 20.9 Advanced Features (V3+)
 
- [ ] 🤝 **Match Pressure Engine:** simulate match scenarios, track shot quality under pressure
- [ ] 🤝 **Pro comparison templates:** record coach demonstrating ideal shots → compare player skeleton overlay
- [ ] 🤖 **AI Coach video:** Python script generates personalized coaching video (moviepy + TTS + highlights)
- [ ] 🤖 **Leaderboards:** cross-academy opt-in leaderboards, weekly challenges
- [ ] 🤖 **White-label academies:** custom logo, colors, branded URL `[name].knoq.in`

---

### Phase 20 — Execution Order & Timeline

| Step | Phase | What | Depends On | Who |
|------|-------|------|------------|-----|
| 1 | 20.1 | Camera recording + clip extraction | Nothing — start now | 🤖 |
| 2 | 20.2 | BLE-Camera timestamp sync | 20.1 | 🤖 |
| 3 | 20.3 | MediaPipe pose integration | 20.1 | 🤖 |
| 4 | 20.4 | Manual tagging UI + rule engine | 20.3 | 🤖+🤝 |
| 5 | — | **Data collection checkpoint:** 500 tagged clips | 20.4 + 👤 coaching time | 👤 |
| 6 | 20.5 | Train shot classifier | 500 tagged clips | 🤝 |
| 7 | 20.6 | Train ball detector | 500 labelled clips | 🤝 |
| 8 | 20.7 | Train technique scorer | 2000 rated clips | 🤝 |
| 9 | 20.8 | Voice coaching | Bat sensor data only | 🤖 |
| 10 | 20.9 | Advanced features | Everything above | 🤝 |

---

## STATUS SUMMARY

| Phase | Name | Status | Notes |
|-------|------|--------|-------|
| 0 | Environment Setup | ✅ Complete | Hardware setup pending |
| 1 | Design System | ✅ Complete | |
| 2 | Authentication | ✅ Complete | |
| 3 | BLE Service | ✅ Complete | |
| 4 | Live Session | ✅ Complete | Critical path — done |
| 5 | Session History | ✅ Complete | |
| 6 | Coaching Insights | ✅ Complete | |
| 7 | Analytics Dashboard | ✅ Complete | |
| 8 | Home & Navigation | ✅ Complete | |
| 9 | Profile & Settings | ✅ Complete | |
| 10 | Coach Features | ✅ Complete | Academy delegation done |
| 11 | Offline Sync | ✅ Complete | |
| 12 | Notifications & Extras | ✅ Complete | |
| 13 | Testing & QA | ✅ Complete | Pre-launch |
| 14 | API RBAC Testing | ✅ Complete | Pre-launch |
| 15 | Security Hardening | ✅ Complete | |
| 16 | Performance | ✅ Complete | |
| 17 | Production Build | 🟡 In Progress | Launch blocker |
| 18 | Admin Dashboard (React) | ⬜ Not Started | Post-launch |
| 19 | V1.5 Enhancements | ⬜ Not Started | Post-launch |
| 20 | V2 — AI & Camera | ⬜ Not Started | Ready to start |

**Legend:** ⬜ Not Started | 🟡 In Progress | ✅ Complete

---

*This master plan covers the complete end-to-end development of the KnoQ mobile application.*  
*Update this document as tasks are completed.*  
*Last updated: April 2026*
