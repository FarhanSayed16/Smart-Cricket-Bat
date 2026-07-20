# KnoQ — Master Project Reference

**Startup Name:** KnoQ  
**Category:** Sports Technology / AI / IoT  
**Tagline:** A smart coach in your pocket.  
**Last Updated:** April 2026  

> [!IMPORTANT]
> This is the **single source of truth** for the entire KnoQ project. It synthesizes all documentation, prompts, and design decisions into one reference. Consult this document first before making any development decisions.

---

## Table of Contents

1. [Vision & Core Concept](#1-vision--core-concept)
2. [System Architecture Overview](#2-system-architecture-overview)
3. [Hardware Layer](#3-hardware-layer)
4. [Firmware (ESP32)](#4-firmware-esp32)
5. [Algorithms & Calculations](#5-algorithms--calculations)
6. [Mobile Application (Flutter)](#6-mobile-application-flutter)
7. [Data Architecture (Firestore)](#7-data-architecture-firestore)
8. [BLE Connectivity Specification](#8-ble-connectivity-specification)
9. [Coaching Insights Engine](#9-coaching-insights-engine)
10. [UI/UX Design System](#10-uiux-design-system)
11. [Business Model & Go-To-Market](#11-business-model--go-to-market)
12. [Production & Manufacturing Plan](#12-production--manufacturing-plan)
13. [Development Roadmap & Phasing](#13-development-roadmap--phasing)

---

## 1. Vision & Core Concept

### 1.1 What KnoQ Is

KnoQ is an **integrated Digital Cricket Coach** — a smart cricket bat system that captures impact data from shots and converts it into actionable performance analytics. It is NOT just a Bluetooth data logger; it is a **multi-stakeholder performance platform**.

### 1.2 The Data Fusion Innovation

The core innovation lies in **Data Fusion**:

| Layer | Provides | Example |
|-------|----------|---------|
| **Bat (Embedded Sensors)** | *What* happened | Bat speed, power, impact zone, sweet spot % |
| **Camera (Smartphone @ Bowler's End)** | *How/why* it happened | Pose estimation, footwork, stance, shot selection |
| **Fusion (App + AI)** | Combined insights | "Your front foot was late — that's why edge hit" |

> [!NOTE]
> The camera is NOT on the bat. It is the user's smartphone placed on a tripod at the bowler's end. No extra hardware cost. This mirrors professional sports analysis.

### 1.3 Core Philosophy

- **Guide, don't judge.** Use "Risky option for this delivery" instead of "Wrong shot."
- **Confidence levels protect trust.** If data is incomplete → "Low confidence — not counted." Never show wrong feedback.
- **Measurable over subjective.** Every coaching insight must be backed by data.

### 1.4 Target Audience

| Phase | Audience | Rationale |
|-------|----------|-----------|
| **Phase 1** | Cricket academies, coaches, training centres | Train multiple players daily; value measurable improvement; lower CAC |
| **Phase 2** | Individual serious players, club-level cricketers | Pull from academy usage |
| **Phase 3** | Professional training setups, sports institutions | Scale play |

---

## 2. System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│              SMART BAT (Embedded System)                         │
│  ESP32 + IMU (MPU-9250 / ICM-20948) + 3× Piezo + LiPo Battery  │
│  → Process & Packetize → BLE Broadcast                          │
└───────────────────────────┬─────────────────────────────────────┘
                            │ BLE (Nordic UART)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│              SMARTPHONE (User's Device)                          │
│  Flutter App + Camera (Bowler's End) + MediaPipe AI              │
│  → BLE Receive → Video Sync → Insight Generation                │
└───────────────────────────┬─────────────────────────────────────┘
                            │ HTTPS
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│              FIREBASE (Cloud Backend)                             │
│  Auth + Firestore + Cloud Storage + Cloud Functions + FCM        │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow Per Shot

1. **Bat** → IMU + Piezo capture swing + impact → ESP32 processes
2. **ESP32** → Calculates zone, power, swing speed → BLE packet to phone
3. **Phone** → Receives BLE packet, optionally records video
4. **Sync** → Match impact timestamp to video frame (future)
5. **AI** → MediaPipe analyzes video clip (future)
6. **Cloud** → Save to Firebase for history, progress, coach access

---

## 3. Hardware Layer

### 3.1 Current Prototype Components

| Component | What We Have | Status |
|-----------|-------------|--------|
| **MCU** | ESP32 Dev Board (USB micro-B) | ✅ Working |
| **IMU** | MPU-9250 (or ICM-20948 9-DOF) | ✅ Working |
| **Impact Sensors** | 3× Piezo ceramic disc sensors (27mm) | ✅ Working |
| **Battery** | 3.7V LiPo | ❌ Not yet acquired |
| **Charger** | TP4056 module | ❌ Not yet acquired |
| **Bat** | Tennis cricket bat | ❌ Not yet acquired |

### 3.2 Electrical Connections (Prototype)

```
Power:
  LiPo (+) → TP4056 B+ → OUT+ → ESP32 VIN
  LiPo (−) → TP4056 B− → OUT− → ESP32 GND

IMU (I2C):
  VCC → ESP32 3V3
  GND → ESP32 GND
  SDA → GPIO 21
  SCL → GPIO 22
  AD0 → GND (address 0x68)

Piezo Sensors (ADC1):
  S1 (Center)  → GPIO 34 (ADC1_CH6) + 1MΩ to GND
  S2 (Left)    → GPIO 35 (ADC1_CH7) + 1MΩ to GND
  S3 (Right)   → GPIO 36 (ADC1_CH0) + 1MΩ to GND
  All piezo (−) leads → GND

Common GND: ESP32, TP4056, IMU, all piezos, all resistors
```

### 3.3 Sensor Placement (Back/Spine of Bat)

```
        ┌──────────┐  ← Handle
        │          │
        │          │
        │   [S1]   │  ← 22-24 cm from top (Center / Sweet Spot)
        │          │
        │          │
        │ [S2][S3] │  ← 32-35 cm from top (S2: left, S3: right)
        │          │     Offset 4-5 cm from center each
        │          │
        │          │
        └──────────┘  ← Toe
```

- V1: Sensors placed **externally** (tape-mounted), not embedded
- Sensors on the **back/spine** of the bat, not on the hitting face

### 3.4 Signal Conditioning

| Stage | Current (V1) | Upgrade Path |
|-------|-------------|--------------|
| **Piezo interface** | Direct → 1MΩ bleed → ADC | Add op-amp buffer (LMV321/LM358) per channel |
| **Filter** | None (oversampling only) | Add 10kΩ + 100nF low-pass filter after op-amp |
| **ADC** | ESP32 internal 12-bit (0–3.3V) | Consider external ADC for higher precision |

### 3.5 Production Hardware Targets

| Aspect | Prototype → Production |
|--------|----------------------|
| MCU | ESP32 Dev Board → ESP32-WROOM-32E module (pre-certified RF) |
| IMU | MPU-9250/ICM-20948 → ICM-45686 (±32g, sports-grade) |
| Piezo | Bare discs → Silicone-potted/encapsulated, 4 sensors |
| Battery | Generic LiPo → BIS-certified (IS 16046), 500-600mAh |
| Charging | TP4056 → BQ24075 (OVP, thermal protection), USB-C |
| PCB | Breadboard → Custom 4-layer FR4, 50×30mm, ENIG finish |
| Housing | Tape → Injection-molded TPU, IP54 |
| Weight | Unconstrained → ≤35g total electronics + housing |

---

## 4. Firmware (ESP32)

### 4.1 Current Implementation

**File:** `firmware/KnoQ_SmartBat/KnoQ_SmartBat.ino`  
**Framework:** Arduino (ESP32)  
**Baud Rate:** 115200  

### 4.2 Feature Flags

```cpp
ENABLE_BLE   = true   // BLE UART broadcasting
ENABLE_MPU   = true   // MPU-9250 IMU reading
SERIAL_RAW   = false  // Raw ADC debug printing
```

### 4.3 Core Firmware Functions

| Function | What It Does |
|----------|-------------|
| `readADC(pin)` | Reads ADC with 4× oversampling for noise reduction |
| `mpuInit()` | Initializes MPU-9250 via I2C at 400kHz |
| `mpuReadData()` | Returns accel (g) + gyro (°/s) + gyro magnitude |
| `detectZone(v1, v2, v3)` | Ratio-based zone classification → sweet/top/left/right/bottom |
| `calcPower(maxVal)` | Normalizes max ADC value to 0–100 scale |
| `updateBaseline(v1, v2, v3)` | EMA-based adaptive baseline for dynamic thresholding |
| `processHit(v1, v2, v3, gyro)` | Core hit handler: zone + power + stats + BLE output |
| `printSessionSummary()` | Prints/sends session summary every 10 hits |

### 4.4 Detection Pipeline

```
1. Read 3× Piezo ADC (oversampled)
2. Read IMU (accel + gyro)
3. Check: maxVal > dynamicThreshold AND debounce elapsed?
   YES → processHit()
   NO  → updateBaseline() if quiet (maxVal < threshold × 0.5)
4. Loop at ~200Hz (3ms delay)
```

### 4.5 Key Parameters

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `BASELINE_INIT` | 150 | Initial quiet ADC baseline |
| `HIT_MULTIPLIER` | 4.0× | Hit = signal > baseline × 4 |
| `BASELINE_ALPHA` | 0.05 | EMA smoothing (lower = slower adaptation) |
| `DEBOUNCE_MS` | 500 | Ignore duplicate hits within 500ms |
| `SWING_GYRO_THRESH` | 80 °/s | Above this = bat is swinging |
| `ZONE_DOMINANT` | 0.50 | Ratio above which one sensor "owns" the hit |
| `ZONE_LOW_THRESH` | 0.22 | Ratio below which sensor is "not active" |
| `POWER_MIN_RAW` | 200 | ADC value → 0% power |
| `POWER_MAX_RAW` | 3800 | ADC value → 100% power |

### 4.6 Zone Detection Logic

```
r1 = S1 / total,  r2 = S2 / total,  r3 = S3 / total

if r1 > 0.50  → "top"     (center sensor dominates)
if r2 > 0.50  → "left"    (left sensor dominates)
if r3 > 0.50  → "right"   (right sensor dominates)
if r1 < 0.22  → "bottom"  (center very weak = toe area)
else          → "sweet"   (balanced = sweet spot)
```

### 4.7 BLE Output Format

**Per shot (JSON over Nordic UART NOTIFY):**
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

**Session summary (every 10 hits):**
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

### 4.8 Production Firmware Targets

- Transition from Arduino to **ESP-IDF** for production
- **Interrupt-driven state machine**: IDLE (deep sleep ~80µA) → ACTIVE (wake-on-motion from IMU) → TRANSMIT → IDLE
- **SPI for IMU** (4× faster than I2C)
- **5kHz piezo sampling** to catch fast 1-2ms impact pulse
- **OTA update** support
- **NVS** for factory calibration storage

---

## 5. Algorithms & Calculations

### 5.1 Impact Detection

```
Baseline: EMA of quiet readings (updated when no hit for >500ms)
Threshold: baseline × 4.0 (clamped to 300–2500 ADC)
Impact: max(|piezo_i - baseline_i|) > threshold for any channel
Debounce: 500ms between hits
```

### 5.2 Bat Speed

```
ω (°/s) = √(gx² + gy² + gz²)         // gyro magnitude
ω (rad/s) = ω (°/s) × π/180
v (m/s) = ω (rad/s) × r               // r ≈ 0.45–0.55m (calibration constant)
v (km/h) = v (m/s) × 3.6

Use: max ω in window [t_impact - 50ms, t_impact + 10ms]
```

### 5.3 Power Index (0–100)

```
v_norm = min(1, v_kmh / 100)
a_norm = min(1, a_mag / 20)            // a in g
PowerIndex = 100 × (w1 × v_norm + w2 × a_norm)    // w1=0.5, w2=0.5
Clamp to [0, 100]

Current V1 (simplified): normalize max piezo ADC to 0–100 using
map(constrain(maxVal, 200, 3800), 200, 3800, 0, 100)
```

### 5.4 Shot Timing

```
t_max_speed = time of max ω in swing window
Δt = (t_impact - t_max_speed) × 1000 ms

Δt < 0  → "Early"
Δt > 0  → "Late"
|Δt| < 15ms → "On time"
```

### 5.5 Sweet Spot Detection

```
p_centre ≥ 0.5 × (p1 + p2 + p3) → sweet spot = true
Otherwise check which sensor dominates for zone classification
```

### 5.6 Consistency Score (App-Side)

```
consistencyScore = 100 - (zoneEntropyScore + powerStdDevNormalized)
  zoneEntropyScore: 0 = all same zone, 50 = all different
  powerStdDevNormalized: stdDev of power values → 0–50
Range: 0–100. Above 70 = consistent. Below 40 = inconsistent.
```

### 5.7 IMU Configuration

| Sensor | Range | Scale Factor |
|--------|-------|-------------|
| Accelerometer | ±16g (recommended) | raw / 2048 → g |
| Gyroscope | ±2000 dps (recommended) | raw / 16.4 → °/s |

> [!NOTE]
> Current firmware uses ±2g accel and ±250°/s gyro (conservative). For production, switch to ±16g and ±2000 dps to handle high-impact cricket shots without saturation.

---

## 6. Mobile Application (Flutter)

### 6.1 App Overview

| Attribute | Value |
|-----------|-------|
| **Platform** | Flutter (Android primary, iOS later, Web for coaches) |
| **State Management** | Riverpod (recommended) or Bloc |
| **Navigation** | GoRouter |
| **BLE Library** | flutter_blue_plus |
| **Local DB** | Hive (offline session storage) |
| **Charts** | fl_chart |
| **Auth** | Firebase Auth (email/password + Google OAuth) |
| **Database** | Cloud Firestore |
| **Min SDK** | Android 8 (API 26) |

### 6.2 User Roles & RBAC

| Role | Can Do | Cannot Do |
|------|--------|-----------|
| **Player** | Register, connect bat, start/end sessions, view own data, view coaching insights | See other players, access coach views, manage academy |
| **Coach** | View assigned players' data, add notes, compare players, export PDFs | See unassigned players, access billing, delete accounts |
| **Academy Admin** | Create coaches, assign players, view academy analytics, manage devices, billing | Access other academies, modify platform settings |
| **Super Admin** | Everything (web only) | Mobile login |

**Data Visibility Rules:**
- Player → own data only
- Coach → assigned players only
- Academy Admin → aggregated stats, drill into individual on request
- Super Admin → everything

### 6.3 Complete Screen Map

#### Player Screens

```
Splash → Login/Register → Onboarding (first time)
  ↓
Player Home
  ├── Quick stats (last session, lifetime sweet%)
  ├── Start Session → BLE Scan → Connect → Live Session
  ├── Recent sessions list
  └── Device connection status

Live Session (CORE SCREEN)
  ├── Zone indicator (SVG bat, zone lights up)
  ├── Power arc meter (0–100, color-coded)
  ├── Last shot card (zone + power + swing)
  ├── Running stats bar (hits / sweet% / avg power)
  ├── Shot history mini-list (last 5 shots)
  ├── End Session button
  └── BLE status indicator

Session Summary (after End Session)
  ├── Total hits, sweet%, avg power, peak power
  ├── Zone distribution pie chart
  ├── Power over time line chart
  ├── Coaching insight card (top 1-2 insights)
  ├── Save to Firestore
  └── Share (screenshot of summary)

Analytics Dashboard
  ├── Time range selector (session / 7d / 30d / all time)
  ├── Zone distribution donut chart
  ├── Power trend line chart
  ├── Sweet spot % trend
  ├── Consistency score gauge
  ├── Strongest/weakest zone badges
  └── Heatmap of hit zones (bat face visual)

Profile | Settings | Coaching Insights | Shot History
```

#### Coach Screens

```
Coach Dashboard → Player list (assigned) → Player Detail
  ├── Full analytics, session history, trend charts
  ├── Add coaching note
  ├── Compare players side-by-side
  └── Export PDF report

Session Detail (coach view) → Shot list + zone dist + coach note
```

#### Academy Admin (Web Dashboard)

```
Overview → Player Management → Coach Management
→ Device Management → Reports (CSV/PDF) → Billing
```

### 6.4 Auth Flow

```
App Launch → Check Firebase auth state
  ↓
Not logged in → Login Screen (email/pass or Google OAuth)
  ↓
On success → Fetch user doc → Read role → Route:
  "player" → Player Home
  "coach"  → Coach Dashboard
  "admin"  → Academy Admin Dashboard
  "super"  → Block mobile, web only
  ↓
First login → Onboarding (name, age, batting hand, academy code)
```

### 6.5 Offline Strategy

- **BLE works fully offline** — no internet needed for live session
- **Hive local DB** stores active session shots (written locally first)
- **On reconnect** → auto-sync to Firestore
- **Last 5 sessions cached** for offline analytics viewing
- **User profile cached** for instant app load

### 6.6 Performance Requirements

| Metric | Requirement |
|--------|-------------|
| BLE data → UI update | < 100ms |
| App cold start | < 3 seconds |
| Session save to Firestore | < 2 seconds on 4G |
| Chart render (100 shots) | < 500ms |
| Max local shots | 500 without degradation |
| Simultaneous BLE + Firestore | No dropped BLE packets |

---

## 7. Data Architecture (Firestore)

### 7.1 Collections

```
/users/{uid}
  name, email, role, academyId, battingHand, age, createdAt,
  assignedCoachId (players), assignedPlayers[] (coaches), profileImageUrl

/academies/{academyId}
  name, ownerUid, city, state, plan, planExpiresAt, totalBats

/devices/{deviceId}
  macAddress, name ("KnoQ-Bat-V1"), academyId, firmwareVersion,
  registeredAt, lastSeenAt, currentAssignedTo

/sessions/{sessionId}
  playerId, academyId, deviceId, startTime, endTime, status,
  totalHits, sweetSpotHits, sweetSpotPct, avgPower, peakPower,
  zoneDistribution {sweet, top, left, right, bottom},
  consistencyScore, coachNotes

/sessions/{sessionId}/shots/{shotId}
  timestamp, shotNumber, zone, power (0-100), swing (°/s),
  rawS1, rawS2, rawS3

/coachNotes/{noteId}
  coachId, playerId, sessionId, note, createdAt, tags[]
```

### 7.2 Security Rules

- All Firestore rules enforce role checks **server-side** (not just client)
- Player cannot query another player's sessions even by manipulating the app
- Coach can VIEW but never EDIT player session data
- Coach notes are separate (additive, not modifying)
- Device belongs to academy; cannot be assigned to two players simultaneously

### 7.3 Monetization Infrastructure

- `plan` field on academy gates features in Firestore rules
- `isPremium` check in code (returns false for all in V1)
- Usage counters on sessions, players, coaches
- Firebase Remote Config for feature flags

---

## 8. BLE Connectivity Specification

### 8.1 Service UUIDs (Nordic UART)

| Characteristic | UUID | Direction |
|---------------|------|-----------|
| **Service** | `6E400001-B5A3-F393-E0A9-E50E24DCCA9E` | — |
| **TX (Bat→App)** | `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` | NOTIFY |
| **RX (App→Bat)** | `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` | WRITE |

**Device Name:** `KnoQ-Bat-V1`

### 8.2 Connection State Machine

```
DISCONNECTED → user taps "Scan" → SCANNING
  → device found → CONNECTING
  → connected + services discovered → CONNECTED
  → BLE drops → AUTO_RECONNECT (3 retries, 2s apart)
  → retries exhausted → DISCONNECTED (toast)

During active session:
  → BLE drop → warning banner, keep session running locally
  → reconnect → resume streaming, no data lost
```

### 8.3 Commands App → Bat (RX)

```json
{"cmd": "calibrate"}       // reset baseline on ESP32
{"cmd": "reset_session"}   // clear session counters
{"cmd": "get_battery"}     // request battery level (future)
```

### 8.4 Data Integrity

- Each shot has a `hit` sequence number
- App checks for gaps → mark as "missing" (never fabricate)
- Duplicate sequence numbers deduplicated silently

### 8.5 Binary Packet Format (Production Target)

| Field | Type | Size | Description |
|-------|------|------|-------------|
| timestamp_ms | uint32 | 4B | Millis at impact |
| bat_speed_kmh | float | 4B | Bat speed (km/h) |
| power_index | uint8 | 1B | 0–100 |
| timing_delta_ms | int16 | 2B | Early(-) / Late(+) |
| sweet_spot | uint8 | 1B | 0=no, 1=yes |
| confidence | uint8 | 1B | 0=low, 1=med, 2=high |
| checksum | uint8 | 1B | XOR of bytes |
| **Total** | | **14–15B** | Per shot |

---

## 9. Coaching Insights Engine

### 9.1 V1: Rule-Based (Client-Side, No ML)

**Max 3 insights per session, most impactful first.**

#### Zone Bias Rules

| Condition | Insight |
|-----------|---------|
| leftPct > 40% | "Hitting left zone heavily. Check front foot alignment." |
| rightPct > 40% | "Right zone bias. Focus on keeping bat face square." |
| bottomPct > 25% | "Frequent toe hits. Try moving hands slightly down the grip." |
| topPct > 30% | "Hitting top of bat. Watch the ball longer — head may be lifting." |

#### Sweet Spot Rules

| Sweet% | Insight |
|--------|---------|
| > 70% | "Excellent sweet spot accuracy!" |
| 50–70% | "Good contact. Focus on footwork to improve." |
| 30–50% | "Room to improve. Slow swing, watch ball." |
| < 30% | "Low sweet spot contact. Prioritise technique over power." |

#### Power Rules

| Condition | Insight |
|-----------|---------|
| avgPower > 80% | "Very powerful. Focus on accuracy now." |
| avgPower < 40% | "Low power. Ensure full follow-through." |
| powerStdDev > 25 | "Inconsistent power. Focus on repeatable swing." |

#### Trend Rules (Need ≥3 sessions)

| Condition | Insight |
|-----------|---------|
| sweetPct improving over 3 sessions | "Sweet spot % improving. Great progress!" |
| avgPower declining over 3 sessions | "Power trending down. Check for fatigue or grip." |

#### Fatigue Rule

| Condition | Insight |
|-----------|---------|
| totalHits > 50 AND last-quarter avg power < first-quarter × 0.8 | "Power drops in last quarter. Consider shorter sessions." |

### 9.2 Insight Format

Each insight has: **title** (short) + **detail** (1 sentence) + **suggested action** (1 sentence).  
Insights are stored with the session in Firestore so coaches can see what the player was shown.

---

## 10. UI/UX Design System

### 10.1 Design Principles

- **Dark theme primary** (outdoor visibility, OLED battery saving)
- Large readable numbers — minimum **32px** for key metrics
- **One primary action per screen** — no cognitive overload during play
- Live Session screen: **operable with ONE hand, gloves on**
- Light theme option in settings

### 10.2 Color System

```
Primary:       #00C853  (cricket green — energy, positive)
Secondary:     #1565C0  (deep blue — data, trust)
Background:    #0D0D0D  (near-black)
Surface:       #1A1A1A  (card background)
Error:         #FF5252
Warning:       #FFB300
Text primary:  #FFFFFF
Text secondary:#9E9E9E

Zone Colors:
  Sweet:  #00C853 (green)
  Top:    #2196F3 (blue)
  Left:   #FF9800 (orange)
  Right:  #9C27B0 (purple)
  Bottom: #F44336 (red)
```

### 10.3 Key UI Components

| Component | Description |
|-----------|-------------|
| **Bat Zone Diagram** | SVG bat outline, 5 zones. Last hit zone illuminates in zone color, fades after 2s. Sweet zone pulses on sweet hit. |
| **Power Arc** | Circular arc 0–100. Green (>70), orange (40–70), red (<40). Animates 0→value in 300ms. |
| **Zone Distribution Chart** | Donut chart with zone colors. Tappable segments show % and count. |
| **Power Trend Chart** | Line chart (x=shot#, y=power). Reference line at session avg. Sweet hits as green dots. |

### 10.4 Animations & Haptics

- Hit received → haptic feedback + card slides in from bottom
- Sweet spot hit → green flash overlay (0.3s)
- New personal best → confetti + banner

### 10.5 Accessibility

- All text minimum 14sp
- All interactive elements minimum 48×48dp
- Color is never the only differentiator — zone icons accompany colors
- Screen reader labels on all interactive elements

---

## 11. Business Model & Go-To-Market

### 11.1 Revenue Streams

| Stream | Description | Phase |
|--------|-------------|-------|
| **Hardware Sales** | Smart bat device (₹6,000–₹12,000) | Phase 1 |
| **SaaS Subscription** | Academy dashboard (₹3,000–₹5,000/year) | Phase 1 |
| **B2C Subscription** | Personal analytics (₹199/month) | Phase 3 |
| **Premium Features** | AI coaching, highlight reels | Phase 3 |

### 11.2 Pricing Strategy

| Segment | Price (₹) | Margin |
|---------|-----------|--------|
| Single bat (retail) | 8,000–12,000 | 50–60% |
| Training centre (5 bats) | 7,000–10,000/bat | 45–55% |
| Academy (20+ bats) | 6,000–8,500/bat | 40–50% |

**COGS per unit (at 1000 units):** ₹2,250–3,900

### 11.3 Go-To-Market Strategy

```
Phase 1 (Validation):
  → Build working prototype → Test in real nets → Collect feedback

Phase 2 (B2B Entry):
  → Approach 10-20 cricket academies (Mumbai, Pune, Bangalore)
  → Demo + 2-week free trial
  → Sales pitch: "Mathematically prove which students improve"

Phase 3 (B2B2C Expansion):
  → Players at academies demand personal devices
  → Sell through coaches (10% affiliate commission)

Phase 4 (Scaling):
  → Mobile app ecosystem → Multi-city → AI features
```

### 11.4 Centre Tiers

| Tier | Bats | Features | Price Model |
|------|------|----------|-------------|
| **Starter** | 1–5 | Basic app, single bat | Per-bat + basic app |
| **Growth** | 6–20 | Centre dashboard, multi-bat | Bulk discount + subscription |
| **Enterprise** | 21+ | White-label, API, dedicated support | Custom pricing |

### 11.5 Competitive Advantage

- First-principles hardware + software integration
- Real-time **impact-based** analytics (not just video)
- Low-cost vs professional sports tech
- Expandable to full sports analytics platform

---

## 12. Production & Manufacturing Plan

### 12.1 Key Production Upgrades

| Aspect | Prototype → Production |
|--------|----------------------|
| Framework | Arduino → ESP-IDF |
| PCB | Breadboard → 4-layer custom (50×30mm) |
| Assembly | Hand-wired → SMT (JLCPCB/PCBWay or India EMS) |
| Housing | Tape → Injection-molded TPU (IP54) |
| Bat | Off-shelf → OEM with pre-cut cavity |

### 12.2 Quality Assurance

| Test | Specification |
|------|---------------|
| Drop test | 1.5m onto concrete, 6 faces |
| Shock test | 20G, 11ms half-sine, 3 axes |
| Vibration | 10–500Hz, 2g, 2 hrs |
| Temperature | 0°C to 45°C operating |
| Humidity | 90% RH, 48 hrs |
| Impact sim | 1000 simulated ball impacts |

### 12.3 Certifications Required

| Certification | For | Timeline |
|---------------|-----|----------|
| BIS (IS 16046 Part 2) | LiPo battery | 4–6 months |
| WPC | BLE radio | Often covered by ESP32 module |
| CE/FCC | Export (if applicable) | 3–6 months |

### 12.4 Durability Engineering

1. **Conformal coating** on assembled PCB (MG Chemicals 419C)
2. **Silicone wires** (not PVC) — absorb vibration
3. **Strain relief** — silicone RTV over solder joints
4. **Shock isolation** — rubber standoffs (neoprene M2 washers)
5. **Battery protection** — EVA foam wrap, XT30/locking JST connector

### 12.5 Bat Construction Rules

- **Cavity max:** 8mm deep, 40mm wide, ≥6mm solid wood sidewalls
- **All internal corners:** ≥4mm radius (no 90° = stress concentrators)
- **Fill empty space:** Closed-cell EVA foam
- **Lid:** 1.5mm ABS/PETG, press-fit + glued (never screws)
- **Weight equalizer:** Counter-bore handle plug by exact electronics weight

---

## 13. Development Roadmap & Phasing

### 13.1 MVP Scope (V1 — Ship First)

- [x] Firmware: Hit detection + zone classification + power measurement
- [x] Firmware: BLE output (JSON per shot + session summary)
- [ ] Player login / register / onboarding
- [ ] BLE scan + connect + live session screen
- [ ] Shot data parsing + real-time zone + power display
- [ ] Session save to Firestore
- [ ] Basic analytics (zone pie, power line, sweet%)
- [ ] Rule-based coaching insights (5 core rules)
- [ ] Player profile + session history
- [ ] Coach login + player list + session view

### 13.2 V1.5 — Next Sprint

- [ ] Academy admin web dashboard
- [ ] Coach notes on sessions
- [ ] Push notifications (FCM)
- [ ] PDF export
- [ ] Offline sync (Hive)
- [ ] Compare players (coach view)

### 13.3 V2 — After Validation

- [ ] Camera integration + pose estimation (MediaPipe)
- [ ] Shot type classification (drive, pull, cut, etc.)
- [ ] AI coaching (ML-based insights)
- [ ] Drill assignments from coach
- [ ] Multiplayer / leaderboards
- [ ] White-label for academies

### 13.4 Do NOT Build in V1

> [!CAUTION]
> - ❌ Any ML or camera features
> - ❌ Social features (sharing, leaderboards)
> - ❌ Payment / billing UI (handle manually for first 10 academies)
> - ❌ OTA firmware update from app
> - ❌ Multiple bat support per session

### 13.5 Future Vision

- Other sports (tennis, baseball, golf)
- AI-based coaching assistants
- Real-time ball tracking from phone camera
- AI Shot Suggestion Engine ("Cricket Coach Brain")
- Voice feedback ("Too early", "Perfect middle!")
- AI Coach 10-min personalized video
- Pressure Simulation Mode ("Match Pressure Engine")
- Fatigue & consistency tracking

---

## Appendix A: Project File Index

| Document | Content |
|----------|---------|
| `docs/KnoQ_Application_complete_plan_v1.md` | Complete Flutter app specification: RBAC, screens, BLE, data schema, tech stack, UX |
| `docs/PROJECT_UNDERSTANDING.md` | Full project vision: origin, features, architecture, hardware, roadmap |
| `docs/KNOQ_STRUCTURAL_AND_BUSINESS_BLUEPRINT.md` | Signal conditioning fix, bat cavity rules, weight engineering, firmware state machine, B2B strategy |
| `docs/KNOQ_RENEWED_UNDERSTANDING.md` | Unified technical summary: prototype vs production, algorithms, execution steps |
| `docs/CALCULATIONS_AND_ALGORITHMS.md` | Every formula: bat speed, power index, timing, sweet spot, confidence, BLE packet format |
| `docs/CONNECTIONS_LIST.md` | Pin-by-pin wiring: ESP32, IMU, piezos, TP4056, schematic diagram |
| `docs/CURRENT_COMPONENTS_STATUS.md` | What we have vs what we need, acquisition checklist |
| `docs/FINAL_COMPONENTS_LIST.md` | Production BOM: ESP32-WROOM-32E, ICM-45686, piezo, ADXL375, BQ24075, sourcing links |
| `docs/PRODUCTION_PLAN.md` | Manufacturing roadmap: PCB, housing, bat manufacturing, QA, certifications, pricing |
| `firmware/KnoQ_SmartBat/KnoQ_SmartBat.ino` | Current working V1 firmware: ADC + MPU + BLE + zone detection + power |

---

## Appendix B: Known Constraints & Risks

| Constraint | Impact | Mitigation |
|-----------|--------|------------|
| Piezo signals are high impedance | May require buffering | Add op-amp (LMV321) per channel if signal weak |
| ADC noise and BLE interference | False hits / missed hits | Use ADC1 pins only; oversampling; adaptive threshold |
| External sensor mounting | Reduces accuracy slightly | V1 acceptable; embed in V2 |
| No sensor fusion yet | IMU data not integrated with piezo | V1: piezo-only for zones; V2: fuse IMU for timing |
| ESP32 ADC non-linearity | Inaccurate voltage readings | Use calibration; or external ADC in production |
| Hardware durability under impact | Solder joints break, sensors crack | Conformal coating, silicone wire, strain relief, potting |
| Battery life (ESP32 always-on) | Drains in 2-3 hours | Production: deep sleep + wake-on-motion |

---

*This document synthesizes all project documentation as of April 2026. It should be updated as the project evolves.*
