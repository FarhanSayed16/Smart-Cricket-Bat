# KnoQ Smart Bat — Firmware

## Requirements

- **Arduino IDE** or **PlatformIO** with **ESP32** board support.
- **Board:** ESP32 Dev Module (or your exact board).
- **Libraries:** None required (uses built-in `Wire`, `BLEDevice`, `BLEUtils`, `BLE2902`).

## Setup

1. Open `KnoQ_SmartBat/KnoQ_SmartBat.ino` in Arduino IDE.
2. Select board: **ESP32 Dev Module** (or your board).
3. Select the correct COM port.
4. Upload.

## Wiring

See project root **CONNECTIONS_LIST.md** for exact pin wiring (ESP32, ICM-20948, 3× piezo, TP4056, battery).

## Calibration

Edit these at the top of `KnoQ_SmartBat.ino`:

- `EFFECTIVE_RADIUS_M` — Distance (m) from bat rotation axis to IMU (e.g. 0.45–0.55).
- `PIEZO_THRESHOLD` — ADC counts above baseline to trigger impact (e.g. 200–500).
- `SWEET_SPOT_RATIO` — Centre piezo ≥ this fraction of sum ⇒ sweet spot (e.g. 0.5).

All formulas are in **CALCULATIONS_AND_ALGORITHMS.md** in the project root.

## BLE

- **Device name:** `KnoQ-SmartBat`
- **Service UUID:** `6e400001-b5a3-f393-e0a9-e50e24dcca9e`
- **Characteristic UUID:** `6e400002-b5a3-f393-e0a9-e50e24dcca9e` (Notify)
- **Packet:** 14-byte `ShotPacket` (timestamp_ms, bat_speed_kmh, power_index, timing_delta_ms, sweet_spot, confidence). See CALCULATIONS_AND_ALGORITHMS.md §12.

## Serial

At 115200 baud: prints "IMU OK", "Piezo baseline done", "BLE advertising", and per shot: `Shot: 72.5 km/h P=85 T=-12 ms SS=1 CF=2`.
