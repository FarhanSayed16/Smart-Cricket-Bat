# KnoQ V1 — Calibration & Tuning Guide

## Step 1 — First boot (Serial monitor at 115200)

Watch for:
```
[CAL] Calibrating baseline (keep bat still)...
[CAL] Baseline=142  Threshold=568
[OK] Ready. Hit the bat!
```

If baseline > 400: your ADC pins are picking up noise.
Check: Are you using ADC1 pins only (34, 35, 36)?
Check: Is 1MΩ bleed resistor connected from each sensor pin to GND?

---

## Step 2 — Tap test (finger tap on sensor)

Tap each sensor gently with finger. You should see:
```
  HIT #1
  Zone   : top      ← finger on S1
  Power  : 12%
```

If no hit detected → threshold too high.
Lower HIT_MULTIPLIER from 4.0 to 3.0 in main.cpp.

If hits fire when bat is resting → threshold too low.
Raise HIT_MULTIPLIER from 4.0 to 5.0.

---

## Step 3 — Ball hit calibration

Do 10 real hits with ball. Note the Raw values printed:
```
  Raw    : S1=1840 S2=620 S3=590
```

Find your typical max value for a hard hit.
Set POWER_MAX_RAW in main.cpp to that value.
A soft tap should be around POWER_MIN_RAW (200).

---

## Step 4 — Zone validation

Hit deliberately:
- Top of bat    → should say "top"
- Left edge     → should say "left"
- Right edge    → should say "right"
- Sweet spot    → should say "sweet"
- Toe           → should say "bottom"

If zones are wrong:
- Check your physical sensor positions match S1=center-top, S2=left, S3=right
- Adjust ZONE_DOMINANT (default 0.50) — raise if too many sweet spots
- Adjust ZONE_LOW_THRESH (default 0.22) — raise if bottom never triggers

---

## Step 5 — SERIAL_RAW debug mode

In main.cpp, set:
```cpp
#define SERIAL_RAW true
```

This prints every loop iteration:
```
RAW S1: 142 S2: 138 S3: 145 | gyro:2.1 | base:141 thr:566
```

Use this to:
- See if baseline is stable (should barely move when bat is still)
- Watch values rise when you tap a sensor
- Confirm threshold is above quiet noise floor

Set back to false for normal use.

---

## Quick tuning reference

| Problem                        | Fix                                      |
|--------------------------------|------------------------------------------|
| Missing hits                   | Lower HIT_MULTIPLIER (try 3.0)           |
| False hits when resting        | Raise HIT_MULTIPLIER (try 5.0)           |
| Everything shows "sweet spot"  | Raise ZONE_DOMINANT (try 0.60)           |
| Sweet spot never triggers      | Lower ZONE_DOMINANT (try 0.45)           |
| Power always 100%              | Raise POWER_MAX_RAW                      |
| Power always 0%                | Lower POWER_MIN_RAW                      |
| Baseline drifts up over time   | Lower BASELINE_ALPHA (try 0.02)          |
| Baseline slow to settle        | Raise BASELINE_ALPHA (try 0.10)          |
| Multiple hits per ball strike  | Raise DEBOUNCE_MS (try 700)              |

---

## BLE testing (Android)

1. Install "Serial Bluetooth Terminal" or "nRF Connect" from Play Store
2. Scan for "KnoQ-Bat-V1"
3. Connect → subscribe to TX characteristic
4. Hit bat → JSON appears on phone:

```json
{"hit":1,"zone":"sweet","power":78,"swing":142.3,"sweet_pct":100,"avg_power":78,"total_hits":1}
```

---

## Known V1 limitations (fix in V2)

- No op-amp buffer: if signal is weak, add LMV321 voltage follower per channel
- Power is piezo-only: not fused with IMU gyro data yet
- No persistent storage: session stats reset on power cycle
- BLE packet rate: ~1 packet per hit (not streaming)
