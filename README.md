# KnoQ — Smart Bat (Coach's Eye AI)

**A Digital Cricket Coach for the Indian Audience**

KnoQ (Smart Bat) is an IoT-powered cricket training system that combines embedded sensors in a tennis cricket bat with AI-powered video analysis to help players practice effectively, track their performance, and improve their batting technique.

---

## 🏏 Overview

The Smart Bat transforms ordinary cricket practice into a data-driven coaching experience. By fusing **sensor data from the bat** with **computer vision from a smartphone camera** at the bowler's end, the system provides:

- **Real-time metrics** — Bat speed, power index, timing, sweet spot accuracy
- **AI technique analysis** — Pose estimation, footwork, head position, elbow angle
- **Synchronized video replay** — Slow-motion replays with stats overlaid at impact
- **Shot selection feedback** — AI recommendations based on ball trajectory and field setup

---

## 🎯 Key Features

### Bat-Side Metrics (Embedded Sensors)
| Metric | Description |
|--------|-------------|
| **Bat Speed** | Maximum speed of the bat's arc before impact (km/h) |
| **Power Index** | Score (1–100) based on bat speed and impact quality |
| **Shot Timing** | Perfect, early, or late timing (ms from ideal impact) |
| **Sweet Spot Accuracy** | Percentage of hits in the bat's optimal zone |
| **Bat Path Analysis** | 3D visualization of swing arc |
| **Follow-Through Angle** | Post-impact angle and completeness |

### Camera-Side Features (Coach's Eye AI)
- **Synchronized slow-motion replay** with stats overlaid at impact
- **Pose estimation** — Head position, footwork, backlift, elbow position
- **Shot selection feedback** — "Cut or backfoot punch would have been better"
- **Bat-ball contact visualizer** — Bat face angle, impact position analysis

---

## ⚙️ System Architecture

### How It Works

1. **Setup** — Player opens the app, places phone on a tripod at bowler's end, connects Smart Bat via Bluetooth
2. **Action** — Player swings and hits; IMU captures 3D motion; piezoelectric sensors detect impact point
3. **Transmission** — ESP32 processes data and sends compact packets to the app via BLE
4. **Synchronization** — App matches impact timestamp to exact video frame
5. **AI Analysis** — MediaPipe pose estimation analyzes technique on isolated video clips
6. **Insight** — Fused bat + video data generates coaching feedback and saves to cloud

### Data Flow

```
[Bat Sensors] → [ESP32] → BLE → [Smartphone App] ← [Camera]
                                    ↓
                            [MediaPipe AI]
                                    ↓
                            [Firebase Cloud]
```

---

## 🔧 Hardware Components

### Embedded System (Inside the Bat)

| Component | Specification |
|-----------|---------------|
| **MCU** | ESP32-WROOM-32 (Wi-Fi + BLE) |
| **IMU** | BNO055 (9-axis) or MPU-6050 (6-axis) |
| **Impact Sensors** | 3–4 Piezoelectric disc sensors (27mm) |
| **Power** | 400–500mAh LiPo + TP4056 charger (USB-C) |
| **Casing** | Shock-absorbent, 3D-printed or molded housing |

### External Hardware

- **Camera** — User's smartphone (iOS 14+ / Android 9+)
- **Stabilizer** — Tripod for smartphone at bowler's end

### Prototyping Tools

- Breadboard, jumper wires, soldering kit
- Multimeter, wire stripper, hot glue gun
- Electrical tape, Kapton tape

---

## 💻 Software & Technology Stack

| Layer | Technology |
|-------|------------|
| **Firmware** | C++ (Arduino framework) on ESP32 |
| **Mobile App** | Flutter or React Native (cross-platform) |
| **Communication** | Bluetooth Low Energy (BLE) |
| **AI / CV** | Google MediaPipe (pose estimation) |
| **Backend** | Firebase (Auth, Firestore, Cloud Storage) |

---

## 📋 Project Execution Roadmap

| Phase | Duration | Goals |
|-------|----------|-------|
| **Phase 1: Proof of Concept** | 2–6 weeks | Validate sensor capture, BLE connection, minimal app |
| **Phase 2: Prototyping** | 4–10 weeks | Custom PCB, housing, bat integration, main app UI |
| **Phase 3: AI Integration** | 2–8 weeks | MediaPipe, sync algorithm, cricket metrics from sensors |
| **Phase 4: Field Testing** | 2–6 weeks | Beta testing, calibration, bug fixes |
| **Phase 5: Launch** | 2–4+ weeks | Manufacturing, app store submission, marketing |

---

## 🛡️ Negative Scenarios & Mitigations

### Physical Misuse
- **Design** — Electronics offset from bat face, foam isolation, not on sweet spot
- **Policy** — Warranty excludes intentional impact on electronics housing

### Electronics Failure Mid-Session
- **Confidence levels** — App shows High / Medium / Low confidence; low = "not counted"
- **Fail-safe mode** — Switch to camera-only or auto-pause; never show wrong feedback

### Camera / Video Issues
- **Pre-session check** — Warn if lighting/angle insufficient; allow session but disable shot-selection judgement

### Player Mental Impact
- **Tone** — Guide, don't judge. Use "Risky option" instead of "Wrong shot"; "Better alternative suggested" instead of harsh criticism

---

## 🚀 Future Enhancements (from SMART BAT.pdf)

- **Real-time ball tracking** — Ball speed, line & length, swing direction from phone camera
- **AI Shot Suggestion Engine** — "For this length + position → recommended: Cover drive"
- **After-shot analysis** — "Right shot" / "Risky shot" / "Better option: Square cut"
- **Air-gesture voice feedback** — "Too early", "Perfect middle!", "Feet not aligned"
- **AI Coach — 10-min personalized video** — Session review with TTS, overlays, coaching tips
- **Pressure Simulation Mode** — Match scenarios (e.g., 12 off 4), field presets, mental training
- **Fatigue & consistency tracking** — Bat speed drop, timing degradation over session

---

## 📁 Project Structure

```
KnoQ/
├── docs/                    # Project documentation
│   ├── Adding Camera feature.pdf
│   ├── Components list - Batman.pdf
│   ├── Final Project Execution.pdf
│   ├── me and gemini conversation.txt
│   ├── Negative scenarios.pdf
│   ├── Smart Bat - Overview.pdf
│   └── SMART BAT.pdf
└── README.md
```

---

## 📄 Documentation

All planning, component lists, execution plans, and design decisions are documented in the `docs/` folder:

- **me and gemini conversation.txt** — Full design discussion and decisions
- **Adding Camera feature.pdf** — Coach's Eye AI camera system design
- **Components list - Batman.pdf** — Hardware component checklist
- **Final Project Execution.pdf** — Data flow, workflow, phased roadmap
- **Negative scenarios.pdf** — Business risks and mitigations
- **Smart Bat - Overview.pdf** — PitchView AI features and technical plan
- **SMART BAT.pdf** — Advanced features (ball tracking, AI coach, pressure mode)

---

## 🎯 Target Audience

- Indian cricket enthusiasts practicing tennis cricket
- Amateur players seeking structured feedback
- Cricket academies and sports clubs
- Anyone wanting to improve batting technique with data and AI

---

## 📜 License

*License to be defined.*

---

**Built with 🏏 for cricket lovers.**
