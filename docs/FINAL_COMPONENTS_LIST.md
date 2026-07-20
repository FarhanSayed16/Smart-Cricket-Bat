# KnoQ Smart Bat — Final Components List

**Production-ready component selection with best-in-class options for MCU, IMU, and impact/sweet-spot detection.**

---

## Quick Reference Summary

| Category | Primary (Best) | Alternative (Budget) | Notes |
|----------|----------------|----------------------|-------|
| **MCU** | ESP32-WROOM-32E | nRF52840 module | ESP32: ecosystem, availability. nRF: ultra-low power |
| **IMU** | ICM-45686 | ICM-20649 | ICM-45686: best motion tracking. ICM-20649: ±30g, high impact |
| **Impact / Sweet Spot** | 4× Ceramic Piezo (27mm) + potting | PVDF film (custom) | Piezo: triangulation. PVDF: flexible, research-grade |
| **High-G Impact (optional)** | ADXL375 | — | ±200g for extreme impact backup |

---

## 1. Microcontroller (MCU)

### 1.1 Primary: ESP32-WROOM-32E

| Parameter | Value |
|-----------|-------|
| **Part** | ESP32-WROOM-32E |
| **Vendor** | Espressif Systems |
| **Core** | Dual-core Xtensa LX6 @ 240 MHz |
| **Flash** | 4 MB |
| **RAM** | 520 KB SRAM |
| **Wireless** | Wi-Fi 802.11 b/g/n + Bluetooth 4.2 BR/EDR + BLE |
| **Package** | Module, 18×25.5×3.1 mm |
| **Certification** | FCC, CE, TELEC (pre-certified) |
| **Price** | ~₹250–350 (volume) |

**Why:** Widely available in India, mature ecosystem, pre-certified RF, dual-core for sensor fusion + BLE. Wi-Fi enables future OTA updates.

**Where to buy:** Robu.in, ProtoCentral, Mouser India, LCSC

---

### 1.2 Alternative: nRF52840 Module (BLE-Only, Ultra-Low Power)

| Parameter | Value |
|-----------|-------|
| **Part** | nRF52840 (e.g., Raytac MDBT50Q-P1M or Nordic nRF52840 SoC) |
| **Vendor** | Nordic Semiconductor |
| **Core** | ARM Cortex-M4F @ 64 MHz |
| **Flash** | 1 MB |
| **RAM** | 256 KB |
| **Wireless** | BLE 5.0 only (no Wi-Fi) |
| **Power** | ~5 µA sleep, ~50 µA/MHz active (vs ESP32 ~20 mA active) |
| **Price** | ~₹400–600 (module) |

**Why:** Best battery life for BLE-only. Ideal if bat sessions are long and battery size is constrained.

**Trade-off:** Different SDK (nRF Connect / Zephyr), smaller India ecosystem. Use if power is critical.

---

### 1.3 Not Recommended

- **ESP32-S3:** Overkill (dual-core, display features); higher power.
- **ESP32-C3/C6:** Single-core; ESP32-WROOM-32E has more headroom for sensor processing.
- **STM32WBA:** Good BLE, but less ecosystem for this use case.

---

## 2. Inertial Measurement Unit (IMU)

### 2.1 Primary: ICM-45686

| Parameter | Value |
|-----------|-------|
| **Part** | ICM-45686 |
| **Vendor** | TDK InvenSense |
| **Type** | 6-axis (3-axis accel + 3-axis gyro) |
| **Accelerometer** | ±2 to ±32g FSR, 70 µg/√Hz noise |
| **Gyroscope** | ±15.625 to ±4000 dps, 3.8 mdps/√Hz |
| **Output rate** | 1.56 Hz to 32 kHz |
| **Interface** | I2C, SPI, I3C |
| **Power** | 9.8 µA @ 25 Hz (ALP mode) |
| **Package** | 2.5×3×0.81 mm LGA |
| **Temp** | -40°C to +85°C |
| **Price** | ~₹500–700 |

**Why:** Top-rated for motion tracking (SlimeVR, research). ±32g handles bat swing + impact. Low noise, high ODR for fast swings. Designed for wearables/sports.

**Where to buy:** DigiKey, Mouser, LCSC

---

### 2.2 Alternative: ICM-20649 (High-Impact Focus)

| Parameter | Value |
|-----------|-------|
| **Part** | ICM-20649 |
| **Vendor** | TDK InvenSense |
| **Type** | 6-axis |
| **Accelerometer** | ±4 / ±8 / ±16 / ±30g |
| **Gyroscope** | ±500 / ±1000 / ±2000 / ±4000 dps |
| **Interface** | I2C 400 kHz, SPI 7 MHz |
| **FIFO** | 512 bytes |
| **Package** | 3×3×0.9 mm QFN-24 |
| **Temp** | -40°C to +85°C |
| **Price** | ~₹350–450 |

**Why:** ±30g accelerometer for high-impact. Cheaper than ICM-45686. Good for budget builds.

---

### 2.3 Not Recommended

- **MPU-6050:** ±16g max, older, avoid for new designs.
- **ICM-20948:** 9-axis but poorer motion-tracking performance per community testing.
- **BNO055/BNO085:** BNO055 EOL; BNO085 rated poorly for motion tracking.
- **LSM6DSV/LSM6DSR:** ±16g max — may clip on hard hits.

---

## 3. Impact / Sweet Spot Detection

### 3.1 Primary: 4× Ceramic Piezoelectric Disc Sensors

| Parameter | Value |
|-----------|-------|
| **Part** | Piezoelectric disc, 27 mm diameter |
| **Material** | PZT (lead zirconate titanate) ceramic |
| **Quantity** | 4 per bat |
| **Placement** | Bat face: top-left, top-right, bottom-left, bottom-right (around sweet spot) |
| **Output** | Voltage proportional to impact force |
| **Mounting** | Silicone potting + adhesive (encapsulation for durability) |
| **Price** | ~₹20–40 each (pack of 10) |

**Why:** Triangulation of impact point from which sensor vibrates first/strongest. Proven for sweet-spot detection. Low cost.

**Durability:** Encapsulate with silicone potting or polyetherimide lamination to avoid cracking and bond failure.

**Where to buy:** Amazon, Robu, local electronics (search "piezoelectric disc 27mm")

---

### 3.2 Optional Enhancement: ADXL375 (High-G Impact Backup)

| Parameter | Value |
|-----------|-------|
| **Part** | ADXL375 |
| **Vendor** | Analog Devices |
| **Type** | 3-axis accelerometer only |
| **Range** | ±200g fixed |
| **Shock survival** | 10,000g |
| **Interface** | I2C, SPI |
| **Use** | Backup impact detection; validates piezo; handles extreme hits |
| **Price** | ~₹400–600 |

**Why:** Catches very hard impacts that could saturate the IMU. Built-in shock detection. Optional for production.

---

### 3.3 Alternative: PVDF Film (Research / Custom)

| Parameter | Value |
|-----------|-------|
| **Material** | PVDF (polyvinylidene fluoride) film |
| **Advantage** | Flexible, low profile, used in table tennis smart rackets |
| **Use** | Row-column array for hit position + force |
| **Challenge** | Custom design, harder to source off-the-shelf |

**Why consider:** Used in research for hit location + spin. Better for custom/integrated designs.

**When to use:** Future iteration or custom bat design.

---

## 4. Power System

### 4.1 Battery

| Parameter | Value |
|-----------|-------|
| **Type** | Lithium Polymer (LiPo) |
| **Voltage** | 3.7 V |
| **Capacity** | 500–600 mAh |
| **Connector** | JST-PH 2-pin |
| **Certification** | BIS IS 16046 (Part 2) for India |
| **Price** | ~₹150–250 (BIS certified) |

---

### 4.2 Charging IC

| Parameter | Value |
|-----------|-------|
| **Part** | BQ24075 or BQ25606 |
| **Vendor** | Texas Instruments |
| **Input** | USB-C, 5 V |
| **Protection** | Overcharge, OVP, thermal |
| **Price** | ~₹80–120 |

---

### 4.3 USB Connector

| Parameter | Value |
|-----------|-------|
| **Type** | USB-C, through-hole or SMT |
| **Rating** | 5 V, 1–2 A |
| **Note** | Robust for training centre use |

---

## 5. Supporting Components

### 5.1 Voltage Regulation

- **LDO:** 3.3 V for MCU and sensors (e.g., AP2112K-3.3, AMS1117-3.3)
- **Current:** 500 mA minimum

### 5.2 Passives

- **Decoupling:** 100 nF + 10 µF per IC
- **Crystal:** 40 MHz for ESP32 (if not using module internal)

### 5.3 Connectors & Wiring

- **PCB to piezo:** Flexible silicone wire, strain relief
- **Battery:** JST-PH 2P connector

---

## 6. Complete BOM (Bill of Materials)

### Production Build (Single Unit)

| # | Component | Part / Spec | Qty | Est. Price (₹) |
|---|-----------|-------------|-----|----------------|
| 1 | MCU Module | ESP32-WROOM-32E | 1 | 300 |
| 2 | IMU | ICM-45686 (or ICM-20649) | 1 | 600 (or 400) |
| 3 | Impact sensors | Piezo disc 27 mm | 4 | 120 |
| 4 | Battery | LiPo 3.7V 500mAh, BIS certified | 1 | 200 |
| 5 | Charging IC | BQ24075 or BQ25606 | 1 | 100 |
| 6 | USB-C connector | Through-hole | 1 | 30 |
| 7 | LDO | 3.3V 500mA | 1 | 25 |
| 8 | Passives | Caps, resistors | — | 50 |
| 9 | PCB | 4-layer, 50×30 mm | 1 | 80 |
| 10 | Housing | TPU molded / 3D printed | 1 | 200 |
| 11 | Bat | Tennis cricket bat (OEM) | 1 | 1000 |
| | **Total (electronics + housing)** | | | **~2,705** |
| | **Total (with bat)** | | | **~3,705** |

*Prices approximate; volume discounts apply.*

---

## 7. Reframing / Alternative Ideas

### 7.1 IMU + Impact: Dual-Sensor Fusion

**Current:** IMU for swing; piezo for impact location.

**Enhancement:** Add ADXL375 for high-g impact. Use:
- **IMU (ICM-45686):** Swing path, bat speed, orientation
- **Piezo (4×):** Sweet-spot location (triangulation)
- **ADXL375:** Impact magnitude, validation, extreme hits

**Cost:** +₹400–600. **Benefit:** More robust impact detection.

---

### 7.2 Replace Piezo with Force-Sensitive Resistor (FSR) Array?

**FSR:** Measures pressure, not dynamic impact. Slower response.

**Verdict:** Not suitable. Piezo is correct for fast ball impact.

---

### 7.3 MCU: BLE-Only for Maximum Battery Life

If battery life is critical (e.g., 8+ hour academy sessions):

- Use **nRF52840** instead of ESP32
- Remove Wi-Fi; BLE only
- Expect 2–3× longer battery life

**Trade-off:** Different toolchain, less common in India.

---

### 7.4 IMU: Dedicated High-G for Impact

**Idea:** Use ICM-45686 for motion; add ADXL375 only for impact.

**Benefit:** ICM-45686 stays in normal range; ADXL375 handles shock.

**When:** If ICM-45686 clips or misbehaves on very hard hits during testing.

---

## 8. Sourcing Links (India)

| Component | Supplier | Notes |
|-----------|----------|-------|
| ESP32-WROOM-32E | Robu.in, ProtoCentral | Dev boards also for prototyping |
| ICM-45686 | DigiKey, Mouser | May need international |
| ICM-20649 | Mouser, LCSC | Check stock |
| Piezo 27mm | Amazon, Robu | Search "piezoelectric disc" |
| BQ24075 | Mouser, LCSC | TI part |
| LiPo BIS | Local battery pack maker | Must be BIS certified |
| PCB | JLCPCB, PCBWay | 4-layer, ENIG |

---

## 9. Final Recommendation

| Component | Recommended Part | Rationale |
|-----------|------------------|------------|
| **MCU** | ESP32-WROOM-32E | Availability, ecosystem, Wi-Fi for OTA |
| **IMU** | ICM-45686 | Best motion tracking, ±32g, sports-grade |
| **Impact** | 4× 27 mm ceramic piezo + silicone potting | Sweet-spot triangulation, low cost |
| **Optional** | ADXL375 | High-g backup if needed |
| **Power** | BIS LiPo 500mAh + BQ24075 + USB-C | Safety, durability |

---

*Document created from component research. Update prices and availability before ordering. Last updated: February 2025.*
