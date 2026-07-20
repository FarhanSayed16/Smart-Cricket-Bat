# KnoQ Smart Bat — Current Components Status

**What you have vs what the project needs, and what to do next.**

---

## 1. What You Have (Confirmed)

| Component | What You Have | Status |
|-----------|----------------|--------|
| **MCU** | ESP32 development board (with USB micro-B) | ✅ **Matches** — Same chip as ESP32-WROOM-32; dev board is fine for prototyping. |
| **IMU** | 7SEMI ICM-20948 9-DOF IMU module (I2C/SPI: VCC, GND, SDA, SCL, AD0, CS, INT) | ✅ **Matches** — 9-axis (accel + gyro + magnetometer). Use for swing path and bat speed. Impact/sweet spot from piezo, so ±16g accel is acceptable. |
| **Impact / sweet spot** | 3× TE Connectivity film sensors (silver, rectangular, two pins, TE logo) | ✅ **PVDF / piezo film** — TE makes PVDF-based piezo film (e.g. DT series). Ideal for impact and vibration; flexible and good for bat face. |

---

## 2. TE Sensors — What They Are

- **Type:** TE Connectivity **piezo film sensors** (PVDF-based, e.g. DT series).
- **Look:** Thin, flexible, silver metallization, two leads.
- **Use:** Dynamic strain, vibration, **impact detection** — exactly what we need for ball-on-bat.
- **Verdict:** These are **suitable and better than cheap ceramic discs** for a flexible, research-style setup. You can use them for **sweet-spot / impact location** by comparing which sensor(s) respond first and strongest.

---

## 3. Requirements vs What You Have

| Requirement | Spec | You Have | Match? |
|-------------|------|----------|--------|
| MCU with BLE | ESP32 (Wi-Fi + BLE) | ESP32 dev board | ✅ Yes |
| IMU (motion) | 6-axis or 9-axis for swing/speed | ICM-20948 9-DOF | ✅ Yes |
| Impact sensors | 3–4 for sweet-spot triangulation | 3× TE PVDF/piezo film | ✅ Yes (3 is enough; 4 is slightly better) |
| Battery | 3.7 V LiPo 400–500 mAh | — | ❌ Not yet |
| Charging | TP4056 or BQ24075, USB | — | ❌ Not yet |
| Bat | Tennis cricket bat | — | ❌ Not yet |
| Housing | Shock-proof casing | — | ❌ Later (prototype can be taped) |
| Wires / proto | Jumper wires, breadboard | — | ❌ Get if you don’t have |

**Summary:** **MCU, IMU, and impact sensors match.** You still need **power (battery + charger)**, a **bat**, and **basic prototyping parts**.

---

## 4. What To Do Next

### Step 1: Get the missing hardware (short list)

- **LiPo battery:** 3.7 V, 400–500 mAh, with JST-PH 2-pin (or similar).
- **Charging module:** TP4056 with USB (micro or USB-C) and protection circuit.
- **Jumper wires:** Male–male and male–female (for ESP32, IMU, TE sensors).
- **Breadboard (optional):** For quick testing before mounting on bat.
- **Tennis cricket bat:** One piece for first prototype.

### Step 2: Wiring (high level)

- **ESP32**  
  - 3.3 V → IMU VCC, and (if needed) high-impedance buffer for piezo.  
  - GND → common GND for IMU, piezo return, battery negative.  
  - SDA/SCL → IMU (I2C).  
  - ADC or digital pins → TE piezo sensors (see below).

- **ICM-20948**  
  - VCC, GND, SDA, SCL to ESP32.  
  - AD0: tie to GND or 3.3 V to fix I2C address if needed.

- **TE piezo film (3 sensors)**  
  - **Important:** Piezo output is high impedance and can be small voltage. Use a **high-impedance buffer** (e.g. op-amp voltage follower, 1 MΩ+ input) or a simple **RC + comparator** per channel if you only need “impact yes/no” and relative strength.  
  - One pin of each sensor to signal (via buffer/comparator to ESP32 ADC or GPIO); other pin to GND.  
  - Place the 3 films at different positions on the bat face (e.g. top-left, centre, bottom-right) for **triangulation** of impact location (sweet spot vs toe/edge).

### Step 3: Firmware (first goals)

1. Read **ICM-20948** (accel + gyro) over I2C; stream or log at ~100–200 Hz.
2. Read **3× TE piezo** channels (after buffering); detect **impact** (threshold + timing).
3. Send data over **BLE** to phone (or USB serial for first tests).

### Step 4: Optional improvements

- **4th TE sensor** — Improves triangulation; add if you can get one more.
- **Housing** — Once the prototype works, design a small shock-proof box (e.g. 3D print) and fix it on the bat spine, not on the hitting face.

---

## 5. Quick Checklist

- [x] ESP32 — have  
- [x] ICM-20948 9-DOF IMU — have  
- [x] Impact sensors (3× TE PVDF/piezo film) — have  
- [ ] LiPo battery 3.7 V 400–500 mAh  
- [ ] TP4056 (or similar) charging module  
- [ ] Jumper wires / breadboard  
- [ ] Tennis cricket bat  
- [ ] High-impedance buffer or simple circuit for piezo (recommended)  
- [ ] Firmware: IMU + piezo + BLE  
- [ ] App or PC tool to receive BLE data  

---

## 6. Summary

- **Your 3 small TE sensors are PVDF/piezo film sensors** — correct for impact and sweet-spot detection.  
- **ESP32 + ICM-20948 + 3× TE piezo** meets the **core sensing requirements**.  
- **Next:** Add **battery, charger, bat, and piezo interface**; then implement **IMU + piezo + BLE** in firmware and connect to an app or PC for testing.
