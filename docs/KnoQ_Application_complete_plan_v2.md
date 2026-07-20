# KnoQ Performance App — Complete Application Specification V2

## Enhanced Production-Ready Specification

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
- Can: register, log in, connect bat, start/end sessions, view own sessions, view own analytics, view own coaching insights, edit own profile, delete own account
- Cannot: see other players' data, access coach views, manage academy settings, export bulk data

#### Coach
- Can: log in, view all players assigned to them, view any assigned player's full session history and analytics, add notes to a player's session, create drill assignments, compare players side-by-side, export player reports (PDF)
- Cannot: see players not assigned to them, access billing, manage other coaches, delete player accounts

#### Academy Admin
- Can: log in to web dashboard + app, create and manage coach accounts, assign players to coaches, view academy-wide analytics (aggregated), manage bat device registrations, view billing and subscription status, export academy reports, regenerate academy join codes
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
- **Firebase Authentication** — token issuing only (email/password + Google OAuth)
- **JWT tokens** for API calls (Firebase ID tokens, sent in `Authorization: Bearer <token>` header on every request)
- **Role stored in PostgreSQL**, returned by the API on login via `GET /users/me`
- **Academy ID stored in PostgreSQL** — scopes all data queries server-side
- **Email verification** — required before first session (send verification email on register)

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
  - Get Firebase ID token
  - Call GET /users/me (with JWT in header)
  - API verifies JWT via Firebase Admin SDK
  - API returns user profile from PostgreSQL (role, academyId, onboardingComplete, etc.)
  - Route to correct screen:
      onboardingComplete = false → Onboarding Flow
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
- Email, password (min 8 chars, 1 uppercase, 1 number), name
- Email verification sent automatically
- Age, batting hand, academy code collected during onboarding (separate step)

**Coaches are created by Academy Admin:**
- Admin creates coach account → system sends invite email → coach sets password
- Coach cannot self-register

**Academy Admins are created by Super Admin (KnoQ team) only**

### 3.4 Session Security
- All RBAC is enforced in the Node.js API middleware — no client-side-only access checks
- A player cannot query another player's sessions even by manipulating the app
- Rate limiting enforced via Redis on Upstash (optional for V1; Firebase Auth also has built-in rate limiting at 100 requests/IP/hour)

### 3.5 Offline Handling
- If no internet: session data saves locally (Hive local DB)
- On reconnect: auto-sync to backend API (see Section 21 for detailed sync strategy)
- BLE functionality works fully offline — internet only needed for cloud sync and coach features

### 3.6 Account Deletion
- Player can request full account + data deletion from Settings
- Flow: Settings → "Delete My Account" → Confirm with password → Call `DELETE /users/me` → API deletes:
  - All sessions and shots from PostgreSQL
  - User record from PostgreSQL
  - Firebase Auth account (via Firebase Admin SDK server-side)
  - App clears local Hive data
- 30-day grace period before permanent deletion (store deletion request timestamp)
- Admin notified when a player in their academy deletes account

---

## 4. DATA ARCHITECTURE

### 4.1 Backend Architecture Overview

```
┌─────────────────────┐
│   Flutter App        │
│   (Mobile Client)    │
└──────────┬──────────┘
           │ Firebase JWT in Authorization header
           ▼
┌─────────────────────┐
│  Node.js + Express  │  ← Hosted on Render or Railway
│  REST API           │
│  (All business logic│
│   + RBAC middleware) │
└──┬──────┬───────┬───┘
   │      │       │
   ▼      ▼       ▼
┌──────┐ ┌─────┐ ┌──────────────────┐
│Postgres│ │Redis│ │Firebase Admin SDK│
│Supabase│ │Upstash│ │(JWT verify,     │
│(Primary│ │(Cache│ │ Auth management) │
│  DB)   │ │ +Rate│ │                  │
│        │ │Limit)│ │Firebase Storage  │
│        │ │      │ │(Profile images)  │
│        │ │      │ │                  │
│        │ │      │ │FCM              │
│        │ │      │ │(Push notifs)    │
└────────┘ └──────┘ └──────────────────┘
```

### 4.2 PostgreSQL Schema (Supabase)

```sql
-- ── Users ──────────────────────────────────────────────────
CREATE TABLE users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_uid    TEXT UNIQUE NOT NULL,
  name            TEXT NOT NULL,
  email           TEXT UNIQUE NOT NULL,
  role            TEXT NOT NULL CHECK (role IN ('player', 'coach', 'admin', 'super')),
  academy_id      UUID REFERENCES academies(id) ON DELETE SET NULL,
  batting_hand    TEXT CHECK (batting_hand IN ('left', 'right')),
  age             INTEGER,
  profile_image_url TEXT,
  fcm_token       TEXT,
  app_version     TEXT,
  onboarding_complete BOOLEAN DEFAULT false,
  assigned_coach_id UUID REFERENCES users(id) ON DELETE SET NULL,
  deletion_requested_at TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT now(),
  last_login_at   TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX idx_users_academy_role ON users(academy_id, role);
CREATE INDEX idx_users_coach ON users(assigned_coach_id);

-- ── Academies ──────────────────────────────────────────────
CREATE TABLE academies (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  owner_uid       UUID REFERENCES users(id),
  city            TEXT,
  state           TEXT,
  plan            TEXT DEFAULT 'starter' CHECK (plan IN ('starter', 'growth', 'enterprise')),
  plan_expires_at TIMESTAMPTZ,
  join_code       TEXT UNIQUE NOT NULL,          -- 6-char alphanumeric
  max_players     INTEGER DEFAULT 30,
  max_coaches     INTEGER DEFAULT 5,
  logo_url        TEXT,
  created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_academies_join_code ON academies(join_code);

-- ── Devices ────────────────────────────────────────────────
CREATE TABLE devices (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mac_address       TEXT UNIQUE NOT NULL,
  name              TEXT DEFAULT 'KnoQ-Bat-V1',
  academy_id        UUID REFERENCES academies(id) ON DELETE CASCADE,
  firmware_version  TEXT,
  registered_at     TIMESTAMPTZ DEFAULT now(),
  last_seen_at      TIMESTAMPTZ,
  current_assigned_to UUID REFERENCES users(id) ON DELETE SET NULL
);

-- ── Sessions ───────────────────────────────────────────────
CREATE TABLE sessions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  academy_id        UUID REFERENCES academies(id) ON DELETE SET NULL,
  device_id         UUID REFERENCES devices(id) ON DELETE SET NULL,
  start_time        TIMESTAMPTZ NOT NULL,
  end_time          TIMESTAMPTZ,
  status            TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'abandoned')),
  total_hits        INTEGER DEFAULT 0,
  sweet_spot_hits   INTEGER DEFAULT 0,
  sweet_spot_pct    REAL DEFAULT 0,
  avg_power         REAL DEFAULT 0,
  peak_power        REAL DEFAULT 0,
  avg_swing         REAL,                        -- nullable (MPU-9250 may not be connected)
  peak_swing        REAL,                        -- nullable
  zone_distribution JSONB DEFAULT '{}',          -- {sweet: N, top: N, left: N, right: N, bottom: N}
  consistency_score REAL,
  insights          JSONB DEFAULT '[]',          -- [{type, title, detail, action}, ...]
  app_version       TEXT,
  firmware_version  TEXT,
  sync_status       TEXT DEFAULT 'synced' CHECK (sync_status IN ('synced', 'pending', 'failed')),
  created_at        TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_sessions_player_time ON sessions(player_id, start_time DESC);
CREATE INDEX idx_sessions_academy_time ON sessions(academy_id, start_time DESC);
CREATE INDEX idx_sessions_player_status ON sessions(player_id, status);

-- ── Shots ──────────────────────────────────────────────────
CREATE TABLE shots (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id      UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  shot_number     INTEGER NOT NULL,
  zone            TEXT NOT NULL CHECK (zone IN ('sweet', 'top', 'left', 'right', 'bottom')),
  power           INTEGER NOT NULL CHECK (power BETWEEN 0 AND 100),
  swing           REAL,                          -- nullable (°/s from MPU-9250 gyro, null if IMU unavailable)
  timestamp       TIMESTAMPTZ DEFAULT now(),
  UNIQUE(session_id, shot_number)                -- prevent duplicate shot numbers per session
);

CREATE INDEX idx_shots_session ON shots(session_id);

-- ── Coach Notes ────────────────────────────────────────────
CREATE TABLE coach_notes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  player_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  session_id      UUID REFERENCES sessions(id) ON DELETE CASCADE,
  note            TEXT NOT NULL,
  tags            TEXT[] DEFAULT '{}',            -- {'footwork', 'timing', 'power', ...}
  created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_coach_notes_player ON coach_notes(player_id, created_at DESC);
```

### 4.3 Node.js API Endpoints

```
── Auth & Users ──────────────────────────────────────────
POST   /auth/register          → Create user in PostgreSQL after Firebase signup
GET    /users/me               → Get current user profile (from JWT)
PATCH  /users/me               → Update profile fields (name, age, batting_hand, etc.)
DELETE /users/me               → Request account deletion
GET    /users/me/stats         → Lifetime stats for current player

── Academy ───────────────────────────────────────────────
GET    /academy/lookup?code=X  → Look up academy by join code (returns name + id)
POST   /academy/join           → Player joins an academy by code
POST   /academy/leave          → Player leaves academy
GET    /academy                → Get current user's academy details
GET    /academy/players        → List all players in academy (coach/admin only)
GET    /academy/coaches        → List all coaches in academy (admin only)
POST   /academy/invite-coach   → Admin invites a coach (sends email)

── Devices ───────────────────────────────────────────────
GET    /devices                → List devices in academy
POST   /devices                → Register new device (admin only)
PATCH  /devices/:id            → Update device (assign to player, etc.)
DELETE /devices/:id            → Unregister device (admin only)

── Sessions ──────────────────────────────────────────────
POST   /sessions               → Create new session (player only)
GET    /sessions               → List sessions (own for player, assigned for coach)
GET    /sessions/:id           → Get session detail with shots
PATCH  /sessions/:id           → Update session (end session, update stats)
DELETE /sessions/:id           → Delete session (own only)

── Shots ─────────────────────────────────────────────────
POST   /sessions/:id/shots     → Batch upload shots for a session
GET    /sessions/:id/shots     → Get all shots for a session

── Coach Notes ───────────────────────────────────────────
POST   /coach-notes            → Create note (coach only)
GET    /coach-notes?player=X   → Get notes for a player
PATCH  /coach-notes/:id        → Update note (own notes only)

── Analytics ─────────────────────────────────────────────
GET    /analytics?range=7d     → Aggregated analytics for current player
GET    /analytics/player/:id   → Analytics for a specific player (coach/admin only)
GET    /analytics/academy      → Academy-wide analytics (admin only)

── Admin ─────────────────────────────────────────────────
GET    /admin/overview         → Academy dashboard stats
POST   /admin/assign-coach     → Assign player to coach
POST   /admin/regenerate-code  → Regenerate academy join code
```

### 4.4 API Authentication Middleware

```
Every request to the Node.js API:
  1. Extract JWT from Authorization: Bearer <token> header
  2. Verify JWT using Firebase Admin SDK (admin.auth().verifyIdToken(token))
  3. Extract firebase_uid from decoded token
  4. Look up user in PostgreSQL by firebase_uid
  5. Attach user object (id, role, academy_id) to request context
  6. RBAC middleware checks role against the endpoint's required permissions
  7. If unauthorized → 403 Forbidden
  8. If user not found → 401 Unauthorized (trigger re-auth on client)
```

### 4.5 Incoming BLE Data Format (from ESP32)

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

**Note on `swing` field:** This value comes from the MPU-9250 gyroscope (°/s). It may be `0`, `null`, or absent if the IMU is not connected, not wired, or not yet calibrated. The app MUST treat `swing` as nullable everywhere. If `swing` is `0` or `null`, do not display it and do not generate swing-based insights.

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

### 4.6 Local Storage (Hive)

Boxes:
- `user_cache` — User profile for instant load without API call
- `sessions_cache` — Last 5 sessions for offline analytics viewing
- `active_session` — Write-ahead log for crash recovery (see Section 20)
- `pending_sync` — Sessions and shots waiting to be synced to backend API
- `app_settings` — Theme preference (light/dark/system), notification toggles, last connected device

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
  ├── Recent sessions list
  ├── Pending sync badge (if offline sessions exist)
  └── Device connection status pill

Start Session Flow
  ├── Permission Check Screen (BLE + Location)
  ├── BLE Scan Screen (scan → find KnoQ-Bat-V1 → connect)
  ├── Pre-session check (battery level, baseline calibration status)
  └── → Live Session Screen

Live Session Screen (CORE)
  ├── Zone indicator (visual bat diagram, zone lights up)
  ├── Power meter (large number + progress arc)
  ├── Swing speed display (shown only if swing data available from MPU-9250)
  ├── Last shot card (zone + power + swing speed if available)
  ├── Running stats bar (hits / sweet% / avg power)
  ├── Shot history mini-list (last 5 shots scrolling)
  ├── End Session button
  ├── BLE status indicator
  └── BLE reconnecting banner (if disconnected)

Session Summary Screen (after End Session)
  ├── Total hits, sweet spot %, avg power, peak power
  ├── Avg swing speed (shown only if swing data was available)
  ├── Zone distribution pie chart
  ├── Power over time line chart
  ├── Coaching insight card (top 1–2 insights)
  ├── Save Session button → API sync
  └── Share button (screenshot of summary)

Shot History Screen
  ├── Full list of shots in session
  ├── Each row: shot #, zone badge, power bar, swing (if available)
  └── Filters: All / Sweet only / Weak (<40%) / Strong (>75%)

Analytics Dashboard
  ├── Time range selector (This session / Last 7 days / Last 30 days / All time)
  ├── Zone distribution pie/donut chart
  ├── Power trend line chart (per session avg)
  ├── Swing speed trend line chart (per session avg, shown only if data exists)
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
  ├── Join Academy (enter code)
  ├── Notification preferences
  ├── Theme: Light / Dark / System default
  ├── Data & privacy
  ├── Delete account
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
  ├── Trend charts (sweet%, power, swing speed over weeks)
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
  ├── All players table
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

Academy Settings
  ├── Academy join code (display + regenerate)
  ├── Academy logo
  └── Academy profile
```

### 5.4 Loading / Empty / Error States Per Screen

Every screen MUST implement these 3 states beyond the happy path:

| Screen | Loading State | Empty State | Error State |
|--------|--------------|-------------|-------------|
| **Player Home** | Skeleton cards shimmer | "Welcome! Start your first session" + illustration | "Could not load data. Pull to refresh" |
| **BLE Scan** | Animated radar/ripple | "No devices found. Is your bat powered on?" | "Bluetooth unavailable. Check settings" |
| **Live Session** | "Waiting for first hit..." pulse animation | N/A (always has BLE status) | "Connection lost" banner + retry button |
| **Session Summary** | Charts loading shimmer | "No shots recorded" (if 0 hits — do not save) | "Failed to save. Retry / Save locally" |
| **Analytics** | Chart placeholders shimmer | "Play 3+ sessions to see trends" | "Could not load analytics" |
| **Coaching Insights** | Skeleton insight cards | "Need 5+ shots for insights" | "Could not generate insights" |
| **Session History** | List skeleton shimmer | "No sessions yet. Start practicing!" + CTA | "Could not load history. Pull to refresh" |
| **Coach Dashboard** | Player cards shimmer | "No players assigned. Contact your admin" | "Could not load players" |
| **Profile** | Avatar + fields shimmer | N/A (always has data after onboarding) | "Could not load profile" |

---

## 6. BLE CONNECTIVITY — DETAILED SPEC

### 6.1 BLE Service
- Service UUID: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E` (Nordic UART)
- TX Characteristic (ESP32→App): `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` — NOTIFY
- RX Characteristic (App→ESP32): `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` — WRITE

### 6.2 Flutter BLE Library
- **flutter_blue_plus** (primary recommendation)
- Handle: scan → find by name "KnoQ-Bat-V1" → connect → discover services → subscribe to TX notify characteristic → parse JSON on each notification

### 6.3 Android Permissions Flow

**Android < 12 (API < 31):**
```
Required: ACCESS_FINE_LOCATION
Auto-granted: BLUETOOTH, BLUETOOTH_ADMIN
+ Location services must be ENABLED
```

**Android 12+ (API 31+):**
```
Required: BLUETOOTH_SCAN, BLUETOOTH_CONNECT
Optional: ACCESS_FINE_LOCATION (only if deriving location from BLE)
BLUETOOTH_SCAN must have android:usesPermissionFlags="neverForLocation"
+ Bluetooth adapter must be ON
```

**AndroidManifest.xml additions:**
```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
```

**Permission request flow in app:**
```
1. Check all required permissions
2. If not granted → show explanation dialog ("KnoQ needs Bluetooth to connect to your bat")
3. Request permission
4. If denied → show "Go to Settings" button
5. If denied permanently → open app settings directly
6. Check Location services enabled (Android < 12)
7. Check Bluetooth adapter ON (all versions)
8. If BLE not supported → show "This device doesn't support Bluetooth Low Energy"
```

**OEM Battery Optimization (Critical for Xiaomi, Samsung, OnePlus, Oppo, Vivo):**
- Show one-time guidance: "To keep the bat connected, disable battery optimization for KnoQ"
- Link to device-specific settings
- Reference: https://dontkillmyapp.com/

### 6.4 Connection State Machine
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

### 6.5 Commands App Sends to Bat (RX)
```json
{"cmd": "calibrate"}     // reset baseline on ESP32
{"cmd": "reset_session"} // clear session counters on ESP32
{"cmd": "get_battery"}   // request battery level (future)
```

### 6.6 Data Integrity
- Each shot has a `hit` sequence number from ESP32
- App checks for gaps in sequence numbers — if gap detected, mark those shots as "missing" in the database rather than fabricating data
- Duplicate sequence numbers (from BLE retry) are deduplicated by sequence number

### 6.7 MTU Negotiation & JSON Fragmentation

```
After connection established:
  1. Request MTU 512 bytes
  2. If denied → fall back to 23 bytes (BLE default)
  3. If MTU < 100 → warn: JSON may arrive in fragments

JSON Fragmentation Handling:
  ESP32 JSON strings can exceed MTU (especially session summary ~200 bytes)
  App MUST buffer incoming BLE notifications
  Assembly strategy:
    - Maintain a string buffer per connection
    - Append each incoming notification to buffer
    - Look for newline delimiter (\n) in buffer
    - When newline found → extract complete JSON line → parse
    - Keep remainder in buffer for next packet
  
  NEVER attempt to parse a partial JSON string
```

### 6.8 Reconnection Strategy (Detailed)

```
1. Detect disconnect (onDisconnect callback from flutter_blue_plus)
2. If during active session:
   a. Show "Reconnecting..." banner on live session screen
   b. Continue logging shots to Hive (local)
   c. Wait 1 second
   d. Attempt reconnect to same device (by MAC address)
   e. Retry up to 3 times, 2 seconds apart
   f. On reconnect success:
      - Re-discover services
      - Re-subscribe to TX characteristic
      - Verify shot sequence number continuity
      - Hide banner, show "Reconnected" toast
   g. On all retries failed:
      - Show "Connection lost. Tap to retry" button
      - Keep session alive locally
      - Manual retry available
3. If NOT during active session:
   a. Silent reconnect on next scan
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

// Swing speed insights (MPU-9250 gyroscope — ONLY if swing data is available)
// Skip ALL swing-based insights silently if swing is null/0 for most shots
if (hasValidSwingData && swingStdDev > 40)
  → "Your swing speed is inconsistent — varies significantly across shots.
     Focus on a repeatable swing tempo."

if (hasValidSwingData && avgSwing > 200 && sweetPct < 40%)
  → "High swing speed but low accuracy. Try slowing down for better control."

// Trend insights (cross-session, needs 3+ sessions)
if (sweetPct improving over last 3 sessions)
  → "Sweet spot % improving week on week. Great progress!"
if (avgPower declining over last 3 sessions)
  → "Power trending down over recent sessions. Check for fatigue or grip."

// Session length insight
if (totalHits > 50 && lastQuarterAvgPower < firstQuarterAvgPower * 0.8)
  → "Power drops significantly in the last quarter. Consider shorter, focused sessions."
```

### 7.2 Swing Data Availability Check

```dart
/// Determines if the session has meaningful swing data from the MPU-9250.
/// swing is nullable — the IMU may not be connected or may not be wired.
bool hasValidSwingData(List<ShotData> shots) {
  final validSwings = shots.where((s) => s.swing != null && s.swing! > 0).toList();
  // Need at least 50% of shots to have valid swing data
  return validSwings.length >= (shots.length * 0.5);
}
```

### 7.3 Insight Priority
- Maximum 3 insights shown per session (most impactful first)
- Each insight has: title (short), detail (1 sentence), suggested action (1 sentence)
- Insights are stored with the session in PostgreSQL so coach can see what the player was shown

### 7.4 Consistency Score Formula
```
consistencyScore = 100 - (zoneEntropyScore + powerStdDevNormalized)

zoneEntropyScore = measures how spread shots are across zones (0=all same zone, 50=all different)
powerStdDevNormalized = stdDev of power values normalized to 0–50

Range: 0–100. Above 70 = consistent. Below 40 = inconsistent.
```

---

## 8. UI/UX SPECIFICATION

### 8.1 Design Principles
- **Light theme is the default** on first app launch
- On first launch, app follows the **device system setting** automatically (light/dark)
- User can manually override in Settings with three options: **Light, Dark, System default**
- Manual preference is stored in Hive `app_settings` box and persists across sessions
- Both light and dark themes must be **fully designed and implemented** — no "only works in one mode" components
- **Never hardcode color hex values in widgets** — always use `Theme.of(context).colorScheme`
- Large, readable numbers — minimum 32px for key metrics
- One primary action per screen — no cognitive overload during play
- Live Session screen must be operable with ONE hand, gloves on

### 8.2 Color System (Dual Theme)

```
── Light Theme ──────────────────────────────────────────
Primary:          #00C853  (cricket green — positive, energy)
Secondary:        #1565C0  (deep blue — data, trust)
Background:       #FAFAFA  (off-white)
Surface:          #FFFFFF  (card background)
SurfaceVariant:   #F0F0F0  (secondary card / input background)
OnBackground:     #1A1A1A  (primary text on background)
OnSurface:        #1A1A1A  (primary text on surface)
OnSurfaceVariant: #6B6B6B  (secondary text)
Outline:          #E0E0E0  (borders, dividers)
Error:            #D32F2F
Warning:          #F57C00
OnPrimary:        #FFFFFF  (text on primary buttons)
OnSecondary:      #FFFFFF  (text on secondary buttons)

── Dark Theme ───────────────────────────────────────────
Primary:          #66FFA6  (lighter green for dark bg contrast)
Secondary:        #64B5F6  (lighter blue for dark bg contrast)
Background:       #0D0D0D  (near-black)
Surface:          #1A1A1A  (card background)
SurfaceVariant:   #252525  (secondary card / input background)
OnBackground:     #FFFFFF  (primary text on background)
OnSurface:        #FFFFFF  (primary text on surface)
OnSurfaceVariant: #9E9E9E  (secondary text)
Outline:          #333333  (borders, dividers)
Error:            #FF5252
Warning:          #FFB300
OnPrimary:        #0D0D0D  (text on primary buttons)
OnSecondary:      #0D0D0D  (text on secondary buttons)

── Zone Colors (same in both themes) ────────────────────
Sweet:   #00C853  (green)
Top:     #2196F3  (blue)
Left:    #FF9800  (orange)
Right:   #9C27B0  (purple)
Bottom:  #F44336  (red)

── Zone Colors on Dark Background (elevated contrast) ───
Sweet:   #69F0AE
Top:     #64B5F6
Left:    #FFB74D
Right:   #CE93D8
Bottom:  #EF5350
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

**Swing Speed Display:**
- Shown alongside power arc, smaller text: "Swing: 142°/s"
- **Only shown when swing value is non-null and > 0**
- If swing is null/0 → hide this element entirely (do not show "0°/s" or empty placeholder)

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
Flutter SDK: latest stable
State management: Riverpod
Navigation: GoRouter
BLE: flutter_blue_plus
Local DB: Hive (offline session storage + crash recovery)
Charts: fl_chart
Auth: firebase_auth (token issuing only)
HTTP client: dio (for API calls to Node.js backend)
Storage: firebase_storage (profile images only)
FCM: firebase_messaging
Crash reporting: firebase_crashlytics
Analytics: firebase_analytics
PDF export: pdf package
Share: share_plus
Permissions: permission_handler
Connectivity: connectivity_plus
Wakelock: wakelock_plus
```

### 10.2 Backend
```
Firebase Auth          — JWT token issuing + verification (via Firebase Admin SDK on server)
Node.js + Express      — REST API, all business logic, RBAC middleware (hosted on Render or Railway)
PostgreSQL (Supabase)  — Primary database for all entities (users, sessions, shots, academies, devices, coach notes)
Redis (Upstash)        — Rate limiting + response caching (optional for V1, recommended for V1.5+)
Firebase Storage       — Profile images only
FCM                    — Push notifications only
Firebase Remote Config — Feature flags (turn features on/off without app update)
```

### 10.3 Web Dashboard (Coach + Admin)
```
Framework: React + TypeScript
Hosting: Vercel
Styling: Tailwind CSS or MUI
State: React Query (TanStack Query) for data fetching
Auth: Firebase Auth (same JWT flow as mobile app)
API: Same Node.js REST API as mobile app
Separate codebase from Flutter — optimized for data tables, CSV exports, admin workflows
```

### 10.4 Future Backend Services
```
ML service — shot classification, AI coaching (V2/V3)
Video processing service — camera clip extraction + pose estimation (V2)
```

---

## 11. PERFORMANCE REQUIREMENTS

| Metric | Requirement | Strategy |
|--------|-------------|----------|
| BLE data → UI update | < 100ms | Direct stream subscription, no middleware |
| App cold start | < 3 seconds | Hive profile cache, lazy-load non-critical screens |
| Session save to backend | < 2 seconds on 4G | Batch write shots in single POST, compress payload |
| Chart render (100 shots) | < 500ms | fl_chart with pre-computed data points |
| Offline session support | Full functionality, no internet needed | Hive write-ahead log for all shots |
| Max session shots stored locally | 500 shots without performance degradation | Hive handles 10K+ lightweight objects; 500 shots ≈ 100KB |
| Simultaneous BLE + API sync | No dropped BLE packets during sync | API sync on background isolate |

---

## 12. ERROR HANDLING & EDGE CASES

### 12.1 BLE Edge Cases
- Bat not found in scan → "Make sure bat is powered on and within 5 metres"
- BLE drops mid-session → Save locally, show reconnecting banner, auto-retry (3 attempts)
- Malformed JSON from ESP32 → Log error to Crashlytics, skip shot, do not crash
- Duplicate shot sequence → Deduplicate silently by sequence number
- Battery low on bat (future) → Show warning at <20%
- BLE permission denied → explain why needed, link to settings
- Bluetooth adapter OFF → prompt to enable with dialog
- Location services OFF (Android <12) → prompt to enable
- Swing value is 0 or null from ESP32 → treat as IMU unavailable, skip swing display silently

### 12.2 Data Edge Cases
- Session ended with 0 hits → Do not save, show "No shots recorded"
- Player has no sessions yet → Show empty state with "Start your first session" CTA
- Coach has no assigned players → Show "No players assigned yet, contact your admin"
- Insight engine with < 5 shots → Do not show insights, show "Play more shots for insights"
- API returns 500 → save locally, retry with exponential backoff
- Session data too large → paginate shots (max 100 per batch POST)

### 12.3 Auth Edge Cases
- Token expired mid-session → Refresh silently (Firebase SDK auto-refresh), never interrupt live session
- Wrong academy code on registration → Clear error message, retry
- Coach tries to access unassigned player → API returns 403 + app shows "Access denied"
- Email not verified → block session start, show "Verify your email first"
- Account deleted while logged in → force logout, clear local data

### 12.4 Network Edge Cases
- No internet on app launch → load from Hive cache, show "offline" indicator
- Internet lost during session save → save locally, show "Saved locally. Will sync when online"
- Internet restored → auto-sync pending sessions (see Section 21)
- Very slow connection → show progress indicator, never timeout silently

### 12.5 App Lifecycle Edge Cases
- App crashes during session → recover from Hive on next launch (see Section 20)
- Phone call during session → continue BLE in foreground service, resume UI on return
- Screen locked during session → continue BLE, keep wakelock if user enabled
- Back button during session → confirm dialog "End session? Data will be saved"
- App killed by OS → Hive has all shots, recover on next launch

---

## 13. MVP SCOPE (WHAT TO BUILD FIRST)

### V1 — Ship this:
- Player login / register / onboarding
- BLE scan + connect + live session screen (with permissions flow)
- Shot data parsing + real-time zone + power + swing speed display (swing only if available)
- Session save to backend API (with local fallback)
- Session crash recovery (Hive write-ahead log)
- Basic analytics (zone pie, power line, swing trend if data exists, sweet%)
- Rule-based coaching insights (core rules including swing consistency if data available)
- Player profile + session history
- Coach login + player list + session view
- Loading / empty / error states on all screens

### V1.5 — Next sprint:
- Academy admin web dashboard (React + TypeScript)
- Coach notes on sessions
- Push notifications
- PDF export
- Offline sync (Hive → API queue)
- Compare players (coach view)
- Redis caching layer

### V2 — After validation:
- Camera integration + pose estimation
- Shot type classification (cover drive, pull shot, etc.)
- AI coaching (ML-based insights)
- Drill assignments from coach
- Multiplayer / leaderboards
- White-label for academies

### Do NOT build in V1:
- Any ML or camera features
- Social features (sharing, leaderboards)
- Payment / billing UI (handle manually for first 10 academies)
- OTA firmware update from app
- Multiple bat support per session

---

## 14. SECURITY & PRIVACY

- All data in transit: HTTPS (API on Render/Railway auto-provisions TLS)
- All data at rest: PostgreSQL on Supabase (encrypted at rest by default)
- All API endpoints protected by Firebase JWT verification + RBAC middleware
- Player age < 18: parental consent flow (future — flag for now)
- Data deletion: player can request full account + data deletion from Settings (see §3.6)
- DPDP Act (India) compliance: privacy policy, consent on registration, data minimization
- No sensor raw data (S1, S2, S3) stored in production — only processed metrics
- Coach cannot download raw video of players (future feature must go through consent flow)
- RBAC enforced entirely in the Node.js API middleware — never trust client-side only

---

## 15. MONETIZATION HOOKS (build infrastructure, don't show UI yet)

- `plan` field on academy table gates features in API middleware
- Premium features flagged in code with `isPremium` check (returns false for all in V1)
- Usage counters on sessions, players, coaches — needed for plan enforcement later
- Firebase Remote Config for feature flags (turn features on/off without app update)

---

## 16. USER FLOW — COMPLETE

```
New Player:
  Download app → Register (email) → Verify email
  → Onboarding (name, age, batting hand, academy code)
  → Home → Tap "Start Session" → Permission check → BLE Scan → Connect bat
  → Live Session (hit shots) → End Session → Session Summary
  → View Analytics → View Coaching Insights → Profile

Returning Player:
  Open app (auto-login) → Home (last session shown)
  → Start Session → (bat auto-reconnects if in range) → Play
  → End Session → Summary → Done

Returning Player (offline):
  Open app → Home (cached data) → Start Session → BLE connects locally
  → Live Session → End Session → Summary → "Saved locally"
  → [Later when online] → Auto-sync → "Session synced"

Crash Recovery:
  App crashes during session → Player reopens app
  → "You have an unsaved session. Recover?" → Yes → View summary
  → Save to backend → Done

Coach:
  Login → Coach Dashboard → Tap player → View analytics
  → Tap session → View shots → Add note → Done

Academy Admin (Web):
  Login → Overview → Player management → Assign coach
  → View reports → Export CSV → Done
```

---

## 17. DEFINITION OF DONE

A screen is "done" when:
- Renders correctly on Android (min SDK 26 / Android 8)
- Works fully offline where applicable
- All 3 states handled: loading, empty, error (in addition to happy path)
- Role-based access enforced (player cannot reach coach screens)
- Data persists correctly to backend and survives app restart
- No crashes on the happy path or on the 3 most common error paths
- Reviewed against this spec for completeness
- Unit tests pass for business logic in that feature
- Accessibility: all interactive elements labeled, min touch targets met

---

## 18. FLUTTER PROJECT STRUCTURE

```
lib/
├── main.dart
├── main_dev.dart                     # Dev flavor entry
├── main_prod.dart                    # Prod flavor entry
├── app.dart                          # MaterialApp, theme, router
├── firebase_options.dart             # Generated by FlutterFire CLI
│
├── core/                             # Shared utilities
│   ├── constants/
│   │   ├── app_colors.dart           # Color system from §8.2 (light + dark tokens)
│   │   ├── app_typography.dart       # Text styles
│   │   ├── ble_constants.dart        # UUIDs, device name
│   │   └── api_endpoints.dart        # API base URL + endpoint paths
│   ├── errors/
│   │   ├── app_exceptions.dart       # Custom exception classes
│   │   └── error_handler.dart        # Global error handler
│   ├── extensions/                   # Dart extensions on String, DateTime, etc.
│   ├── network/
│   │   ├── api_client.dart           # Dio instance with JWT interceptor
│   │   └── auth_interceptor.dart     # Attaches Firebase JWT to every request
│   ├── utils/
│   │   ├── validators.dart           # Email, password, academy code
│   │   └── formatters.dart           # Date, percentage, power display
│   └── widgets/                      # Shared UI components
│       ├── knoq_button.dart
│       ├── zone_badge.dart
│       ├── power_arc.dart
│       ├── swing_speed_display.dart  # Shows swing only if non-null/non-zero
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
│   │   │   └── user_repository.dart  # Calls Node.js API, not Firestore
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
│   │   │   ├── ble_repository.dart
│   │   │   ├── shot_parser.dart       # JSON parsing + validation (swing is nullable)
│   │   │   └── mock_ble_service.dart  # For testing without hardware
│   │   ├── domain/
│   │   │   ├── ble_state.dart         # Connection state enum
│   │   │   └── shot_data.dart         # Shot model (swing: double?)
│   │   └── providers/
│   │       └── ble_provider.dart
│   │
│   ├── session/
│   │   ├── data/
│   │   │   ├── session_repository.dart  # Calls Node.js API
│   │   │   └── local_session_store.dart  # Hive write-ahead log
│   │   ├── domain/
│   │   │   ├── session_model.dart
│   │   │   └── session_stats.dart
│   │   ├── presentation/
│   │   │   ├── permission_check_screen.dart
│   │   │   ├── ble_scan_screen.dart
│   │   │   ├── live_session_screen.dart
│   │   │   ├── session_summary_screen.dart
│   │   │   └── shot_history_screen.dart
│   │   └── providers/
│   │       └── session_provider.dart
│   │
│   ├── analytics/
│   │   ├── data/
│   │   │   └── analytics_repository.dart  # Calls Node.js API
│   │   ├── domain/
│   │   │   └── analytics_model.dart
│   │   ├── presentation/
│   │   │   └── analytics_dashboard_screen.dart
│   │   └── providers/
│   │       └── analytics_provider.dart
│   │
│   ├── insights/
│   │   ├── data/
│   │   │   └── insight_engine.dart    # Rule-based engine from §7 (handles nullable swing)
│   │   ├── domain/
│   │   │   └── insight_model.dart
│   │   └── presentation/
│   │       └── coaching_insights_screen.dart
│   │
│   ├── coach/                         # Coach-specific screens
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
│   │       └── widgets/
│   │
│   └── profile/
│       └── presentation/
│           ├── profile_screen.dart
│           └── settings_screen.dart
│
├── routing/
│   ├── app_router.dart               # GoRouter config with guards
│   └── route_guards.dart             # Role-based navigation guards
│
└── services/                         # App-level services
    ├── local_storage_service.dart     # Hive init + helpers
    ├── notification_service.dart      # FCM setup
    ├── analytics_service.dart         # Firebase Analytics events
    ├── crash_reporting_service.dart   # Crashlytics
    └── sync_service.dart             # Offline → API sync
```

---

## 19. STATE MANAGEMENT ARCHITECTURE (Riverpod)

### 19.1 Provider Types

```dart
// 1. Auth State — StreamProvider (reacts to Firebase auth changes)
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 2. User Profile — FutureProvider (fetch from API via GET /users/me)
final userProfileProvider = FutureProvider<UserModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return ref.read(userRepositoryProvider).getCurrentUser();
});

// 3. BLE Connection — StateNotifierProvider (complex state machine)
final bleProvider = StateNotifierProvider<BleNotifier, BleState>((ref) {
  return BleNotifier();
});

// 4. Live Session — StateNotifierProvider (accumulates shots in real-time)
final liveSessionProvider = StateNotifierProvider<LiveSessionNotifier, LiveSessionState>((ref) {
  return LiveSessionNotifier(ref.read(bleProvider.notifier));
});

// 5. Session History — FutureProvider (paginated API query)
final sessionHistoryProvider = FutureProvider<List<SessionModel>>((ref) {
  return ref.read(sessionRepositoryProvider).getSessions();
});

// 6. Analytics — FutureProvider.family (by time range, from API)
final analyticsProvider = FutureProvider.family<AnalyticsModel, String>((ref, timeRange) {
  return ref.read(analyticsRepositoryProvider).getAnalytics(timeRange);
});
```

### 19.2 Architecture Rules

- **Never** put BLE logic in a Widget — always in a provider/notifier
- **Never** call the API directly from a screen — always through a repository
- Use `ref.invalidate()` to refresh data after session save
- Dispose BLE subscription when provider is disposed
- BLE provider persists across screens (not disposed on navigation)
- Session provider creates a new instance per session
- All providers are testable with overrides in ProviderScope
- All API calls go through the `ApiClient` (Dio) which auto-attaches the Firebase JWT

---

## 20. SESSION CRASH RECOVERY

If the app crashes during a live session, the player loses all shot data. This DESTROYS trust and is unacceptable.

### 20.1 Write-Ahead Log Strategy

```
On every shot received from BLE:
  1. Write shot to Hive 'active_session' box immediately (< 1ms)
  2. Update in-memory state for UI rendering
  3. On session end → POST all shots to backend API → clear Hive

Hive 'active_session' box schema:
  'session_meta': {
    startTime: int (milliseconds since epoch),
    deviceId: string,
    playerId: string,
    deviceName: string
  }
  'shots': List<Map<String, dynamic>>  (all shots received)
  'is_active': bool  (true during session, false after end)
```

### 20.2 Recovery Flow

```
On app launch:
  1. Check Hive 'active_session' box
  2. Read 'is_active' flag
  3. If true (crash occurred):
     a. Show dialog: "You have an unsaved session with X shots. Recover?"
     b. YES → Load shots from Hive → show Session Summary screen
        → User taps Save → POST to backend API → clear Hive
     c. NO → clear Hive active_session box
  4. If false → normal app launch
```

---

## 21. OFFLINE SYNC STRATEGY

### 21.1 Data Prioritization for Sync

When internet is restored, sync in this order:

```
Priority 1: Completed sessions (most important, user expects cloud save)
Priority 2: User profile updates
Priority 3: Shot data for synced sessions
```

### 21.2 Sync Mechanism

```
1. On app launch → check Hive 'pending_sync' box for pending items
2. On internet restored (connectivity_plus listener) → trigger sync service
3. On session end → attempt API save (POST /sessions + POST /sessions/:id/shots):
   - Success → clear local copy, set syncStatus = "synced"
   - Fail → save to 'pending_sync' box, set syncStatus = "pending"
   - Show badge on home: "1 session pending sync"
4. Sync service processes queue one at a time with retry logic
5. On sync success → remove from queue
6. On sync failure → increment retry count, exponential backoff
   - After 5 failures → mark as "failed", notify user
```

### 21.3 Conflict Resolution

```
Sessions: app-generated UUID (uuid package) → no conflicts possible
Profile: last-write-wins (acceptable for V1)
Coach notes: server-authoritative (coach must be online to add notes)
```

### 21.4 Offline Capabilities Matrix

```
✅ Start/run/end session (BLE is local)
✅ View cached sessions (last 5 from Hive)
✅ View cached profile
✅ View cached analytics (last computed)
✅ Generate coaching insights (computed client-side)
❌ Coach features (require API reads)
❌ Registration (requires Firebase Auth)
❌ Push notifications (require FCM)
❌ Compare players (requires API reads of other players)
```

---

## 22. APP LIFECYCLE & SESSION PROTECTION

### 22.1 During Active Live Session

```
1. Keep screen ON:
   → WakelockPlus.enable() on session start
   → WakelockPlus.disable() on session end

2. App backgrounded:
   → Continue BLE via foreground service (Android)
   → Show persistent notification: "KnoQ session in progress"
   → Continue writing shots to Hive

3. Phone call interrupts:
   → Pause UI updates, keep BLE alive
   → Resume on return to app

4. Screen locked:
   → Same as backgrounded — BLE continues

5. App killed by OS:
   → Hive write-ahead log has all shots
   → Recover on next launch (Section 20)

6. Low battery warning:
   → Show "Battery low. Save your session now?" prompt

7. "Back" button pressed:
   → PopScope widget prevents accidental back navigation
   → Show confirm dialog: "End session? Your data will be saved"
```

### 22.2 Foreground Service Notification (Android)

```
Title: "KnoQ Session Active"
Body: "Recording your batting session. Tap to return."
→ Tapping opens the live session screen
→ Prevents Android from killing BLE in background
→ Required for Android 12+ background execution limits
```

---

## 23. ACADEMY CODE SYSTEM

### 23.1 Code Format
```
6 characters: uppercase alphanumeric [A-Z0-9]
Example: "KNQ4B2"
Generated automatically when academy is created
Stored in academies.join_code column in PostgreSQL
```

### 23.2 Validation Flow

```
1. Player enters code during onboarding (or "Join Academy" in Settings)
2. App calls GET /academy/lookup?code=ENTERED_CODE on the Node.js API
3. API returns academy name if found, 404 if not
4. If found:
   a. Display academy name: "Join [Academy Name]?"
   b. Player confirms → app calls POST /academy/join with the code
   c. API sets user.academy_id, increments academy player count
5. If not found (404):
   a. Show error: "Invalid academy code. Please check with your academy."
   b. Allow retry
6. Code does NOT expire automatically
7. Admin can regenerate code (POST /admin/regenerate-code — old code becomes invalid)
```

### 23.3 Edge Cases

```
- Player registers without code → standalone mode (no academy, no coach)
- Player wants to join academy later → Settings → "Join Academy" → enter code
- Player switches academy → admin must remove first, then player joins new one
- Academy at max player limit → API returns 409: "This academy has reached its player limit"
- Same code entered twice by same player → API returns 200 no-op, already a member
```

---

## 24. ONBOARDING FLOW

### 24.1 Three Screens (swipeable, progress dots)

**Screen 1: "Welcome to KnoQ"**
```
- KnoQ logo with subtle animation
- "Your AI-powered cricket coach"
- Brief value prop: 3 bullet points with icons
  • Track every shot
  • Find your patterns
  • Improve your game
- "Get Started" button
```

**Screen 2: "About You"**
```
- Name (text field, REQUIRED — block progress without it)
- Age (number picker dropdown 8-60, REQUIRED)
- Batting hand (toggle button: Left / Right, REQUIRED)
- Profile photo (camera/gallery picker, OPTIONAL)
```

**Screen 3: "Join Your Academy"**
```
- Academy code (text field with validation, OPTIONAL)
- "I don't have a code" link → skip, standalone mode
- On valid code → show academy name for confirmation
- "Join" button / "Skip for now" button
```

**→ Call POST /auth/register or PATCH /users/me → Set onboardingComplete = true → Navigate to Player Home**

### 24.2 Skip Behavior

- Name, age, and batting hand are REQUIRED (block progress)
- Academy code is OPTIONAL
- If academy code skipped → prompt again after 3rd session ("Join your academy for coaching insights")

---

## 25. NAVIGATION & ROUTING (GoRouter)

### 25.1 Route Definitions

```dart
// Public routes (no auth required)
/login
/register
/forgot-password

// Protected routes (auth required)
/onboarding                    → player onboarding (first time)
/home                          → player home screen
/session/permissions           → BLE permission check
/session/scan                  → BLE scan screen
/session/live                  → live session screen
/session/summary/:id           → session summary
/sessions                      → session history list
/sessions/:id                  → session detail
/sessions/:id/shots            → shot history for session
/analytics                     → analytics dashboard
/insights                      → coaching insights
/profile                       → player profile
/settings                      → app settings

// Coach routes (coach role only)
/coach                         → coach dashboard
/coach/player/:id              → player detail (coach view)
/coach/player/:id/session/:sid → session detail (coach view)
/coach/compare                 → compare players

// Error
/unauthorized                  → "Access denied" screen
```

### 25.2 Navigation Guards

```dart
GoRouter(
  redirect: (context, state) {
    final isLoggedIn = /* check auth state */;
    final userRole = /* check user role */;
    final onboardingDone = /* check onboarding flag */;
    final isOnLoginPage = state.matchedLocation == '/login';
    final isOnRegister = state.matchedLocation == '/register';
    final isPublicRoute = isOnLoginPage || isOnRegister ||
        state.matchedLocation == '/forgot-password';

    // Not logged in → force login (unless on public route)
    if (!isLoggedIn && !isPublicRoute) return '/login';

    // Logged in but on login page → redirect to home
    if (isLoggedIn && isOnLoginPage) return _homeForRole(userRole);

    // Logged in but onboarding incomplete
    if (isLoggedIn && !onboardingDone &&
        state.matchedLocation != '/onboarding') {
      return '/onboarding';
    }

    // Role-based route blocking
    if (state.matchedLocation.startsWith('/coach') &&
        userRole != 'coach') {
      return '/unauthorized';
    }

    return null; // no redirect needed
  },
);
```

---

## 26. ANALYTICS EVENT TRACKING

Track these events for product decisions using Firebase Analytics:

### 26.1 Auth Events
```
'sign_up'              → {method: 'email'|'google', has_academy: bool}
'login'                → {method: 'email'|'google'}
'onboarding_complete'  → {batting_hand: str, age: int, has_academy: bool}
'logout'               → {}
'account_deleted'      → {}
```

### 26.2 Session Events
```
'session_started'      → {device_id: str}
'shot_received'        → {zone: str, power: int, has_swing: bool, session_shot_count: int}
'session_ended'        → {total_hits: int, duration_s: int, sweet_pct: int, has_swing_data: bool}
'session_saved'        → {to: 'api'|'local'}
'session_recovered'    → {shots_recovered: int}
'session_shared'       → {method: str}
```

### 26.3 BLE Events
```
'ble_scan_started'     → {}
'ble_device_found'     → {device_name: str}
'ble_connected'        → {connect_time_ms: int}
'ble_disconnected'     → {during_session: bool, reason: str}
'ble_reconnected'      → {attempt: int}
'ble_permission_denied'→ {permission: str}
```

### 26.4 Feature Usage Events
```
'analytics_viewed'     → {time_range: str}
'insight_viewed'       → {insight_type: str}
'profile_edited'       → {fields_changed: [str]}
'academy_joined'       → {academy_id: str}
```

### 26.5 Coach Events
```
'player_viewed'        → {player_id: str}
'note_added'           → {session_id: str, tag_count: int}
'players_compared'     → {}
'report_exported'      → {format: 'pdf'|'csv'}
```

---

## 27. TESTING STRATEGY

### 27.1 Unit Tests (target: 80% coverage on business logic)

```
test/
├── features/
│   ├── insights/
│   │   └── insight_engine_test.dart     → all 10+ rules with edge cases + nullable swing
│   ├── ble/
│   │   └── shot_parser_test.dart        → valid JSON, malformed, missing fields, null swing
│   ├── session/
│   │   └── session_stats_test.dart      → averages, percentages, empty sessions, swing aggregation
│   └── auth/
│       └── validators_test.dart         → email, password, academy code
```

### 27.2 Widget Tests

```
test/
├── core/
│   └── widgets/
│       ├── bat_zone_diagram_test.dart   → renders correct zone highlight
│       ├── power_arc_test.dart          → correct color at boundaries (39,40,70,71)
│       ├── swing_speed_display_test.dart→ hidden when swing is null, visible when valid
│       └── zone_badge_test.dart         → correct color and label per zone
```

### 27.3 Integration Tests

```
integration_test/
├── auth_flow_test.dart                  → register → onboard → home
├── session_flow_test.dart               → scan → connect (mock BLE) → shots → end → summary
└── coach_flow_test.dart                 → login → see players → view session
```

### 27.4 Test Infrastructure

```
- Mock BLE service (mock_ble_service.dart) for testing without hardware
  → Simulates: scan results, connection, shot stream (with configurable null swing), disconnect
- Mock API client for testing without backend (interceptor returns fixture data)
- Riverpod overrides for injecting test dependencies
- Golden tests for key UI components (bat diagram, power arc)
- CI runs all tests on every PR merge
```

---

## 28. BUILD FLAVORS & ENVIRONMENT CONFIG

### 28.1 Three Flavors

```
dev     → Firebase dev project, dev API URL, debug BLE logging, mock data toggle
staging → Firebase staging project, staging API URL, real BLE, test analytics
prod    → Firebase production project, prod API URL, Crashlytics, production analytics
```

### 28.2 Per-Flavor Config

```
Environment variables per flavor:
  - Firebase project ID (different for each)
  - API base URL (dev: localhost:3000, staging: api-staging.knoq.in, prod: api.knoq.in)
  - BLE device name filter ("KnoQ-Bat-V1" vs "KnoQ-Bat-DEV")
  - Feature flag defaults
  - Log level (verbose / info / error)
  - Analytics enabled (true/false)
  - Mock BLE available (true for dev only)
```

### 28.3 Launch Commands

```bash
# Development (with mock BLE option)
flutter run --flavor dev --target lib/main_dev.dart

# Staging (real BLE, test API)
flutter run --flavor staging --target lib/main_staging.dart

# Production (release build)
flutter build apk --flavor prod --target lib/main_prod.dart
```

### 28.4 Android Flavor Config

```
android/app/build.gradle:
  flavorDimensions "environment"
  productFlavors {
    dev  { dimension "environment"; applicationIdSuffix ".dev" }
    staging { dimension "environment"; applicationIdSuffix ".staging" }
    prod { dimension "environment" }
  }
```

---

## 29. BUILD ORDER — V1 SPRINT PLAN

### Sprint 1 (Week 1–2): Foundation
```
├── Flutter project setup (structure, flavors, dependencies)
├── Node.js + Express API setup (project scaffold, folder structure, Render/Railway deploy)
├── PostgreSQL schema setup on Supabase (run CREATE TABLE migrations)
├── Firebase project setup (Auth only + Crashlytics + Analytics)
├── API auth middleware (Firebase JWT verification + user lookup)
├── Theme & design system implementation (light + dark themes, typography, shared widgets)
├── Auth screens (login, register, forgot password)
├── Email verification flow
├── Onboarding flow (3 screens)
├── GoRouter setup with navigation guards
├── Hive initialization
└── API endpoints: POST /auth/register, GET /users/me, PATCH /users/me
```

### Sprint 2 (Week 3–4): Core BLE
```
├── BLE service layer (scan, connect, disconnect, state machine)
├── Android permissions flow (all API levels)
├── Shot JSON parser with validation + malformed handling + nullable swing
├── MTU negotiation + JSON fragmentation buffering
├── Mock BLE service for dev/testing (configurable null swing scenarios)
├── BLE scan screen
├── Permission check screen
├── Unit tests: shot parser (including null swing), validators
└── API endpoints: GET /academy/lookup, POST /academy/join
```

### Sprint 3 (Week 5–6): Live Session
```
├── Live session screen (zone diagram, power arc, swing speed display, stats bar, shot list)
├── Session crash recovery (Hive write-ahead log)
├── BLE reconnection logic (3 retries, banner UI)
├── Wakelock + app lifecycle handling
├── PopScope + session end confirmation
├── Session end → summary screen with charts (including swing stats if available)
├── Session save to API (POST /sessions + POST /sessions/:id/shots) with local fallback
├── Widget tests: bat diagram, power arc, swing speed display
└── API endpoints: POST /sessions, GET /sessions, GET /sessions/:id, POST /sessions/:id/shots
```

### Sprint 4 (Week 7–8): Analytics & Insights
```
├── Session history screen (paginated API query)
├── Analytics dashboard (zone donut, power trend, swing trend, sweet% trend, consistency gauge)
├── Coaching insights engine (all V1 rules including swing consistency)
├── Player home screen (quick stats + recent sessions + device status)
├── Profile screen + settings screen (with Light/Dark/System theme picker)
├── Academy code join flow (via API)
├── Unit tests: insight engine (including swing rules + null swing), session stats, consistency score
└── API endpoints: GET /analytics, GET /users/me/stats, GET /coach-notes
```

### Sprint 5 (Week 9–10): Coach & Polish
```
├── Coach dashboard + player list
├── Player detail screen (coach view) + session detail (coach view)
├── Offline sync service (Hive → API queue)
├── Sync badge on home screen
├── Loading / empty / error states on ALL screens
├── Firebase Analytics event tracking
├── Crashlytics integration
├── Push notifications setup (FCM)
└── API endpoints: POST /coach-notes, GET /analytics/player/:id, GET /academy/players
```

### Sprint 6 (Week 11–12): Testing & Launch Prep
```
├── Integration tests (auth flow, session flow, coach flow)
├── Widget golden tests for key components
├── Performance testing (100+ shots live session)
├── OEM BLE testing (Xiaomi, Samsung, OnePlus, Oppo)
├── Bug fixes + UI polish
├── Play Store listing (screenshots, description, privacy policy)
├── Build production APK
└── Internal beta distribution (Firebase App Distribution)
```

---

## 30. RESOLVED DECISIONS

| # | Question (from V1) | Decision | Rationale |
|---|---------------------|----------|-----------|
| 1 | Flutter Web vs React for admin dashboard | **React + TypeScript on Vercel** | Data tables, CSV exports, and admin workflows are better served by React ecosystem; separate codebase from Flutter mobile app |
| 2 | Riverpod vs Bloc | **Riverpod** | Less boilerplate, better BLE stream handling, easier testing with overrides |
| 3 | Session shot limit in Hive | **500 confirmed safe** | Hive handles 10K+ objects; 500 shots ≈ 100KB |
| 4 | Database read cost at scale | **Add pagination from day 1** | Limit session list to 20 per page, load-more on scroll |
| 5 | BLE background handling | **Foreground service** during active session | flutter_blue_plus supports background; add OEM guidance |
| 6 | PDF export library | **`pdf` package** | Full layout control; `printing` is just a print preview wrapper |
| 7 | Primary database | **PostgreSQL on Supabase** (not Firestore) | Relational data model is better for analytics queries, RBAC, and coach-player relationships; Firestore is only used for Auth token issuing |
| 8 | Primary theme | **Light theme default, follows system setting** | Cricket apps used outdoors where light theme is more readable; user can override in Settings |
| 9 | Swing speed (MPU-9250) | **Nullable/optional everywhere** | IMU may not be wired or working; app must degrade gracefully with no swing data |

---

*Document version: 2.1 — KnoQ V1 Enhanced Application Specification*
*Last updated: April 2026*
*Owner: KnoQ Product Team*
*Changes from V2.0: Backend migrated to PostgreSQL + Node.js API, Firestore rules removed, React confirmed for web dashboard, light theme made primary, swing speed handling added as nullable, small reference fixes applied*
