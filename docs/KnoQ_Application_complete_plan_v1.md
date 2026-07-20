# KnoQ Performance App — Complete Application Specification V2

## Production-Ready Flutter Development Blueprint

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Stakeholders & User Roles](#2-stakeholders--user-roles)
3. [Authentication & Authorization](#3-authentication--authorization)
4. [Data Architecture](#4-data-architecture)
5. [Complete Screen Map](#5-complete-screen-map)
6. [BLE Connectivity — Detailed Spec](#6-ble-connectivity--detailed-spec)
7. [Coaching Insights Engine](#7-coaching-insights-engine-v1--rule-based)
8. [UI/UX Specification](#8-uiux-specification)
9. [Notifications](#9-notifications)
10. [Tech Stack — Complete](#10-tech-stack--complete)
11. [Flutter Project Structure](#11-flutter-project-structure)
12. [State Management Architecture](#12-state-management-architecture-riverpod)
13. [Session Recovery & Crash Safety](#13-session-recovery--crash-safety)
14. [Android Permissions Flow](#14-android-permissions-flow)
15. [Firebase Security Rules](#15-firebase-security-rules)
16. [Firestore Indexes](#16-firestore-indexes)
17. [App Lifecycle & Session Protection](#17-app-lifecycle--session-protection)
18. [Academy Code System](#18-academy-code-system)
19. [Offline Sync Strategy](#19-offline-sync-strategy)
20. [Navigation & Routing](#20-navigation--routing)
21. [Screen States — Loading / Empty / Error](#21-screen-states--loading--empty--error)
22. [Analytics & Event Tracking](#22-analytics--event-tracking)
23. [Performance Requirements](#23-performance-requirements)
24. [Error Handling & Edge Cases](#24-error-handling--edge-cases)
25. [Testing Strategy](#25-testing-strategy)
26. [Build Flavors & Environment Config](#26-build-flavors--environment-config)
27. [Security & Privacy](#27-security--privacy)
28. [Monetization Hooks](#28-monetization-hooks)
29. [User Flow — Complete](#29-user-flow--complete)
30. [MVP Scope & Build Order](#30-mvp-scope--build-order)
31. [Definition of Done](#31-definition-of-done)
32. [Resolved Technical Decisions](#32-resolved-technical-decisions)

---

## 1. PROJECT OVERVIEW

**App Name:** KnoQ Performance App
**Tagline:** A smart coach in your pocket.
**Platform:** Flutter (Android primary, iOS later, Web dashboard for coaches)
**Purpose:** Real-time cricket performance analysis via Bluetooth-connected smart bat. Converts raw sensor data into actionable coaching insights for players, coaches, and academy administrators.

This is not just a Bluetooth data logger. KnoQ is a multi-stakeholder performance platform with role-based access, session management, longitudinal progress tracking, and AI-style coaching feedback. Every design and architecture decision must support this vision from day one — even if V1 only ships a subset of features.

---

## 2. STAKEHOLDERS & USER ROLES

### 2.1 Complete Stakeholder Map

| Stakeholder | Who They Are | Their Goal |
|-------------|-------------|------------|
| **Player** | Student / amateur cricketer using the bat | Improve batting — track power, sweet spot, zones over time |
| **Coach** | Academy coach supervising multiple players | Monitor all players' data, compare, assign drills |
| **Academy Admin** | Owner / manager of a cricket academy | Manage coaches and players, view academy-level analytics, billing |
| **Super Admin** | KnoQ internal team | Platform management, all academy access, support |
| **Parent** (future) | Parent of an underage player | Read-only view of their child's progress |

### 2.2 RBAC — Role-Based Access Control

#### Player
- Can: register, log in, connect bat, start/end sessions, view own sessions, view own analytics, view own coaching insights, edit own profile
- Cannot: see other players' data, access coach views, manage academy settings, export bulk data

#### Coach
- Can: log in, view all players assigned to them, view any assigned player's full session history and analytics, add notes to a player's session, create drill assignments, compare players side-by-side, export player reports (PDF)
- Cannot: see players not assigned to them, access billing, manage other coaches, delete player accounts

#### Academy Admin
- Can: log in to web dashboard + app, create and manage coach accounts, assign players to coaches, view academy-wide analytics (aggregated), manage bat device registrations, view billing and subscription status, export academy reports
- Cannot: access other academies' data, modify KnoQ platform settings

#### Super Admin (KnoQ internal)
- Can: access all academies, all data, platform configuration, push firmware OTA, manage subscriptions, view system health
- Web dashboard only — no mobile app login

### 2.3 Data Visibility Rules (Critical)

```
Player data visibility:
  Player → own data only
  Coach  → data of assigned players only
  Academy Admin → aggregated stats of all players in their academy
                  (can drill into individual on request)
  Super Admin → everything

Session data:
  A session belongs to ONE player
  A coach can VIEW but never EDIT a player's session data
  Coach notes are separate from session data (additive, not modifying)

Device (bat) ownership:
  A bat is registered to an academy
  A bat can be assigned to a player for a session
  A bat cannot be simultaneously assigned to two players
```

---

## 3. AUTHENTICATION & AUTHORIZATION

### 3.1 Auth Stack
- **Firebase Authentication** (primary) — email/password + Google OAuth
- **JWT tokens** for API calls (Firebase ID tokens, refreshed automatically)
- **Role stored in Firestore** `users/{uid}/role` — checked on every protected route
- **Academy ID stored in Firestore** `users/{uid}/academyId` — scopes all data queries

### 3.2 Login Flow

```
App launch
  ↓
Check Firebase auth state
  ↓
Not logged in → Login Screen
  ↓
Login Screen:
  - Email + Password
  - "Continue with Google"
  - "Forgot password" → Firebase email reset
  ↓
On login success:
  - Fetch user document from Firestore
  - Read role field
  - Route to correct home screen:
      role = "player"  → Player Home
      role = "coach"   → Coach Dashboard
      role = "admin"   → Academy Admin Dashboard
      role = "super"   → Web only, block mobile with message
  ↓
On first login (new player):
  - Onboarding flow (name, age, batting hand, academy code)
  - Academy code links player to academy
```

### 3.3 Registration

**Players register themselves:**
- Email, password, name, age, batting hand (left/right), academy code (optional — links them to an academy)
- Email verification sent on registration — app shows "Verify your email" until confirmed
- Password requirements: minimum 8 characters, at least 1 number

**Coaches are created by Academy Admin:**
- Admin creates coach account → system sends invite email → coach sets password
- Coach cannot self-register

**Academy Admins are created by Super Admin (KnoQ team) only**

### 3.4 Session Security
- All Firestore rules enforce role checks server-side (not just client-side)
- A player cannot query another player's sessions even by manipulating the app
- Firebase Security Rules document is specified in Section 15

### 3.5 Offline Handling
- If no internet: session data saves locally (Hive local DB)
- On reconnect: auto-sync to Firestore
- BLE functionality works fully offline — internet only needed for cloud sync and coach features

### 3.6 Account Management
- **Account deletion:** Player can request full account + data deletion from Settings → triggers Cloud Function that deletes all sessions, shots, profile, and Firebase Auth account
- **Password change:** Via Firebase Auth email flow
- **Email change:** Via Settings → requires re-authentication → Firebase Auth update
- **Rate limiting:** Firebase Auth has built-in rate limiting (e.g., 5 failed login attempts → temporary lockout)

### 3.7 Onboarding Flow (Detailed)

```
Onboarding (3 screens, swipeable + progress indicator):

Screen 1: "Welcome to KnoQ"
  - Brief value prop with animation (bat + data visualization)
  - "Let's set up your profile" button

Screen 2: "About You"
  - Name (text field, required — blocks progress without it)
  - Age (number picker 8–60, required)
  - Batting hand (toggle: Left / Right, required)
  - Profile photo (camera/gallery, optional — show avatar placeholder)

Screen 3: "Join Your Academy"
  - Academy code (6-character text field, optional)
  - On valid code → show academy name below for confirmation
  - "I don't have a code" → skip, standalone mode
  - "Join" button

→ Save to Firestore → set onboardingComplete = true → Navigate to Player Home

Skip behavior:
  - Name, Age, Batting hand are REQUIRED (blocks progress)
  - Academy code is OPTIONAL
  - If code skipped, prompt again after 3rd session with a subtle banner
```

---

## 4. DATA ARCHITECTURE

### 4.1 Firestore Collections

```
/users/{uid}
  name: string
  email: string
  role: "player" | "coach" | "admin" | "super"
  academyId: string | null
  battingHand: "left" | "right"
  age: number
  createdAt: timestamp
  lastLoginAt: timestamp
  assignedCoachId: string | null   (for players)
  assignedPlayers: [uid, ...]      (for coaches)
  profileImageUrl: string | null
  fcmToken: string | null
  appVersion: string
  onboardingComplete: boolean

/academies/{academyId}
  name: string
  ownerUid: string
  city: string
  state: string
  plan: "starter" | "growth" | "enterprise"
  planExpiresAt: timestamp
  createdAt: timestamp
  totalBats: number
  joinCode: string                 (6-char alphanumeric, unique)
  maxPlayers: number               (plan-gated limit)
  maxCoaches: number               (plan-gated limit)
  logoUrl: string | null

/devices/{deviceId}
  macAddress: string
  name: "KnoQ-Bat-V1"
  academyId: string
  firmwareVersion: string
  registeredAt: timestamp
  lastSeenAt: timestamp
  currentAssignedTo: uid | null

/sessions/{sessionId}
  playerId: uid
  academyId: string
  deviceId: string
  startTime: timestamp
  endTime: timestamp | null
  status: "active" | "completed" | "abandoned"
  totalHits: number
  sweetSpotHits: number
  sweetSpotPct: number
  avgPower: number
  peakPower: number
  zoneDistribution: {
    sweet: number, top: number,
    left: number, right: number, bottom: number
  }
  consistencyScore: number
  coachNotes: string | null        (written by coach, not player)
  appVersion: string
  firmwareVersion: string
  syncStatus: "synced" | "pending" | "failed"
  insights: [{
    type: string,
    title: string,
    detail: string,
    action: string
  }]

/sessions/{sessionId}/shots/{shotId}
  timestamp: timestamp
  shotNumber: number
  zone: "sweet"|"top"|"left"|"right"|"bottom"
  power: number        (0–100)
  swing: number        (°/s from gyro)
  rawS1: number
  rawS2: number
  rawS3: number

/coachNotes/{noteId}
  coachId: uid
  playerId: uid
  sessionId: string
  note: string
  createdAt: timestamp
  tags: ["footwork", "timing", "power", "technique", "stance",
         "follow-through", "head-position", "grip"]
```

### 4.2 Incoming BLE Data Format (from ESP32)

Per shot (received as JSON string over BLE UART notify):
```json
{
  "hit": 25,
  "zone": "left",
  "power": 72,
  "swing": 120.5,
  "sweet_pct": 60,
  "avg_power": 68,
  "total_hits": 25
}
```

Session summary (sent every 10 hits automatically):
```json
{
  "summary": true,
  "total": 30,
  "sweet_pct": 63,
  "avg_power": 71,
  "peak_power": 94,
  "duration_s": 420
}
```

### 4.3 Local Storage (Hive)

```
Box: 'user_cache'
  - User profile data for instant app load

Box: 'session_cache'
  - Last 5 completed sessions for offline analytics viewing

Box: 'active_session'
  - Write-ahead log for crash recovery (see Section 13)
  - Keys: 'session_meta', 'shots', 'is_active'

Box: 'pending_sync'
  - Sessions that failed to sync to Firestore
  - Retried on next internet connection
```

### 4.4 Data Retention
- No sensor raw data (S1, S2, S3) stored in production Firestore — only processed metrics
- Raw data stored only in local Hive during active session, cleared after sync
- Session data retained indefinitely (user can request deletion via Settings)

---

## 5. COMPLETE SCREEN MAP

### 5.1 Player App Screens

```
Splash Screen
  ↓
Login / Register
  ↓
Onboarding (first time only — 3 screens)
  ↓
Player Home
  ├── Quick stats (last session, lifetime sweet%)
  ├── Start Session button
  ├── Recent sessions list (last 5, paginated on "View All")
  ├── Device connection status pill
  └── Pending sync badge (if offline sessions exist)

Start Session Flow
  ├── Permission Check (BLE + Location — see Section 14)
  ├── BLE Scan Screen (scan → find KnoQ-Bat-V1 → connect)
  ├── Pre-session check (connection confirmed, calibration status)
  └── → Live Session Screen

Live Session Screen (CORE)
  ├── Zone indicator (visual bat diagram, zone lights up)
  ├── Power meter (large number + progress arc)
  ├── Last shot card (zone + power + swing speed)
  ├── Running stats bar (hits / sweet% / avg power)
  ├── Shot history mini-list (last 5 shots scrolling)
  ├── End Session button (with confirmation dialog)
  └── BLE status indicator (connected / reconnecting / disconnected)

Session Summary Screen (after End Session)
  ├── Total hits, sweet spot %, avg power, peak power
  ├── Zone distribution pie chart
  ├── Power over time line chart
  ├── Coaching insight cards (top 1–3 insights)
  ├── Save Session button → Firestore sync (or local if offline)
  └── Share button (screenshot of summary)

Shot History Screen
  ├── Full list of shots in session
  ├── Each row: shot #, zone badge, power bar, swing
  └── Filters: All / Sweet only / Weak (<40%) / Strong (>75%)

Analytics Dashboard
  ├── Time range selector (This session / Last 7 days / Last 30 days / All time)
  ├── Zone distribution pie/donut chart
  ├── Power trend line chart (per session avg)
  ├── Sweet spot % trend line
  ├── Consistency score gauge
  ├── Strongest zone badge
  ├── Weakest zone badge
  └── Heatmap of hit zones (visual bat face)

Coaching Insights Screen
  ├── Rule-based insights (V1) — see Section 7
  ├── Each insight card: title, detail, suggested drill
  └── Progress indicators (improving / declining / stable)

Profile Screen
  ├── Name, age, batting hand, academy
  ├── Lifetime stats (total sessions, total hits, best sweet%)
  ├── Edit profile
  └── Logout

Settings Screen
  ├── BLE device management (connect / disconnect / forget)
  ├── Calibration reset (sends reset command to bat)
  ├── Notification preferences
  ├── Join Academy (enter code — if not already in one)
  ├── Data & privacy
  ├── Delete account (with confirmation + re-auth)
  └── App version + firmware version

Notifications
  ├── "Session saved successfully"
  ├── "Coach added a note to your last session"
  ├── "New personal best: 94% power!"
  └── "Your sweet spot % improved this week"
```

### 5.2 Coach App Screens (same app, role-gated)

```
Coach Dashboard
  ├── Player list (all assigned players)
  ├── Each player card: name, last session date, sweet%, avg power
  ├── Sort by: name / last active / sweet% / avg power
  └── Search bar

Player Detail (coach view)
  ├── Full analytics for that player (all time)
  ├── Session history list
  ├── Trend charts (sweet%, power over weeks)
  ├── Add coaching note button
  ├── Compare with another player button
  └── Export PDF report button

Session Detail (coach view)
  ├── All shots in that session
  ├── Zone distribution
  ├── Power chart
  ├── Coach note for this session (editable by coach)
  └── Coaching insight auto-generated for that session

Compare Players Screen
  ├── Select 2 players
  ├── Side-by-side: sweet%, avg power, consistency, strongest zone
  └── Overlay power trend charts

Drill Assignment (future V2)
  ├── Create drill (name, target zone, target power, shot count)
  └── Assign to player → player sees it in their app
```

### 5.3 Academy Admin Web Dashboard

```
Overview
  ├── Total players, total coaches, total sessions this month
  ├── Academy-wide avg sweet%, avg power
  └── Activity heatmap (sessions per day)

Player Management
  ├── All players table (paginated)
  ├── Add player / invite player
  ├── Assign coach to player
  └── Deactivate player

Coach Management
  ├── All coaches
  ├── Invite coach (sends email)
  ├── View coach's player list
  └── Deactivate coach

Device Management
  ├── All registered bats
  ├── Each bat: MAC address, firmware version, last seen, assigned to
  ├── Register new bat (MAC + name)
  └── Unassign bat

Reports
  ├── Export academy report (CSV / PDF)
  ├── Top performing players this month
  ├── Most improved players
  └── Usage stats (sessions per bat, sessions per player)

Billing & Subscription
  ├── Current plan, expiry date
  ├── Upgrade plan
  └── Invoice history
```

---

## 6. BLE CONNECTIVITY — DETAILED SPEC

### 6.1 BLE Service
- Service UUID: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E` (Nordic UART)
- TX Characteristic (ESP32→App): `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` — NOTIFY
- RX Characteristic (App→ESP32): `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` — WRITE

### 6.2 Flutter BLE Library
- **flutter_blue_plus** (primary)
- Handle: scan → find by name "KnoQ-Bat-V1" → connect → discover services → subscribe to TX notify characteristic → parse JSON on each notification

### 6.3 Connection State Machine
```
DISCONNECTED
  → user taps "Scan" → SCANNING
  → device found → CONNECTING
  → connected + services discovered → CONNECTED
  → BLE drops → AUTO_RECONNECT (3 retries, 2s apart)
  → retries exhausted → DISCONNECTED (show toast)

During active session:
  → BLE drop → show warning banner, keep session running locally
  → reconnect → resume streaming, no data lost
```

### 6.4 Commands App Sends to Bat (RX)
```json
{"cmd": "calibrate"}     // reset baseline on ESP32
{"cmd": "reset_session"} // clear session counters on ESP32
{"cmd": "get_battery"}   // request battery level (future)
```

### 6.5 Data Integrity
- Each shot has a `hit` sequence number from ESP32
- App checks for gaps in sequence numbers — if gap detected, mark those shots as "missing" in Firestore rather than fabricating data
- Duplicate sequence numbers (from BLE retry) are deduplicated by sequence number

### 6.6 MTU Negotiation & JSON Fragmentation

```
After BLE connection established:
  1. Request MTU 512 bytes
  2. If denied → fall back to default (23 bytes)
  3. If negotiated MTU < 100 → warn: JSON may be fragmented

JSON fragmentation handling:
  - ESP32 JSON packets can exceed MTU (especially session summaries)
  - App MUST buffer incoming BLE notifications
  - Assemble complete JSON by looking for newline delimiter (\n)
  - Only parse when complete line received
  - If buffer exceeds 1KB without newline → flush and log error

Implementation:
  StringBuffer _bleBuffer = StringBuffer();

  void onBleData(List<int> data) {
    String chunk = String.fromCharCodes(data);
    _bleBuffer.write(chunk);
    String full = _bleBuffer.toString();
    if (full.contains('\n')) {
      List<String> lines = full.split('\n');
      for (var line in lines.sublist(0, lines.length - 1)) {
        if (line.trim().isNotEmpty) _processJson(line.trim());
      }
      _bleBuffer = StringBuffer(lines.last);
    }
  }
```

### 6.7 Reconnection Strategy

```
1. Detect disconnect via onDisconnect callback
2. If during active session:
   a. Show persistent "Reconnecting..." banner (yellow)
   b. Continue session locally (Hive keeps recording)
   c. Wait 1 second, then attempt reconnect
   d. Retry up to 3 times, 2 seconds apart
   e. If all fail → show "Reconnect" button + keep session alive
   f. On manual reconnect → re-subscribe to TX characteristic
   g. Verify shot sequence number continuity after reconnect
3. If NOT during session:
   a. Show toast "Bat disconnected"
   b. Update connection status pill on home screen
   c. Do NOT auto-reconnect (user must tap "Connect" again)
```

---

## 7. COACHING INSIGHTS ENGINE (V1 — Rule-Based)

All insights are generated client-side from session data. No ML in V1.

### 7.1 Insight Rules

```dart
// Zone bias insights
if (leftPct > 40%)  → "You are hitting left zone heavily ({leftPct}%).
                        Check your front foot alignment at impact."

if (rightPct > 40%) → "Right zone bias detected ({rightPct}%).
                        Focus on keeping bat face square at contact."

if (bottomPct > 25%) → "Frequent toe hits ({bottomPct}%).
                         Try moving hands slightly down the grip."

if (topPct > 30%)   → "Hitting top of bat ({topPct}%).
                        Watch the ball longer — head may be lifting early."

// Sweet spot insights
if (sweetPct > 70%)      → "Excellent sweet spot accuracy! Consistent middle hitting."
if (sweetPct 50–70%)     → "Good contact. Focus on footwork to improve further."
if (sweetPct 30–50%)     → "Room to improve. Try slowing your swing and watching the ball."
if (sweetPct < 30%)      → "Low sweet spot contact. Prioritise technique over power."

// Power insights
if (avgPower > 80%)      → "Very powerful hitting. Focus on accuracy now."
if (avgPower < 40%)      → "Low power output. Ensure full follow-through on every shot."
if (powerStdDev > 25)    → "Inconsistent power. Focus on repeatable swing mechanics."

// Trend insights (cross-session, needs 3+ sessions)
if (sweetPct improving over last 3 sessions)
  → "Sweet spot % improving week on week. Great progress!"
if (avgPower declining over last 3 sessions)
  → "Power trending down over recent sessions. Check for fatigue or grip."

// Session length insight
if (totalHits > 50 && lastQuarterAvgPower < firstQuarterAvgPower * 0.8)
  → "Power drops significantly in the last quarter. Consider shorter, focused sessions."
```

### 7.2 Insight Priority
- Maximum 3 insights shown per session (most impactful first)
- Each insight has: title (short), detail (1 sentence), suggested action (1 sentence)
- Insights are stored with the session in Firestore so coach can see what the player was shown

### 7.3 Consistency Score Formula
```
consistencyScore = 100 - (zoneEntropyScore + powerStdDevNormalized)

zoneEntropyScore = measures how spread shots are across zones (0=all same zone, 50=all different)
powerStdDevNormalized = stdDev of power values normalized to 0–50

Range: 0–100. Above 70 = consistent. Below 40 = inconsistent.
```

### 7.4 Minimum Data Requirements
- **< 5 shots in session:** Do not generate insights. Show "Play more shots for insights."
- **< 3 sessions total:** Do not generate trend insights. Show "Complete 3 sessions to see trends."
- **All insights are non-blocking:** UI renders immediately, insights compute in background.

---

## 8. UI/UX SPECIFICATION

### 8.1 Design Principles
- Dark theme primary (outdoor cricket visibility, OLED battery saving)
- Light theme option in settings
- Large, readable numbers — minimum 32px for key metrics
- One primary action per screen — no cognitive overload during play
- Live Session screen must be operable with ONE hand, gloves on

### 8.2 Color System
```
Primary:     #00C853  (cricket green — positive, energy)
Secondary:   #1565C0  (deep blue — data, trust)
Background:  #0D0D0D  (near-black)
Surface:     #1A1A1A  (card background)
Error:       #FF5252
Warning:     #FFB300
Success:     #00C853
Text primary: #FFFFFF
Text secondary: #9E9E9E

Zone colors:
  Sweet:  #00C853 (green)
  Top:    #2196F3 (blue)
  Left:   #FF9800 (orange)
  Right:  #9C27B0 (purple)
  Bottom: #F44336 (red)
```

### 8.3 Key UI Components

**Bat Zone Diagram (Live Session):**
- SVG bat outline, divided into 5 zones
- Last hit zone illuminates in zone color
- Fades back to neutral after 2 seconds
- Sweet zone pulses briefly on sweet hit

**Power Arc:**
- Circular arc from 0–100
- Color: green (>70), orange (40–70), red (<40)
- Animates from 0 to value in 300ms on each hit

**Zone Distribution Chart:**
- Donut chart with zone colors
- Tappable segments show exact % and count

**Power Trend Chart:**
- Line chart, x-axis = shot number, y-axis = power 0–100
- Horizontal reference line at session average
- Highlight sweet spot hits as green dots on line

### 8.4 Animations
- Hit received → brief haptic + card slides in from bottom
- Sweet spot hit → green flash overlay on screen (0.3s)
- New personal best → confetti animation + banner

### 8.5 Accessibility
- All text minimum 14sp
- All interactive elements minimum 48×48dp touch target
- Color is never the only differentiator — zone icons accompany zone colors
- Screen reader labels on all interactive elements

---

## 9. NOTIFICATIONS

### 9.1 In-App Notifications (real-time)
- Session saved confirmation
- BLE connection lost / restored
- Coach added a note to your session
- New personal best achieved
- Pending session sync reminder

### 9.2 Push Notifications (Firebase Cloud Messaging)
- "Your coach left feedback on yesterday's session"
- "Weekly summary: Your sweet spot % this week was X%"
- "You haven't practiced in 5 days — time to hit the nets?"
- Academy admin: "3 new players joined your academy"

### 9.3 Notification Permissions
- Request permission on first session end (not on app open — less intrusive)
- Granular controls in Settings (per notification type)

---

## 10. TECH STACK — COMPLETE

### 10.1 Mobile (Flutter)
```
Flutter SDK: latest stable (3.x)
State management: Riverpod (flutter_riverpod + riverpod_annotation)
Navigation: GoRouter (go_router)
BLE: flutter_blue_plus
Local DB: Hive (hive_flutter)
Charts: fl_chart
Auth: firebase_auth
Firestore: cloud_firestore
Storage: firebase_storage (profile images)
FCM: firebase_messaging
Crash reporting: firebase_crashlytics
Analytics: firebase_analytics
PDF export: pdf
Share: share_plus
Permissions: permission_handler
Connectivity: connectivity_plus
Wakelock: wakelock_plus
Image picker: image_picker
Remote config: firebase_remote_config
```

### 10.2 Backend (Firebase)
```
Firebase Auth — authentication
Firestore — primary database
Firebase Storage — profile images, exported PDFs
Firebase Cloud Functions — account deletion, push triggers, coach invite
Firebase Security Rules — enforce RBAC server-side (Section 15)
Firebase Hosting — web dashboard
Firebase Remote Config — feature flags
```

### 10.3 Web Dashboard (Coach + Admin)
```
Framework: Flutter Web (same codebase, responsive layout) for V1
Migration path: React + TypeScript for V2 if complex table UX needed
```

### 10.4 Future Backend Services
```
Node.js / Go — custom API when Firebase costs scale
PostgreSQL — relational data for complex analytics queries
ML service — shot classification, AI coaching (V2/V3)
```

---

## 11. FLUTTER PROJECT STRUCTURE

```
lib/
├── main.dart
├── main_dev.dart                     # Dev flavor entry point
├── main_prod.dart                    # Prod flavor entry point
├── app.dart                          # MaterialApp, theme, router
├── firebase_options.dart             # Generated by FlutterFire CLI
│
├── core/                             # Shared utilities
│   ├── constants/
│   │   ├── app_colors.dart           # Color system from §8.2
│   │   ├── app_typography.dart       # Text styles, font sizes
│   │   ├── ble_constants.dart        # UUIDs, device name, timeout values
│   │   └── firestore_paths.dart      # Collection/field name string constants
│   ├── errors/
│   │   ├── app_exceptions.dart       # Custom exception classes
│   │   └── error_handler.dart        # Global error handler + Crashlytics
│   ├── extensions/                   # Dart extensions (String, DateTime, etc.)
│   ├── utils/
│   │   ├── validators.dart           # Email, password, academy code validation
│   │   └── formatters.dart           # Date, percentage, power display formatting
│   └── widgets/                      # Shared UI components
│       ├── knoq_button.dart
│       ├── zone_badge.dart
│       ├── power_arc.dart
│       ├── bat_zone_diagram.dart
│       ├── loading_overlay.dart
│       ├── empty_state.dart
│       ├── error_state.dart
│       └── shimmer_skeleton.dart
│
├── features/                         # Feature-based modules
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_repository.dart
│   │   │   └── user_repository.dart
│   │   ├── domain/
│   │   │   └── user_model.dart
│   │   ├── presentation/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   ├── onboarding_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   └── providers/
│   │       └── auth_provider.dart
│   │
│   ├── ble/
│   │   ├── data/
│   │   │   ├── ble_repository.dart       # Scan, connect, subscribe, send
│   │   │   ├── shot_parser.dart          # JSON parsing + validation
│   │   │   └── mock_ble_repository.dart  # For testing without hardware
│   │   ├── domain/
│   │   │   ├── ble_state.dart            # Connection state enum
│   │   │   └── shot_data.dart            # Shot model
│   │   └── providers/
│   │       └── ble_provider.dart
│   │
│   ├── session/
│   │   ├── data/
│   │   │   ├── session_repository.dart       # Firestore CRUD
│   │   │   └── local_session_store.dart      # Hive write-ahead log
│   │   ├── domain/
│   │   │   ├── session_model.dart
│   │   │   └── session_stats.dart
│   │   ├── presentation/
│   │   │   ├── ble_scan_screen.dart
│   │   │   ├── live_session_screen.dart
│   │   │   ├── session_summary_screen.dart
│   │   │   └── shot_history_screen.dart
│   │   └── providers/
│   │       └── session_provider.dart
│   │
│   ├── analytics/
│   │   ├── data/
│   │   │   └── analytics_repository.dart
│   │   ├── domain/
│   │   │   └── analytics_model.dart
│   │   ├── presentation/
│   │   │   └── analytics_dashboard_screen.dart
│   │   └── providers/
│   │       └── analytics_provider.dart
│   │
│   ├── insights/
│   │   ├── data/
│   │   │   └── insight_engine.dart         # Rule-based engine
│   │   ├── domain/
│   │   │   └── insight_model.dart
│   │   └── presentation/
│   │       └── coaching_insights_screen.dart
│   │
│   ├── coach/
│   │   ├── presentation/
│   │   │   ├── coach_dashboard_screen.dart
│   │   │   ├── player_detail_screen.dart
│   │   │   ├── compare_players_screen.dart
│   │   │   └── session_detail_coach_screen.dart
│   │   └── providers/
│   │       └── coach_provider.dart
│   │
│   ├── home/
│   │   └── presentation/
│   │       ├── player_home_screen.dart
│   │       └── widgets/                    # Home-specific widgets
│   │
│   └── profile/
│       └── presentation/
│           ├── profile_screen.dart
│           └── settings_screen.dart
│
├── routing/
│   ├── app_router.dart                     # GoRouter config + all routes
│   └── route_guards.dart                   # Role-based redirect logic
│
└── services/                               # App-level services
    ├── local_storage_service.dart           # Hive init + helpers
    ├── notification_service.dart            # FCM setup + handlers
    ├── analytics_service.dart              # Firebase Analytics event wrappers
    ├── crash_reporting_service.dart        # Crashlytics setup
    └── connectivity_service.dart           # Internet + BLE availability
```

---

## 12. STATE MANAGEMENT ARCHITECTURE (Riverpod)

### 12.1 Provider Patterns

```dart
// 1. Auth State — StreamProvider (reacts to Firebase auth changes)
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 2. User Profile — FutureProvider.family (fetch once, cache)
final userProfileProvider = FutureProvider.family<UserModel, String>((ref, uid) {
  return ref.read(userRepositoryProvider).getUser(uid);
});

// 3. Current User Profile — auto-watches auth state
final currentUserProvider = FutureProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.value?.uid;
  if (uid == null) return null;
  return ref.read(userRepositoryProvider).getUser(uid);
});

// 4. BLE Connection — StateNotifierProvider (complex state machine)
final bleProvider = StateNotifierProvider<BleNotifier, BleState>((ref) {
  return BleNotifier();
});

// 5. Live Session — StateNotifierProvider (accumulates shots real-time)
final liveSessionProvider = StateNotifierProvider<LiveSessionNotifier, LiveSessionState>((ref) {
  return LiveSessionNotifier(
    bleNotifier: ref.read(bleProvider.notifier),
    localStore: ref.read(localSessionStoreProvider),
  );
});

// 6. Session History — FutureProvider (paginated Firestore query)
final sessionHistoryProvider = FutureProvider<List<SessionModel>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return [];
  return ref.read(sessionRepositoryProvider).getSessions(uid, limit: 20);
});

// 7. Analytics — FutureProvider.family (by time range)
final analyticsProvider = FutureProvider.family<AnalyticsModel, String>((ref, timeRange) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) throw Exception('Not authenticated');
  return ref.read(analyticsRepositoryProvider).getAnalytics(uid, timeRange);
});
```

### 12.2 Rules

- **Never** put BLE logic in a Widget — always in a provider/notifier
- **Never** call Firestore directly from a screen — always through a repository
- **Repositories** are provided via `Provider` (dependency injection)
- Use `ref.invalidate()` to refresh data after session save
- Dispose BLE subscription when provider is disposed
- All providers that hold state must have proper `dispose()` cleanup

---

## 13. SESSION RECOVERY & CRASH SAFETY

**Problem:** If the app crashes during a live session, the player loses all shot data. This destroys trust.

**Solution: Write-ahead logging to Hive**

### 13.1 During Active Session

```
On every shot received from BLE:
  1. Write shot to Hive immediately (< 1ms, synchronous)
  2. Update in-memory state for UI rendering
  3. Never depend solely on in-memory state

On session end (normal):
  1. Batch write all shots to Firestore
  2. Clear Hive active_session box
  3. Mark session as "completed"
```

### 13.2 On App Launch — Recovery Check

```
On app startup:
  1. Check Hive 'active_session' box for 'is_active' flag
  2. If is_active == true:
     → Show recovery dialog:
       "It looks like your last session didn't end properly.
        We saved [X] shots. Would you like to recover them?"
     → "Recover" → Load shots from Hive → show Session Summary
     → "Discard" → Clear Hive → start fresh
  3. If is_active == false → normal startup
```

### 13.3 Hive Schema for Active Session

```
Box: 'active_session'

Key 'session_meta': {
  sessionId: string (UUID, generated at session start),
  startTime: int (millisecondsSinceEpoch),
  deviceId: string,
  playerId: string,
}

Key 'shots': List<Map<String, dynamic>> [
  { shotNumber: 1, zone: "sweet", power: 72, swing: 120.5, timestamp: ... },
  { shotNumber: 2, zone: "left",  power: 65, swing: 98.0,  timestamp: ... },
  ...
]

Key 'is_active': bool (true while session is running)
```

---

## 14. ANDROID PERMISSIONS FLOW

### 14.1 Required Permissions by Android Version

```
Android < 12 (API < 31):
  Required: ACCESS_FINE_LOCATION
  Auto-granted: BLUETOOTH, BLUETOOTH_ADMIN

Android 12+ (API 31+):
  Required: BLUETOOTH_SCAN, BLUETOOTH_CONNECT
  NOT required: ACCESS_FINE_LOCATION (if neverForLocation flag set)

All versions:
  Location services must be ENABLED (not just permitted)
  Bluetooth adapter must be ON
```

### 14.2 AndroidManifest.xml Additions

```xml
<!-- BLE permissions -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation"
    tools:targetApi="s" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<!-- BLE requirement -->
<uses-feature android:name="android.hardware.bluetooth_le"
    android:required="true" />

<!-- Keep BLE alive during session -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### 14.3 Permission Request Flow in App

```
When user taps "Start Session":
  1. Check Bluetooth adapter → OFF? → show "Enable Bluetooth" prompt
  2. Check BLE permissions:
     - Not requested yet → show explanation dialog FIRST, then request
     - Denied → show explanation + "Go to Settings" button
     - Permanently denied → show "Open App Settings" with instructions
  3. Check Location services (Android <12) → OFF? → prompt to enable
  4. All granted → proceed to BLE Scan screen

Explanation dialog text:
  "KnoQ needs Bluetooth to connect to your Smart Bat.
   This permission is only used for bat communication,
   never for tracking your location."
```

### 14.4 OEM Battery Optimization Warning

```
After first successful session, show a one-time banner:
  "For reliable bat connection, disable battery optimization for KnoQ."
  → Link to device-specific instructions (Xiaomi, Samsung, OnePlus, etc.)
  → "Don't show again" option
  → Store dismissal in SharedPreferences
```

---

## 15. FIREBASE SECURITY RULES

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ─── Helper functions ───────────────────────────────────────
    function isAuthenticated() {
      return request.auth != null;
    }
    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }
    function isRole(role) {
      return getUserData().role == role;
    }
    function isOwner(uid) {
      return request.auth.uid == uid;
    }
    function sameAcademy(academyId) {
      return getUserData().academyId == academyId;
    }
    function isAssignedCoach(playerId) {
      return get(/databases/$(database)/documents/users/$(playerId)).data.assignedCoachId == request.auth.uid;
    }

    // ─── Users ──────────────────────────────────────────────────
    match /users/{uid} {
      allow read: if isAuthenticated() && (
        isOwner(uid) ||
        (isRole('coach') && isAssignedCoach(uid)) ||
        (isRole('admin') && sameAcademy(resource.data.academyId)) ||
        isRole('super')
      );
      // Players can update own profile but NOT role or academyId
      allow update: if isOwner(uid) &&
        !request.resource.data.diff(resource.data).affectedKeys()
          .hasAny(['role', 'academyId']);
      allow create: if isAuthenticated() && isOwner(uid);
    }

    // ─── Academies ──────────────────────────────────────────────
    match /academies/{academyId} {
      allow read: if isAuthenticated() && (
        sameAcademy(academyId) || isRole('super')
      );
      allow write: if isRole('admin') && sameAcademy(academyId);
    }

    // ─── Devices ────────────────────────────────────────────────
    match /devices/{deviceId} {
      allow read: if isAuthenticated() && (
        sameAcademy(resource.data.academyId) || isRole('super')
      );
      allow write: if isRole('admin') && sameAcademy(resource.data.academyId);
    }

    // ─── Sessions ───────────────────────────────────────────────
    match /sessions/{sessionId} {
      allow read: if isAuthenticated() && (
        resource.data.playerId == request.auth.uid ||
        (isRole('coach') && isAssignedCoach(resource.data.playerId)) ||
        (isRole('admin') && sameAcademy(resource.data.academyId)) ||
        isRole('super')
      );
      allow create: if isAuthenticated() &&
        request.resource.data.playerId == request.auth.uid;
      allow update: if isAuthenticated() &&
        resource.data.playerId == request.auth.uid;

      // ─── Shots subcollection ────────────────────────────────
      match /shots/{shotId} {
        allow read: if isAuthenticated() && (
          get(/databases/$(database)/documents/sessions/$(sessionId))
            .data.playerId == request.auth.uid ||
          isRole('coach') || isRole('admin') || isRole('super')
        );
        allow write: if isAuthenticated() &&
          get(/databases/$(database)/documents/sessions/$(sessionId))
            .data.playerId == request.auth.uid;
      }
    }

    // ─── Coach Notes ────────────────────────────────────────────
    match /coachNotes/{noteId} {
      allow read: if isAuthenticated() && (
        resource.data.playerId == request.auth.uid ||
        resource.data.coachId == request.auth.uid ||
        isRole('admin') || isRole('super')
      );
      allow create: if isRole('coach') &&
        request.resource.data.coachId == request.auth.uid;
      allow update: if resource.data.coachId == request.auth.uid;
      allow delete: if resource.data.coachId == request.auth.uid;
    }
  }
}
```

---

## 16. FIRESTORE INDEXES

Required compound indexes — queries WILL FAIL without these:

```
Collection: sessions
  Fields: playerId ASC, startTime DESC
  Purpose: Player's session history sorted by most recent

Collection: sessions
  Fields: academyId ASC, startTime DESC
  Purpose: Academy-wide session listing for admin

Collection: sessions
  Fields: playerId ASC, status ASC
  Purpose: Checking if player has an active session

Collection: coachNotes
  Fields: playerId ASC, createdAt DESC
  Purpose: Coach viewing notes for a specific player

Collection: coachNotes
  Fields: sessionId ASC, createdAt DESC
  Purpose: All notes for a specific session

Collection: users
  Fields: academyId ASC, role ASC
  Purpose: Listing all players or coaches in an academy
```

---

## 17. APP LIFECYCLE & SESSION PROTECTION

### 17.1 During Active Live Session

```
1. Keep screen ON
   → Use WakelockPlus.enable() on session start
   → WakelockPlus.disable() on session end

2. App backgrounded (home button, switch app)
   → Continue BLE subscription in background
   → Show persistent notification: "KnoQ session active — X shots recorded"
   → Use foreground service (Android) to prevent OS kill

3. Phone call interrupts
   → Pause UI updates, keep BLE alive
   → Resume UI on return to app

4. Screen locked
   → Same as backgrounded — BLE and Hive recording continue

5. App killed by OS
   → Hive has all shots via write-ahead log (Section 13)
   → On restart, offer recovery

6. Low battery warning (< 15%)
   → Show banner: "Low battery. Consider ending your session to save data."

7. "Back" button / swipe back
   → Show confirmation dialog:
     "End session? Your [X] shots will be saved."
     [Continue Playing] [End Session]
   → Use PopScope (replaces deprecated WillPopScope)
```

### 17.2 Not During Session

```
Standard app lifecycle — no special handling needed.
Hive caches survive app restart.
Firebase Auth persists session token.
```

---

## 18. ACADEMY CODE SYSTEM

### 18.1 Code Format & Generation

```
Format: 6 characters, uppercase alphanumeric [A-Z0-9]
Example: "KNQ4B2"
Generated: By system when academy is created (Cloud Function)
Storage: /academies/{id}/joinCode
Uniqueness: Enforced at creation time (query existing codes)
```

### 18.2 Validation Flow

```
Player enters code during registration or via Settings → "Join Academy":
  1. App queries Firestore: where("joinCode", "==", code.toUpperCase())
  2. If found → show academy name for confirmation
     → "Join [Academy Name]?" → [Yes] [Cancel]
     → On confirm: set user.academyId = academy.id
  3. If not found → "Invalid academy code. Contact your academy."
  4. If academy is at maxPlayers limit → "This academy is full."
```

### 18.3 Edge Cases

```
- Player registers without code → standalone mode (no academy features)
- Player wants to join academy later → Settings → "Join Academy"
- Player switches academy → not supported in V1 (contact admin)
- Code regeneration → admin can request new code (Cloud Function)
- Code does NOT expire by default
```

---

## 19. OFFLINE SYNC STRATEGY

### 19.1 Data Prioritization (When Internet Returns)

```
Priority 1: Completed sessions (user expects cloud save)
Priority 2: User profile updates
Priority 3: Shot data for synced sessions
```

### 19.2 Sync Mechanism

```
Triggers:
  1. On app launch → check Hive 'pending_sync' box
  2. On internet restored → connectivity_plus listener triggers sync
  3. On session end → attempt Firestore save immediately

Flow:
  1. Attempt Firestore write
  2. Success → clear local copy, set syncStatus = "synced"
  3. Failure → save to Hive 'pending_sync', set syncStatus = "pending"
  4. Show badge on home screen: "1 session pending sync"
  5. Retry on next trigger (see above)
  6. After 3 failed retries → set syncStatus = "failed", alert user

Conflict resolution:
  - Sessions: app-generated UUID → no conflicts possible
  - Profile: last-write-wins (acceptable for V1)
  - Coach notes: server-authoritative (coach must be online to write)
```

### 19.3 Offline Capabilities Matrix

```
✅ Start, run, and end session (BLE is local)
✅ View cached sessions (last 5)
✅ View cached profile
✅ View cached analytics (last computed)
✅ View coaching insights (generated locally from cached data)
❌ Coach features (require Firestore reads in real-time)
❌ Registration / Login (requires Firebase Auth)
❌ Push notifications (require FCM connection)
❌ Session sharing (requires internet)
```

---

## 20. NAVIGATION & ROUTING

### 20.1 GoRouter Configuration

```dart
GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final auth = ref.read(authStateProvider);
    final user = ref.read(currentUserProvider).value;
    final isLoggedIn = auth.value != null;
    final isOnAuth = state.matchedLocation.startsWith('/login') ||
                     state.matchedLocation.startsWith('/register');
    final isOnSplash = state.matchedLocation == '/splash';

    // Splash → check auth
    if (isOnSplash) return null; // splash handles its own routing

    // Not logged in → force login (except auth pages)
    if (!isLoggedIn && !isOnAuth) return '/login';

    // Logged in but on auth page → redirect to home
    if (isLoggedIn && isOnAuth) return _homeForRole(user?.role);

    // Logged in but onboarding incomplete
    if (isLoggedIn && user != null && !user.onboardingComplete &&
        state.matchedLocation != '/onboarding') {
      return '/onboarding';
    }

    // Role-based route blocking
    if (state.matchedLocation.startsWith('/coach') &&
        user?.role != 'coach' && user?.role != 'super') {
      return '/home';
    }

    return null; // no redirect
  },
);
```

### 20.2 Route Map

```
/splash                      → Splash screen
/login                       → Login screen
/register                    → Registration screen
/onboarding                  → 3-screen onboarding flow
/forgot-password             → Password reset

/home                        → Player home (or coach dashboard based on role)
/session/scan                → BLE scan screen
/session/live                → Live session screen
/session/summary/:id         → Session summary
/sessions                    → Session history list
/sessions/:id                → Session detail (player view)
/sessions/:id/shots          → Full shot history for a session
/analytics                   → Analytics dashboard
/insights                    → Coaching insights
/profile                     → Player profile
/settings                    → App settings

/coach                       → Coach dashboard
/coach/player/:id            → Player detail (coach view)
/coach/player/:id/session/:sid → Session detail (coach view)
/coach/compare               → Compare players side-by-side
```

---

## 21. SCREEN STATES — LOADING / EMPTY / ERROR

Every screen MUST implement three states beyond the happy path:

| Screen | Loading State | Empty State | Error State |
|--------|--------------|-------------|-------------|
| **Player Home** | Skeleton cards shimmer effect | "Welcome! Start your first session" + bat illustration | "Could not load data. Pull to refresh" |
| **BLE Scan** | Animated radar ripple animation | "No devices found. Is your bat powered on?" + troubleshooting tips | "Bluetooth unavailable. Check settings" + open settings button |
| **Live Session** | "Waiting for first hit..." with pulsing bat icon | N/A (always shows BLE status + stats at 0) | "Connection lost" yellow banner + auto-retry indicator |
| **Session Summary** | Charts loading with shimmer | "No shots recorded" + "Try again" button (if 0 hits) | "Failed to save. Retry / Save locally" |
| **Shot History** | List skeleton shimmer | "No shots in this session" | "Could not load shot data" |
| **Analytics** | Chart placeholders with shimmer | "Play 3+ sessions to see trends" + illustration | "Could not load analytics. Pull to refresh" |
| **Coaching Insights** | Skeleton insight cards | "Need 5+ shots for insights" | "Could not generate insights" |
| **Session History** | List skeleton shimmer | "No sessions yet. Start practicing!" + "Start Session" CTA | "Could not load history. Pull to refresh" |
| **Coach Dashboard** | Player cards shimmer | "No players assigned. Contact your admin" | "Could not load players. Pull to refresh" |
| **Player Detail (coach)** | Profile + charts shimmer | "This player has no sessions yet" | "Could not load player data" |
| **Profile** | Avatar + fields shimmer | N/A (always has data from auth) | "Could not load profile. Pull to refresh" |
| **Settings** | Skeleton toggles | N/A | "Could not load settings" |

### Implementation Pattern

```dart
// Use AsyncValue from Riverpod for clean state handling:
ref.watch(sessionHistoryProvider).when(
  loading: () => ShimmerSkeleton(),
  error: (e, st) => ErrorState(message: "Could not load history", onRetry: () => ref.invalidate(sessionHistoryProvider)),
  data: (sessions) => sessions.isEmpty
    ? EmptyState(message: "No sessions yet", action: "Start Session")
    : SessionList(sessions: sessions),
);
```

---

## 22. ANALYTICS & EVENT TRACKING

### 22.1 Auth Events

```dart
'sign_up'              → {method: 'email'|'google', has_academy: bool}
'login'                → {method: 'email'|'google'}
'onboarding_complete'  → {batting_hand: str, age: int, has_academy: bool}
'logout'               → {}
'account_deleted'      → {}
```

### 22.2 Session Events

```dart
'session_started'      → {device_id: str}
'shot_received'        → {zone: str, power: int, shot_number: int}
'session_ended'        → {total_hits: int, duration_s: int, sweet_pct: int, avg_power: int}
'session_saved'        → {destination: 'firestore'|'local', shot_count: int}
'session_recovered'    → {shot_count: int}
'session_discarded'    → {shot_count: int}
```

### 22.3 BLE Events

```dart
'ble_scan_started'     → {}
'ble_device_found'     → {device_name: str, rssi: int}
'ble_connected'        → {connect_time_ms: int}
'ble_disconnected'     → {during_session: bool, reason: str}
'ble_reconnected'      → {attempt_number: int}
'ble_permission_denied'→ {permission: str, permanent: bool}
```

### 22.4 Feature Usage Events

```dart
'analytics_viewed'     → {time_range: str}
'insight_viewed'       → {insight_type: str, insight_title: str}
'session_shared'       → {method: str}
'profile_edited'       → {fields_changed: [str]}
'academy_joined'       → {academy_id: str}
'settings_changed'     → {setting: str, new_value: str}
```

### 22.5 Coach Events

```dart
'player_viewed'        → {coach_id: str}
'note_added'           → {tags: [str]}
'players_compared'     → {}
'report_exported'      → {format: 'pdf'|'csv'}
```

---

## 23. PERFORMANCE REQUIREMENTS

| Metric | Requirement | How to Achieve |
|--------|-------------|----------------|
| BLE data → UI update | < 100ms | Process JSON on isolate if needed; direct state update |
| App cold start | < 3 seconds | Lazy-load non-critical providers; cache user profile in Hive |
| Session save to Firestore | < 2 seconds on 4G | Batch write shots; use Firestore batch API (max 500 ops) |
| Chart render (100 shots) | < 500ms | fl_chart handles this natively; pre-compute data points |
| Offline session support | Full functionality | Hive write-ahead log; BLE is inherently local |
| Max session shots stored locally | 500+ without degradation | Hive handles 10K+ lightweight objects (~200 bytes/shot) |
| Simultaneous BLE + Firestore | No dropped BLE packets | BLE runs on separate stream; Firestore writes are async |
| Session history list scroll | 60fps | Paginate (20 per page); use ListView.builder |
| Memory during live session | < 150MB | Limit shot history widget to last 5; don't hold all charts in memory |

---

## 24. ERROR HANDLING & EDGE CASES

### 24.1 BLE Edge Cases
- Bat not found in scan → "Make sure bat is powered on and within 5 metres"
- BLE drops mid-session → Save locally, show reconnecting banner, auto-retry (Section 6.7)
- Malformed JSON from ESP32 → Log error to Crashlytics, skip shot, do not crash
- Duplicate shot sequence → Deduplicate silently by sequence number
- Battery low on bat (future) → Show warning at <20%
- Multiple KnoQ bats in range → Show list, let user choose
- BLE notification overflows buffer → Flush buffer, log warning

### 24.2 Data Edge Cases
- Session ended with 0 hits → Do not save, show "No shots recorded"
- Player has no sessions yet → Show empty state with "Start your first session" CTA
- Coach has no assigned players → Show "No players assigned yet, contact your admin"
- Insight engine with < 5 shots → Do not show insights, show "Play more shots for insights"
- Firestore write exceeds 500 ops in batch → Split into multiple batches
- Shots exceeds 500 in single session → Continue recording (Hive handles it); paginate Firestore writes

### 24.3 Auth Edge Cases
- Token expired mid-session → Refresh silently, never interrupt live session
- Wrong academy code on registration → Clear error message, retry
- Coach tries to access unassigned player → Firestore rule blocks + app shows "Access denied"
- Email not verified → Block session start, show "Verify your email first"
- Account deleted while logged in → Next API call fails → force logout with explanation

### 24.4 Network Edge Cases
- Internet lost during session save → Save locally, sync later (Section 19)
- Firestore quota exceeded → Show "Service temporarily unavailable. Data saved locally."
- Firebase Auth service down → Show cached profile, block login-dependent actions
- Slow network (>5s response) → Show timeout message + retry button

### 24.5 App Crash Recovery
- Crash during live session → Hive write-ahead log preserves all shots (Section 13)
- Crash during Firestore sync → Hive still has data; retry on next launch
- Crash during onboarding → Check `onboardingComplete` flag on restart, resume flow

---

## 25. TESTING STRATEGY

### 25.1 Unit Tests (Target: 80% coverage on business logic)

```
test/
├── features/
│   ├── insights/
│   │   └── insight_engine_test.dart     # All 10+ rules with edge cases
│   ├── ble/
│   │   └── shot_parser_test.dart        # Valid JSON, malformed, missing fields, fragmented
│   ├── session/
│   │   ├── session_stats_test.dart      # Averages, percentages, empty sessions
│   │   └── local_session_store_test.dart # Hive write/read/recovery
│   ├── analytics/
│   │   └── analytics_model_test.dart    # Consistency score, zone entropy
│   └── auth/
│       └── validators_test.dart         # Email, password, academy code validation
```

### 25.2 Widget Tests

```
test/
├── core/
│   └── widgets/
│       ├── bat_zone_diagram_test.dart   # Correct zone highlight for each zone
│       ├── power_arc_test.dart          # Correct color at boundaries (39→red, 40→orange, 70→orange, 71→green)
│       ├── zone_badge_test.dart         # Correct color and icon per zone
│       └── empty_state_test.dart        # Renders message and action button
├── features/
│   └── session/
│       └── live_session_screen_test.dart # Shot card appears on mock BLE data
```

### 25.3 Integration Tests

```
integration_test/
├── auth_flow_test.dart              # Register → onboard → home
├── session_flow_test.dart           # Scan → connect (mock) → shots → end → summary
└── coach_flow_test.dart             # Login → see players → view session → add note
```

### 25.4 Test Infrastructure

```
Mock BLE service:
  - mock_ble_repository.dart emits predefined shot sequences
  - Configurable: normal flow, disconnect mid-session, malformed JSON

Mock Firestore:
  - Use fake_cloud_firestore package
  - Pre-populate with test data for each role

CI/CD:
  - GitHub Actions / Codemagic
  - Run unit + widget tests on every PR
  - Run integration tests on merge to main
  - Build APK on release tag
```

---

## 26. BUILD FLAVORS & ENVIRONMENT CONFIG

### 26.1 Flavors

```
dev       → Firebase dev project, verbose logging, mock BLE available
staging   → Firebase staging project, real BLE, test analytics
prod      → Firebase production project, crash reporting, real analytics
```

### 26.2 Environment Config (per flavor)

```dart
class AppConfig {
  final String firebaseProjectId;
  final String bleDeviceNameFilter;   // "KnoQ-Bat-V1" vs "KnoQ-Bat-DEV"
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final bool enableMockBle;           // true only in dev
  final LogLevel logLevel;            // verbose / info / error
}
```

### 26.3 Launch Commands

```bash
# Development (with mock BLE)
flutter run --flavor dev --target lib/main_dev.dart

# Staging (real BLE, test Firebase)
flutter run --flavor staging --target lib/main_staging.dart

# Production
flutter run --flavor prod --target lib/main_prod.dart

# Build release APK
flutter build apk --flavor prod --target lib/main_prod.dart --release
```

### 26.4 Firebase Project Setup

```
Firebase projects:
  knoq-dev     → development
  knoq-staging → staging / QA
  knoq-prod    → production

Each has separate:
  - Firestore database
  - Auth user pool
  - Storage bucket
  - Security rules (same code, deployed separately)
```

---

## 27. SECURITY & PRIVACY

- All data in transit: HTTPS + Firebase TLS (automatic)
- All data at rest: Firestore encryption (automatic)
- Player age < 18: parental consent flow (future — flag for now)
- Data deletion: player can request full account + data deletion from Settings (triggers Cloud Function)
- DPDP Act (India) compliance: privacy policy, consent on registration, data minimization
- No sensor raw data (S1, S2, S3) stored in production Firestore — only processed metrics
- Coach cannot download raw video of players (future feature must go through consent flow)
- Firebase Security Rules enforce all access control server-side (Section 15)
- Rate limiting on auth operations (Firebase built-in)
- API keys restricted to package name (Firebase console → API restrictions)

---

## 28. MONETIZATION HOOKS

Build infrastructure now, don't show UI yet:

- `plan` field on academy document gates features in Firestore rules
- Premium features flagged in code with `isPremium` check (returns false for all in V1)
- Usage counters on sessions, players, coaches — needed for plan enforcement later
- Firebase Remote Config for feature flags (turn features on/off without app update)
- `maxPlayers` and `maxCoaches` on academy document — enforce limits in security rules
- Track analytics events for feature usage — inform pricing decisions

---

## 29. USER FLOW — COMPLETE

```
New Player:
  Download app → Splash → Register (email + academy code) → Verify email
  → Onboarding (name, age, hand, academy) → Home
  → Tap "Start Session" → Permissions check → BLE Scan → Connect bat
  → Live Session (hit shots, see real-time data)
  → End Session → Session Summary (insights, charts)
  → View Analytics → View Coaching Insights → Profile

Returning Player:
  Open app (auto-login) → Splash → Home (last session shown)
  → Start Session → (bat auto-reconnects if in range) → Play
  → End Session → Summary → Done

Crash Recovery:
  Open app → Splash → "Recover session?" dialog
  → Recover → View Summary of recovered session → Done

Offline Player:
  Open app (cached login) → Home (cached data)
  → Start Session → BLE Scan → Connect → Play (fully offline)
  → End Session → Save locally → "Will sync when online" badge
  → Internet returns → auto-sync → badge clears

Coach:
  Login → Coach Dashboard → Tap player → View analytics
  → Tap session → View shots → Add note → Done

Academy Admin (Web):
  Login → Overview → Player management → Assign coach
  → View reports → Export CSV → Done
```

---

## 30. MVP SCOPE & BUILD ORDER

### 30.1 V1 — Ship This

- Player login / register / onboarding
- BLE scan + connect + live session screen
- Shot data parsing + real-time zone + power display
- Session save to Firestore (with local fallback)
- Session recovery from crash
- Basic analytics (zone pie, power line, sweet%)
- Rule-based coaching insights (5 core rules)
- Player profile + session history
- Coach login + player list + session view

### 30.2 V1.5 — Next Sprint

- Academy admin web dashboard
- Coach notes on sessions
- Push notifications
- PDF export
- Offline sync (full Hive strategy)
- Compare players (coach view)

### 30.3 V2 — After Validation

- Camera integration + pose estimation
- Shot type classification (cover drive, pull shot, etc.)
- AI coaching (ML-based insights)
- Drill assignments from coach
- Multiplayer / leaderboards
- White-label for academies

### 30.4 Do NOT Build in V1

- Any ML or camera features
- Social features (sharing, leaderboards)
- Payment / billing UI (handle manually for first 10 academies)
- OTA firmware update from app
- Multiple bat support per session

### 30.5 Sprint-Based Build Order

```
Sprint 1 (Week 1-2): Foundation
  ├── Flutter project creation (structure, flavors, dependencies)
  ├── Firebase project setup (Auth, Firestore, deploy security rules)
  ├── Theme & design system implementation (colors, typography, shared widgets)
  ├── Auth screens (login, register, forgot password)
  ├── Onboarding flow (3 screens)
  └── Hive initialization + local storage service

Sprint 2 (Week 3-4): Core BLE
  ├── BLE service layer (scan, connect, disconnect, state machine)
  ├── Android permissions flow (Bluetooth + Location)
  ├── Shot JSON parser with validation + fragmentation handling
  ├── Mock BLE service for testing without hardware
  ├── BLE scan screen (with radar animation)
  └── Unit tests: shot parser, validators

Sprint 3 (Week 5-6): Live Session
  ├── Live session screen (bat zone diagram, power arc, stats bar, shot list)
  ├── Session recovery via Hive write-ahead log
  ├── Wakelock + PopScope lifecycle handling
  ├── Session end → summary screen (charts, insights)
  ├── Firestore session save (with local fallback)
  └── Widget tests: bat zone diagram, power arc

Sprint 4 (Week 7-8): Analytics & Insights
  ├── Session history screen (paginated from Firestore)
  ├── Analytics dashboard (zone donut, power trend, sweet% trend, consistency gauge)
  ├── Coaching insights engine (all V1 rules)
  ├── Player home screen (quick stats, recent sessions, connection pill)
  ├── Profile screen + settings screen
  └── Unit tests: insight engine, consistency score

Sprint 5 (Week 9-10): Coach & Polish
  ├── Coach dashboard + player detail screen
  ├── Coach session view + note adding
  ├── Loading / empty / error states on ALL screens
  ├── Offline sync strategy (pending sync badge, auto-retry)
  ├── Analytics event tracking (all events from Section 22)
  └── Firebase Security Rules testing + deployment

Sprint 6 (Week 11-12): Testing & Launch Prep
  ├── Integration tests (auth flow, session flow, coach flow)
  ├── Performance testing with 100+ shots in a session
  ├── Real hardware testing (connect to actual KnoQ bat)
  ├── Bug fixes + UI polish
  ├── Play Store listing prep (screenshots, description, privacy policy)
  └── Production build + release
```

---

## 31. DEFINITION OF DONE

A screen is "done" when:
- Renders correctly on Android (min SDK 26 / Android 8)
- Works fully offline where applicable
- All three states handled: loading, empty, error (in addition to happy path)
- Role-based access enforced (player cannot reach coach screens)
- Data persists correctly to Firestore and survives app restart
- Crash during usage does not lose data (Hive write-ahead for session screens)
- No crashes on the happy path or on the 3 most common error paths
- Analytics events fire correctly for all user actions on the screen
- Reviewed against this spec for completeness
- Unit/widget tests written for any business logic or custom widget on the screen

---

## 32. RESOLVED TECHNICAL DECISIONS

These questions from V1 are now resolved:

| # | Question | Decision | Rationale |
|---|----------|----------|-----------|
| 1 | Flutter Web vs React for admin dashboard | **Flutter Web for V1** | Single codebase, faster delivery. Migrate to React for V2 if complex table UX needed |
| 2 | Riverpod vs Bloc | **Riverpod** | Less boilerplate, better for BLE stream handling, easier testing with provider overrides |
| 3 | Session shot limit in Hive | **500+ is safe** | Hive handles 10K+ lightweight objects easily. Shots are ~200 bytes each, 500 shots = 100KB |
| 4 | Firestore read cost at scale | **Paginate from day 1** | Limit session list to 20 items, load more on scroll. Cache aggressively in Hive. At 50 players × 3 sessions/week × 30 shots = ~4,500 shot reads/week per academy |
| 5 | BLE background handling | **Foreground service** | Use foreground service during active session on Android. flutter_blue_plus supports background mode. Add OEM-specific battery optimization guidance for users (Xiaomi, Samsung, OnePlus) |
| 6 | PDF export library | **`pdf` package** | Full layout control for analytics reports. `printing` package is just a print preview wrapper. Use landscape orientation for charts. |

---

*Document version: 2.0 — KnoQ V1 Enhanced Application Specification*
*Upgraded from V1.0 with 13 new sections + 18 enhancements*
*Last updated: April 2026*
*Owner: KnoQ Product Team*