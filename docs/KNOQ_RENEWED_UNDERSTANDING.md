# KnoQ Smart Bat — Renewed Comprehensive Project Understanding

**A unified master document synthesizing all technical, hardware, algorithmic, and business perspectives for the continuous development of the KnoQ "Coach's Eye AI" Digital Cricket Coach.**

---

## 1. Project Vision & Core Philosophy

**The Concept:** KnoQ is not just a smart bat; it is an integrated **Digital Cricket Coach**. The core innovation lies in **Data Fusion**:
- **The Bat (Embedded Sensors):** Tells you *what* happened (Bat Speed, Power, Timing, Sweet Spot).
- **The Camera (User's Smartphone at Bowler's End):** Tells you *how and why* it happened (Pose estimation, stance, footwork, shot selection).
- **The Philosophy:** The system must act as a **guide, not a harsh judge**. Terminology focuses on improvement (e.g., "Risky option for this delivery" instead of "Wrong shot"). Crucially, to maintain player trust, if data is missing or incomplete, the system records "Low confidence" rather than presenting inaccurate feedback.

## 2. Hardware Architecture & Current Status

### 2.1 Prototype vs. Production
Our path spans from current prototyping to B2B mass manufacturing:
*   **MCU:** Currently using an **ESP32 Dev Board**. Production will transition to an **ESP32-WROOM-32E** module for native integration and pre-certified RF. Alternatively, an nRF52840 system for ultimate low power.
*   **IMU:** Currently have the **ICM-20948 (9-DOF)**. Production points towards the sports-grade **ICM-45686** (up to ±32g) with an optional ADXL375 for high-g shock backup.
*   **Impact Sensors:** Currently using **3× TE PVDF/piezo film sensors**. Production shifts toward durable, encapsulated **27 mm ceramic piezo discs** to better survive impact forces without bond failure.
*   **Missing Prototype Elements:** We urgently need **3.7V LiPo batteries (400-500 mAh)**, **TP4056 charging modules**, high-impedance buffers/resistors (1MΩ), and the host **tennis cricket bat**.

### 2.2 Core Circuit Connections (Prototype)
*   **Power:** LiPo -> TP4056 -> ESP32 (`VIN`, `GND`). (Do not plug USB to ESP32 while battery is powering `VIN`).
*   **IMU (ICM-20948):** Connected via I2C (`GPIO 21` SDA, `GPIO 22` SCL). Powered from ESP32 `3V3`.
*   **Piezos (x3):** Require 1 MΩ pull-down resistors. Connected to ADC1 pins (`GPIO 34`, `GPIO 35`, `GPIO 36`) to safely read during Wi-Fi/BLE activities.

## 3. Calculations, Algorithms, and Data Flow

All metrics are processed primarily firmware-side and sent via BLE (approx. 14-byte packet, or debug ASCII) mapping to real-time events.

*   **Bat Speed ($v = \omega \times r$):** Peak gyroscope magnitude (converted to rad/s) in a window around impact multiplied by effective bat radius ($~0.45-0.55m$).
*   **Impact Detection:** Triggered when any piezo channel drastically exceeds its rolling baseline, serving as the `$t_{impact}$` timestamp.
*   **Timing:** Calculates $t_{impact} - t_{max\_speed}$. Negative implies "Early", positive implies "Late".
*   **Sweet Spot:** Determined by mathematical triangulation from the 3/4 piezo films. If the center/primary piezo experiences $>50\%$ of the collective amplitude, it registers as a sweet spot hit.
*   **Power Index:** A combined normalized score (0-100) weighting both the bat speed ($v_{norm}$) and the impact strength ($a_{norm}$).

## 4. Software & AI Ecosystem

*   **Firmware (ESP-IDF/C++):** Handles fast sampling of IMU and ADCs, performs the math above, manages deep-sleep battery saving, and broadcasts the event via BLE per shot.
*   **App (Flutter / React Native):** Cross-platform central hub. Receives BLE timestamps and applies the **most critical system challenge**: Synchronizing the incoming IoT timestamp with the exact smartphone video camera frame.
*   **AI (MediaPipe):** On-device pose estimation. Draws shoulder, elbow, hip vectors mapped on the synced impact frame.
*   **Cloud (Firebase):** Stores historical profiles, allowing players and B2B training center coaches to track longitudinal fatigue and progress charts.

## 5. Production & Go-to-Market (B2B Focus)

*   **Target:** Training academies handling bulk bats (5-20 bats/center) offering the "Tech-Enabled Cricket coaching" edge to their pupils.
*   **Mechanics:** Housing must be injection-molded TPU situated inside a custom-cut spine cavity of the bat (offset from the face impact zone).
*   **Certifications:** Requires BIS for the battery (IS 16046) and electronics.
*   **Future Expansions:** SmartCam real-time ball tracking, AI voice coaching (Air-Gesture feedback), AI 10-minute highlight reels, and a "Match Pressure Engine" gamification system.

## 6. Immediate Next Execution Steps for Project Renewal

To immediately move the renewed phase of KnoQ forward:
1.  **Hardware Procurement:** Acquire LiPo batteries, TP4056 chargers, jumpers, and a cheap tennis cricket bat for mounting.
2.  **Breadboard Rigging:** Connect the ESP32, ICM-20948, and TE Piezos on a benchtop to validate the 1MΩ resistor ADC curves.
3.  **Firmware V1:** Implement the I2C IMU polling and the ADC thresholding for "Impact" detection. Send a basic string via BLE: `Impact detected, max omega = XYZ`.
4.  **App & Synchronization testing:** Get the mobile device observing the BLE characteristic, and experiment with correlating the BLE receipt to system camera time.
