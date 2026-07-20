# KnoQ Smart Bat — Calculations, Formulas & Algorithms

**Complete specification of how every metric is computed, where (firmware vs app), and how the app uses the data.**

---

## Table of Contents

1. [Symbols and Units](#1-symbols-and-units)
2. [Data Flow Overview](#2-data-flow-overview)
3. [IMU Raw Data and Scaling](#3-imu-raw-data-and-scaling)
4. [Piezo Raw Data and Scaling](#4-piezo-raw-data-and-scaling)
5. [Impact Detection](#5-impact-detection)
6. [Bat Speed Calculation](#6-bat-speed-calculation)
7. [Power Index Calculation](#7-power-index-calculation)
8. [Shot Timing (Early / Late)](#8-shot-timing-early--late)
9. [Sweet Spot and Impact Location](#9-sweet-spot-and-impact-location)
10. [Confidence Level](#10-confidence-level)
11. [Firmware vs App Responsibilities](#11-firmware-vs-app-responsibilities)
12. [BLE Packet Format](#12-ble-packet-format)
13. [Calibration and Tuning](#13-calibration-and-tuning)
14. [Summary Formula Reference](#14-summary-formula-reference)

---

## 1. Symbols and Units

| Symbol | Meaning | Unit |
|--------|---------|------|
| \( \omega \) | Angular velocity (magnitude or axis-aligned) | rad/s or °/s |
| \( r \) | Effective radius (rotation axis to IMU) | m |
| \( v \) | Linear bat speed | m/s or km/h |
| \( a_x, a_y, a_z \) | Accelerometer axes | g or m/s² |
| \( g_x, g_y, g_z \) | Gyroscope axes | °/s or rad/s |
| \( a_{\text{mag}} \) | Acceleration magnitude | g |
| \( p_1, p_2, p_3 \) | Piezo channel amplitudes (at impact) | V or ADC counts |
| \( t_{\text{impact}} \) | Time of ball–bat impact | s or ms |
| \( t_{\text{max speed}} \) | Time of max bat speed in swing | s or ms |
| \( \Delta t \) | Timing error (impact − ideal) | ms |

---

## 2. Data Flow Overview

```
[IMU] ──raw ax,ay,az,gx,gy,gz──► [Firmware] ──► Bat speed, power, timing, impact flag
[Piezo] ──raw p1,p2,p3────────► [Firmware] ──► Impact detection, location, sweet spot
                                                                  │
                                                                  ▼
                                              [BLE packet: metrics + timestamp]
                                                                  │
                                                                  ▼
[App] ◄───────────────────────────────────────────────────────────┘
        Uses: display, sync with video, store session, confidence
```

- **Firmware:** Samples IMU + piezo, detects impact, computes bat speed, power index, timing, sweet-spot flag, and confidence. Sends one packet per shot (or streaming raw for debug).
- **App:** Receives packets, matches timestamp to video frame, shows metrics, runs pose estimation on video, stores to cloud.

---

## 3. IMU Raw Data and Scaling

### 3.1 ICM-20948 Registers and Conventions

- **Accelerometer:** 16-bit signed, X/Y/Z. Read registers (example): ACCEL_XOUT_H/L, etc.
- **Gyroscope:** 16-bit signed, X/Y/Z. Read registers: GYRO_XOUT_H/L, etc.
- **Orientation:** X = forward (toward blade), Y = lateral, Z = up (or per datasheet). Use consistent axes for bat frame.

### 3.2 Accelerometer: LSB → g

Full-scale range (FSR) and sensitivity (LSB per g):

| FSR | Sensitivity (LSB/g) | Formula |
|-----|---------------------|--------|
| ±2g | 16384 | \( a = \frac{\text{raw}}{16384} \) |
| ±4g | 8192 | \( a = \frac{\text{raw}}{8192} \) |
| ±8g | 4096 | \( a = \frac{\text{raw}}{4096} \) |
| ±16g | 2048 | \( a = \frac{\text{raw}}{2048} \) |

**Recommendation:** Use ±16g for cricket (high impact). So:

\[
a_x,\, a_y,\, a_z\ (\text{g}) = \frac{\text{raw}_{x,y,z}}{2048}
\]

**Magnitude (in g):**

\[
a_{\text{mag}} = \sqrt{a_x^2 + a_y^2 + a_z^2}
\]

### 3.3 Gyroscope: LSB → °/s (degrees per second)

| FSR | Sensitivity (LSB/(°/s)) | Formula |
|-----|-------------------------|--------|
| ±250 dps | 131 | \( \omega = \frac{\text{raw}}{131} \) |
| ±500 dps | 65.5 | \( \omega = \frac{\text{raw}}{65.5} \) |
| ±1000 dps | 32.8 | \( \omega = \frac{\text{raw}}{32.8} \) |
| ±2000 dps | 16.4 | \( \omega = \frac{\text{raw}}{16.4} \) |

**Recommendation:** Use ±2000 dps for fast swing. So:

\[
g_x,\, g_y,\, g_z\ (\text{°/s}) = \frac{\text{raw}_{x,y,z}}{16.4}
\]

**Magnitude (in °/s):**

\[
\omega_{\text{dps}} = \sqrt{g_x^2 + g_y^2 + g_z^2}
\]

**Convert to rad/s for bat speed:**

\[
\omega_{\text{rad/s}} = \omega_{\text{dps}} \times \frac{\pi}{180}
\]

---

## 4. Piezo Raw Data and Scaling

### 4.1 ESP32 ADC (GPIO 34, 35, 36)

- **Resolution:** 12-bit → raw 0–4095.
- **Default attenuation (11 dB):** effective range ~0–3.3 V (simplified).
- **Voltage:**

\[
V = \frac{\text{ADC}_{\text{raw}}}{4095} \times 3.3\ \text{V}
\]

(For better accuracy use ESP32 calibration and actual Vref.)

### 4.2 Piezo Signal Characteristics

- High impedance → 1 MΩ load to GND.
- Output can be positive or negative (bipolar); use **absolute value** or **rectify** for “strength.”
- **Peak amplitude** at impact is the feature (not DC level).

**Per channel, use one of:**

- **Peak in window:** \(\max(|V(t)|)\) in a short window after impact.
- **Peak-to-peak:** \(\max(V) - \min(V)\) in that window.
- Or use raw ADC **difference from baseline** (running average before impact).

---

## 5. Impact Detection

### 5.1 Trigger Source

- **Primary:** Piezo. When any channel exceeds a threshold above baseline → impact.
- **Secondary (optional):** IMU. When \( a_{\text{mag}} \) exceeds a threshold (e.g. 5–10 g) in a short window.

### 5.2 Piezo Threshold

- **Baseline:** Running average of each channel (e.g. last N samples, N ≈ 50–200).
- **Impact:** When \(\text{abs}(\text{piezo}_i - \text{baseline}_i) > T_{\text{piezo}}\) for **any** channel \(i\).
- **Debounce:** One impact per 100–200 ms (ignore repeats).

**Formula (per channel):**

\[
\text{impact\_detected} = \max_{i=1,2,3} \bigl|\text{ADC}_i - \text{baseline}_i\bigr| > T_{\text{piezo}}
\]

\(T_{\text{piezo}}\): in ADC counts (e.g. 100–500). Tune from real hits.

### 5.3 Impact Timestamp

- \(t_{\text{impact}}\) = sample time (or micros()) when impact condition is first true.
- Send this in the BLE packet so the app can align to video frame.

---

## 6. Bat Speed Calculation

### 6.1 Physics

Linear speed at a point on the bat:

\[
v = \omega \times r
\]

- \( \omega \): angular speed (rad/s) about the rotation axis.
- \( r \): distance from rotation axis to the IMU (metres).

### 6.2 Choosing \( \omega \)

- Use **gyro magnitude** at (or just before) impact:
  \[
  \omega_{\text{dps}} = \sqrt{g_x^2 + g_y^2 + g_z^2}
  \]
- Convert to rad/s:
  \[
  \omega_{\text{rad/s}} = \omega_{\text{dps}} \times \frac{\pi}{180}
  \]

### 6.3 Effective Radius \( r \)

- Depends on bat length and where the IMU is mounted (e.g. spine, 20–30 cm from handle).
- **Typical:** \( r \approx 0.45\text{--}0.55\ \text{m} \). Make this a **calibration constant** (e.g. 0.50 m).

### 6.4 Bat Speed in km/h

\[
v\ (\text{m/s}) = \omega_{\text{rad/s}} \times r
\]

\[
v\ (\text{km/h}) = v\ (\text{m/s}) \times 3.6
\]

### 6.5 Which Sample to Use

- **Option A:** Gyro at the exact impact sample (sample at \(t_{\text{impact}}\)).
- **Option B:** Max gyro magnitude in a short window before impact (e.g. 20–50 ms). Option B is often more representative of “swing speed” at contact.

**Recommendation:** Use **max** \(\omega_{\text{dps}}\) in window \([t_{\text{impact}} - 50\ \text{ms}, t_{\text{impact}} + 10\ \text{ms}]\), then apply \(v = \omega \times r\).

---

## 7. Power Index Calculation

### 7.1 Idea

Combine “how fast the bat was moving” and “how hard the impact was” into a 0–100 score.

### 7.2 Components

1. **Bat speed component:** Normalize bat speed to 0–1. Example: \(v_{\text{norm}} = \min(1, v\ (\text{km/h}) / 100)\).
2. **Impact strength component:** From peak \(a_{\text{mag}}\) at impact, or from sum of piezo peaks. Example: \(a_{\text{norm}} = \min(1, a_{\text{mag}} / 20)\) (if using 20 g as “max”).

### 7.3 Combined Formula

\[
\text{PowerIndex} = 100 \times \bigl( w_1 \cdot v_{\text{norm}} + w_2 \cdot a_{\text{norm}} \bigr)
\]

With \(w_1 + w_2 = 1\). Example: \(w_1 = 0.5\), \(w_2 = 0.5\). Then clamp to [0, 100].

**Alternative (simpler):**

\[
\text{PowerIndex} = \min\left(100,\ 100 \times \frac{v\ (\text{km/h})}{100}\right) \quad \text{(speed-only)}
\]

or mix speed and peak accel with weights; tune \(w_1, w_2\) and max values during calibration.

---

## 8. Shot Timing (Early / Late)

### 8.1 Concept

- “Ideal” impact is near the time of **maximum bat speed** in the swing.
- If impact happens **before** max speed → **early**.
- If impact happens **after** max speed → **late**.

### 8.2 Definition of \(t_{\text{max speed}}\)

- In a swing window (e.g. 200 ms before impact to 50 ms after), find the sample where \(\omega_{\text{dps}}\) is maximum.
- \(t_{\text{max speed}}\) = time of that sample.

### 8.3 Timing Error (ms)

\[
\Delta t = (t_{\text{impact}} - t_{\text{max speed}}) \times 1000
\]

(\(t\) in seconds → \(\Delta t\) in ms.)

- \(\Delta t < 0\): impact **before** max speed → **early**.
- \(\Delta t > 0\): impact **after** max speed → **late**.
- \(\Delta t \approx 0\): **on time** (e.g. |Δt| < 15 ms).

### 8.4 Display

- Send \(\Delta t\) (ms) in BLE packet.
- App shows: “-15 ms (Slightly Early)”, “+8 ms (Slightly Late)”, “On time”.

---

## 9. Sweet Spot and Impact Location

### 9.1 Three Sensors

- Place three piezos on the bat face: e.g. **Top**, **Centre**, **Bottom** (or Left, Centre, Right).
- At impact, record **peak amplitude** (or peak above baseline) for each: \(p_1, p_2, p_3\).

### 9.2 Simple Zone Rule (No Triangulation)

- **Sweet spot:** Centre sensor dominates. Example: \(p_2 > 0.6 \times (p_1 + p_2 + p_3)\).
- **Toe/edge:** Top or bottom (or left/right) dominates. Define thresholds from calibration.

**Formula (example):**

\[
\text{sweet\_spot} = \begin{cases}
\text{true}  & \text{if } p_{\text{centre}} \ge 0.5 \times (p_1 + p_2 + p_3) \\
\text{false} & \text{otherwise}
\end{cases}
\]

### 9.3 Weighted Position (Optional)

- Normalize: \(P_i = p_i / (p_1 + p_2 + p_3)\).
- If sensors are at positions \(x_1, x_2, x_3\) (e.g. 0, 0.5, 1 along bat length):
  \[
  x_{\text{impact}} = P_1 x_1 + P_2 x_2 + P_3 x_3
  \]
- Then map \(x_{\text{impact}}\) to “sweet” (e.g. 0.35–0.65) vs “toe/edge”.

### 9.4 Output to App

- **Sweet spot hit:** boolean (or 0/1).
- **Zone (optional):** “centre” / “toe” / “edge” from which sensor is largest.

---

## 10. Confidence Level

### 10.1 When to Lower Confidence

- **Low:** Any of: (a) no clear impact on piezo, (b) IMU saturated (e.g. accel at ±16g), (c) BLE dropout, (d) sync lost with app.
- **Medium:** Impact clear but one sensor noisy, or bat speed at limit of range.
- **High:** Clear impact, all sensors in range, good sync.

### 10.2 Rule (Firmware)

- If impact not detected by piezo **or** \(a_{\text{mag}} > 15\) g (saturation) → **Low**, do not send shot (or send with confidence=0).
- If impact detected and no saturation → **High** (or **Medium** if secondary checks fail).

### 10.3 App

- If confidence is Low → show “Low confidence – not counted”, do not update session stats.
- If High/Medium → show metrics and count shot.

---

## 11. Firmware vs App Responsibilities

| Task | Where | Notes |
|-----|--------|------|
| Sample IMU at ~200–500 Hz | Firmware | I2C read loop |
| Sample piezo at same rate | Firmware | ADC read |
| Impact detection (threshold) | Firmware | Piezo (and optional accel) |
| Bat speed (\(v = \omega r\)) | Firmware | From gyro + \(r\) |
| Power index (0–100) | Firmware | From speed + peak accel (or piezo) |
| Timing \(\Delta t\) (ms) | Firmware | \(t_{\text{impact}} - t_{\text{max speed}}\) |
| Sweet spot (boolean/zone) | Firmware | From \(p_1, p_2, p_3\) |
| Confidence level | Firmware | From saturation + detection quality |
| BLE packet per shot | Firmware | All above + timestamp |
| Match timestamp to video frame | App | Sync logic |
| Pose estimation (MediaPipe) | App | On video clip |
| Store session, show UI | App | Firebase, screens |

---

## 12. BLE Packet Format

### 12.1 Recommended Payload (per shot)

| Field | Type | Size | Description |
|-------|------|------|-------------|
| timestamp_ms | uint32 | 4 B | Millis at impact (for app sync) |
| bat_speed_kmh | float | 4 B | Bat speed (km/h) |
| power_index | uint8 | 1 B | 0–100 |
| timing_delta_ms | int16 | 2 B | ms (early negative, late positive) |
| sweet_spot | uint8 | 1 B | 0 = no, 1 = yes |
| confidence | uint8 | 1 B | 0=low, 1=med, 2=high |
| checksum (optional) | uint8 | 1 B | XOR of bytes |

**Total:** 14–15 bytes per shot.

### 12.2 Alternative: ASCII over BLE

For debugging, send a single line per shot, e.g.:

`TS=12345678,BS=72.5,PI=85,TD=-12,SS=1,CF=2\n`

App parses this for quick testing.

---

## 13. Calibration and Tuning

### 13.1 Constants to Tune

| Constant | Symbol | Typical | How |
|----------|--------|---------|-----|
| Effective radius | \(r\) | 0.45–0.55 m | Measure bat + IMU position; or compare to reference |
| Piezo threshold | \(T_{\text{piezo}}\) | 100–500 ADC | Hit bat lightly vs hard; set so only real hits trigger |
| Gyro range | ±2000 dps | — | ICM-20948 register |
| Accel range | ±16g | — | ICM-20948 register |
| Power index weights | \(w_1, w_2\) | 0.5, 0.5 | Subjective “feel” vs speed/impact |
| Sweet spot ratio | e.g. 0.5 | — | Centre vs total piezo sum |

### 13.2 Bat Speed Calibration

- Optional: use a known reference (e.g. high-speed camera or another device) at one or two swing speeds.
- Scale \(r\) or add a linear factor so firmware bat speed matches reference: \(v_{\text{out}} = k \cdot \omega \cdot r\).

### 13.3 Baseline (Piezo)

- On startup, sample piezos for 1–2 s with no impact; set baseline = running average.
- Re-baseline periodically (e.g. every 10 s) when no impact for 2 s.

---

## 14. Summary Formula Reference

| Metric | Formula |
|--------|---------|
| Accel (g) | \(a = \text{raw} / 2048\) (±16g) |
| Gyro (°/s) | \(g = \text{raw} / 16.4\) (±2000 dps) |
| Gyro (rad/s) | \(\omega = g \times \pi/180\) |
| Bat speed (km/h) | \(v = \omega \times r \times 3.6\) |
| Power index | \(100 \times (w_1 v_{\text{norm}} + w_2 a_{\text{norm}})\), clamp [0,100] |
| Timing (ms) | \(\Delta t = (t_{\text{impact}} - t_{\text{max speed}}) \times 1000\) |
| Sweet spot | centre_dominates e.g. \(p_2 \ge 0.5(p_1+p_2+p_3)\) |
| Piezo voltage | \(V = (\text{ADC}/4095) \times 3.3\) V |

---

## 15. App-Side Calculations

### 15.1 Per-Shot Display

- Use packet fields directly: **Bat Speed (km/h)**, **Power Index**, **Timing (ms)**, **Sweet Spot (Y/N)**, **Confidence**.
- Map timing to text: e.g. Δt < -20 → "Early", -20 to +20 → "On time", > +20 → "Late".

### 15.2 Session Averages (App)

- **Average bat speed:** Mean of all bat_speed_kmh in session (only high-confidence shots).
- **Sweet spot %:** (count where sweet_spot=1) / (total shots) × 100.
- **Average power index:** Mean of power_index.

### 15.3 Video Sync

- App stores `timestamp_ms` (or device millis at impact).
- When app records video, it has a start timestamp (e.g. `System.currentTimeMillis()` at record start).
- **Frame index** for impact ≈ `(timestamp_ms - record_start_ms) × frame_rate / 1000`. Tune for BLE latency (e.g. add small offset).

### 15.4 Confidence Handling in App

- If `confidence == 0`: Show "Low confidence – not counted"; do not add to session totals.
- If `confidence == 1 or 2`: Show metrics and add to session.

---

## 16. Firmware and Code Location

- **Firmware:** `firmware/KnoQ_SmartBat/KnoQ_SmartBat.ino` (Arduino/ESP32).
- **Implements:** IMU read (ICM-20948), piezo read (GPIO 34/35/36), impact detection, bat speed, power index, timing, sweet spot, confidence, BLE packet (ShotPacket struct).
- **BLE:** Service UUID `6e400001-...`, Characteristic `6e400002-...` (Notify). Device name: `KnoQ-SmartBat`.
- **Calibration:** Edit `EFFECTIVE_RADIUS_M`, `PIEZO_THRESHOLD`, `SWEET_SPOT_RATIO`, and power weights at top of `.ino` to match CALCULATIONS_AND_ALGORITHMS.md.

---

*This document is the single source of truth for all calculations. Firmware and app must implement these formulas and packet format.*
