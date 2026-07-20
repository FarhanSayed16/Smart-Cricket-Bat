# KnoQ Smart Bat — Exact Final Connections List

**Pin-by-pin wiring for ESP32, ICM-20948, 3× TE piezo sensors, and TP4056 + battery.**

---

## 1. Power (Battery + TP4056 → ESP32)

| From | Pin | To | Pin |
|------|-----|-----|-----|
| **LiPo battery** | Red (+) | **TP4056 module** | **B+** |
| **LiPo battery** | Black (−) | **TP4056 module** | **B−** |
| **TP4056 module** | **OUT+** | **ESP32** | **VIN** (or 5V if your board accepts 3.7–4.2 V) |
| **TP4056 module** | **OUT−** | **ESP32** | **GND** |

**Note:** Do **not** connect USB and battery power to the ESP32 at the same time. Use either USB (for programming) or TP4056 OUT (for battery operation).

---

## 2. ICM-20948 9-DOF IMU → ESP32 (I2C)

| ICM-20948 (7SEMI module) | Wire to | ESP32 |
|--------------------------|---------|--------|
| **VCC** | 3.3 V | **3V3** |
| **GND** | GND | **GND** |
| **SDA** | I2C Data | **GPIO 21** (SDA) |
| **SCL** | I2C Clock | **GPIO 22** (SCL) |
| **AD0** | Address select | **GND** → I2C address **0x68** (or **3V3** → **0x69**) |
| **CS** | Not used in I2C | Leave **unconnected** (or tie to **3V3**) |
| **INT** | Optional interrupt | Leave **unconnected** for now (or later use e.g. **GPIO 4**) |

**I2C address:** With AD0 = GND → **0x68**; with AD0 = 3V3 → **0x69**.

---

## 3. TE Piezo Film Sensors (3×) → ESP32 (ADC)

Each piezo has **two leads**. Use a **1 MΩ resistor** per sensor as load (piezo is high impedance).

**Wiring per sensor:**
- **Piezo lead 1** → **1 MΩ resistor** → **GND**
- **Piezo lead 1** (same point as resistor) → **ESP32 ADC pin**
- **Piezo lead 2** → **GND**

| Sensor | Piezo lead 1 (signal) | 1 MΩ resistor | ESP32 pin |
|--------|------------------------|----------------|-----------|
| **Piezo 1** | To resistor + to ESP32 | Other end to **GND** | **GPIO 34** (ADC1_CH6) |
| **Piezo 2** | To resistor + to ESP32 | Other end to **GND** | **GPIO 35** (ADC1_CH7) |
| **Piezo 3** | To resistor + to ESP32 | Other end to **GND** | **GPIO 36** (ADC1_CH0) |

**Common:** All three **piezo lead 2** and all resistor ends → **same GND** as ESP32.

**Why GPIO 34, 35, 36:** They are ADC1 pins (work when WiFi is on). Use 12-bit ADC; scale 0–4095 to voltage (0–3.3 V with default attenuation).

**Optional:** If the signal is too small or noisy, add a voltage follower (op-amp, e.g. MCP6001) between each piezo junction and the ESP32 ADC pin.

---

## 4. Single GND (Common ground)

Connect together:
- ESP32 **GND**
- TP4056 **OUT−**
- ICM-20948 **GND**
- All three piezo **lead 2**
- All three **1 MΩ** resistor ends (the side not connected to piezo)

---

## 5. Summary Table (All Connections)

| # | From | From Pin | To | To Pin |
|---|------|----------|-----|--------|
| 1 | LiPo | + | TP4056 | B+ |
| 2 | LiPo | − | TP4056 | B− |
| 3 | TP4056 | OUT+ | ESP32 | VIN |
| 4 | TP4056 | OUT− | ESP32 | GND |
| 5 | ICM-20948 | VCC | ESP32 | 3V3 |
| 6 | ICM-20948 | GND | ESP32 | GND |
| 7 | ICM-20948 | SDA | ESP32 | GPIO 21 |
| 8 | ICM-20948 | SCL | ESP32 | GPIO 22 |
| 9 | ICM-20948 | AD0 | ESP32 | GND (or 3V3 for 0x69) |
| 10 | Piezo 1 | Lead 1 | 1 MΩ resistor → GND, and to ESP32 | GPIO 34 |
| 11 | Piezo 1 | Lead 2 | GND | — |
| 12 | Piezo 2 | Lead 1 | 1 MΩ resistor → GND, and to ESP32 | GPIO 35 |
| 13 | Piezo 2 | Lead 2 | GND | — |
| 14 | Piezo 3 | Lead 1 | 1 MΩ resistor → GND, and to ESP32 | GPIO 36 |
| 15 | Piezo 3 | Lead 2 | GND | — |

---

## 6. Parts Needed for Wiring

| Item | Qty | Notes |
|------|-----|--------|
| Jumper wires (F–F or M–F) | As needed | ESP32 ↔ IMU, ESP32 ↔ piezo, power |
| Resistor 1 MΩ | 3 | One per piezo (load to GND) |
| Breadboard (optional) | 1 | For prototyping before bat mount |

---

## 7. ESP32 Pin Reference (Quick)

| Function | GPIO | Note |
|----------|------|------|
| I2C SDA | 21 | ICM-20948 |
| I2C SCL | 22 | ICM-20948 |
| Piezo 1 (ADC) | 34 | Input only, ADC1_CH6 |
| Piezo 2 (ADC) | 35 | Input only, ADC1_CH7 |
| Piezo 3 (ADC) | 36 | Input only, ADC1_CH0 |
| Power | 3V3 | For IMU (and AD0 if 0x69) |
| Ground | GND | Common |
| Battery in | VIN | From TP4056 OUT+ |

---

## 8. Schematic (Text Diagram)

```
                    LiPo 3.7V
                    +  −
                     \/
              B+  B−  (TP4056)  OUT+  OUT−
                \  /              \   /
                 \/                \ /
                    TP4056    →   ESP32 VIN, GND

ESP32 3V3 ──────────► ICM-20948 VCC
ESP32 GND ◄────────── ICM-20948 GND, Piezo lead 2 (all), 1MΩ (all)
ESP32 GPIO21 ◄──────► ICM-20948 SDA
ESP32 GPIO22 ◄──────► ICM-20948 SCL
ESP32 GND ──────────► ICM-20948 AD0   (I2C addr 0x68)

Piezo1 lead1 ──┬── 1MΩ ── GND
               └──────────────► ESP32 GPIO34
Piezo1 lead2 ──────────────── GND

Piezo2 lead1 ──┬── 1MΩ ── GND
               └──────────────► ESP32 GPIO35
Piezo2 lead2 ──────────────── GND

Piezo3 lead1 ──┬── 1MΩ ── GND
               └──────────────► ESP32 GPIO36
Piezo3 lead2 ──────────────── GND
```

---

*Use this as the single reference for wiring. Double-check your ESP32 board’s VIN/5V label before connecting battery.*
