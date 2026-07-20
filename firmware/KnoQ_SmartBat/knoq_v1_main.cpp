/*
 * ============================================================
 *  KnoQ Smart Cricket Bat — V1 Firmware
 *  Target:   ESP32 (Arduino framework)
 *  Sensors:  3x Piezo (ADC1), MPU-9250 (I2C)
 *  Output:   Serial (always) + BLE UART (optional)
 * ============================================================
 *
 *  WIRING SUMMARY
 *  ──────────────
 *  Piezo S1  → GPIO34  (ADC1_CH6)  via 1MΩ bleed to GND
 *  Piezo S2  → GPIO35  (ADC1_CH7)  via 1MΩ bleed to GND
 *  Piezo S3  → GPIO36  (ADC1_CH0)  via 1MΩ bleed to GND
 *  MPU-9250 SDA → GPIO21
 *  MPU-9250 SCL → GPIO22
 *  MPU-9250 VCC → 3.3V
 *  MPU-9250 GND → GND
 *  Battery  → TP4056 → ESP32 VIN
 *  All GNDs tied together (star point)
 *
 *  SENSOR PLACEMENT (back/spine of bat)
 *  ──────────────────────────────────────
 *  S1: 22–24 cm from top, center
 *  S2: 32–35 cm from top, 4–5 cm LEFT of center
 *  S3: 32–35 cm from top, 4–5 cm RIGHT of center
 *
 *  SERIAL MONITOR
 *  ──────────────
 *  Baud: 115200
 *  Format: human-readable + JSON per hit
 * ============================================================
 */

// ─── Library includes ────────────────────────────────────────
#include <Arduino.h>
#include <Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// ─── Feature flags ───────────────────────────────────────────
#define ENABLE_BLE        true   // set false to skip BLE entirely
#define ENABLE_MPU        true   // set false if MPU-9250 not wired yet
#define SERIAL_RAW        false  // set true to print raw ADC values every loop

// ─── Pin definitions ─────────────────────────────────────────
#define PIN_S1            34     // ADC1_CH6 — center sensor
#define PIN_S2            35     // ADC1_CH7 — left sensor
#define PIN_S3            36     // ADC1_CH0 — right sensor

// ─── MPU-9250 I2C ────────────────────────────────────────────
#define MPU_ADDR          0x68   // AD0 low; use 0x69 if AD0 pulled high
#define MPU_PWR_MGMT_1    0x6B
#define MPU_GYRO_CFG      0x1B
#define MPU_ACCEL_CFG     0x1C
#define MPU_GYRO_XOUT_H   0x43
#define MPU_ACCEL_XOUT_H  0x3B
#define GYRO_SCALE        131.0f // LSB/(°/s) at ±250°/s range
#define ACCEL_SCALE       16384.0f // LSB/g at ±2g range

// ─── ADC config ──────────────────────────────────────────────
#define ADC_RESOLUTION    12     // bits → 0–4095
#define ADC_SAMPLES       4      // oversample and average for noise reduction

// ─── Detection thresholds ────────────────────────────────────
#define BASELINE_INIT     150    // starting assumed quiet baseline (raw ADC)
#define HIT_MULTIPLIER    4.0f   // hit = reading > baseline × this
#define BASELINE_ALPHA    0.05f  // EMA smoothing for baseline (lower = slower)
#define DEBOUNCE_MS       500    // ms to ignore after a hit is registered
#define SWING_GYRO_THRESH 80.0f  // °/s — above this = bat is swinging

// ─── Zone detection ──────────────────────────────────────────
#define ZONE_DOMINANT     0.50f  // ratio above which one sensor "owns" the hit
#define ZONE_LOW_THRESH   0.22f  // ratio below which a sensor is "not active"

// ─── Power scaling ───────────────────────────────────────────
#define POWER_MIN_RAW     200    // raw ADC value → 0% power (soft tap)
#define POWER_MAX_RAW     3800   // raw ADC value → 100% power (full hit)
                                 // adjust after calibration phase

// ─── BLE UUIDs (Nordic UART Service) ────────────────────────
#define BLE_SERVICE_UUID  "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define BLE_TX_UUID       "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
#define BLE_RX_UUID       "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define BLE_DEVICE_NAME   "KnoQ-Bat-V1"

// ─── Session stats ───────────────────────────────────────────
struct SessionStats {
  uint16_t totalHits       = 0;
  uint16_t sweetSpotHits   = 0;
  uint16_t topHits         = 0;
  uint16_t leftHits        = 0;
  uint16_t rightHits       = 0;
  uint16_t bottomHits      = 0;
  uint32_t powerSum        = 0;
  uint8_t  peakPower       = 0;
  uint32_t sessionStartMs  = 0;
};

// ─── Global state ────────────────────────────────────────────
float     baseline         = BASELINE_INIT;
float     dynamicThreshold = BASELINE_INIT * HIT_MULTIPLIER;
uint32_t  lastHitMs        = 0;
bool      swinging         = false;
SessionStats session;

// BLE
BLEServer*          pServer     = nullptr;
BLECharacteristic*  pTxChar     = nullptr;
bool                bleConnected = false;

// ─── MPU-9250 raw data ───────────────────────────────────────
struct ImuData {
  float ax, ay, az;    // g
  float gx, gy, gz;    // °/s
  float gyroMag;       // magnitude °/s
};

// ═══════════════════════════════════════════════════════════════
//  UTILITY: read ADC with oversampling
// ═══════════════════════════════════════════════════════════════
int readADC(uint8_t pin) {
  uint32_t sum = 0;
  for (int i = 0; i < ADC_SAMPLES; i++) {
    sum += analogRead(pin);
    delayMicroseconds(50);
  }
  return (int)(sum / ADC_SAMPLES);
}

// ═══════════════════════════════════════════════════════════════
//  MPU-9250: write register
// ═══════════════════════════════════════════════════════════════
void mpuWrite(uint8_t reg, uint8_t val) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  Wire.write(val);
  Wire.endTransmission();
}

// ═══════════════════════════════════════════════════════════════
//  MPU-9250: read N bytes from reg into buf
// ═══════════════════════════════════════════════════════════════
bool mpuRead(uint8_t reg, uint8_t* buf, uint8_t len) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  if (Wire.endTransmission(false) != 0) return false;
  Wire.requestFrom((uint8_t)MPU_ADDR, len);
  if (Wire.available() < len) return false;
  for (int i = 0; i < len; i++) buf[i] = Wire.read();
  return true;
}

// ═══════════════════════════════════════════════════════════════
//  MPU-9250: init
// ═══════════════════════════════════════════════════════════════
bool mpuInit() {
  Wire.begin(21, 22);           // SDA=21, SCL=22
  Wire.setClock(400000);

  // Wake up
  mpuWrite(MPU_PWR_MGMT_1, 0x00);
  delay(100);

  // Verify WHO_AM_I (0x75 register → should return 0x71 for MPU-9250)
  uint8_t whoami = 0;
  mpuRead(0x75, &whoami, 1);
  if (whoami != 0x71 && whoami != 0x73) {
    Serial.printf("[MPU] WHO_AM_I = 0x%02X — expected 0x71 or 0x73\n", whoami);
    Serial.println("[MPU] Check wiring. Continuing without IMU.");
    return false;
  }
  Serial.printf("[MPU] Found MPU-9250 (0x%02X)\n", whoami);

  mpuWrite(MPU_GYRO_CFG,  0x00); // ±250°/s
  mpuWrite(MPU_ACCEL_CFG, 0x00); // ±2g
  delay(10);
  return true;
}

// ═══════════════════════════════════════════════════════════════
//  MPU-9250: read accel + gyro
// ═══════════════════════════════════════════════════════════════
ImuData mpuReadData() {
  ImuData d = {};
  uint8_t buf[14];
  if (!mpuRead(MPU_ACCEL_XOUT_H, buf, 14)) return d;

  int16_t ax_raw = (int16_t)((buf[0]  << 8) | buf[1]);
  int16_t ay_raw = (int16_t)((buf[2]  << 8) | buf[3]);
  int16_t az_raw = (int16_t)((buf[4]  << 8) | buf[5]);
  int16_t gx_raw = (int16_t)((buf[8]  << 8) | buf[9]);
  int16_t gy_raw = (int16_t)((buf[10] << 8) | buf[11]);
  int16_t gz_raw = (int16_t)((buf[12] << 8) | buf[13]);

  d.ax = ax_raw / ACCEL_SCALE;
  d.ay = ay_raw / ACCEL_SCALE;
  d.az = az_raw / ACCEL_SCALE;
  d.gx = gx_raw / GYRO_SCALE;
  d.gy = gy_raw / GYRO_SCALE;
  d.gz = gz_raw / GYRO_SCALE;
  d.gyroMag = sqrt(d.gx*d.gx + d.gy*d.gy + d.gz*d.gz);
  return d;
}

// ═══════════════════════════════════════════════════════════════
//  BLE: server callbacks
// ═══════════════════════════════════════════════════════════════
class BLEServerCB : public BLEServerCallbacks {
  void onConnect(BLEServer* s) override {
    bleConnected = true;
    Serial.println("[BLE] Client connected");
  }
  void onDisconnect(BLEServer* s) override {
    bleConnected = false;
    Serial.println("[BLE] Client disconnected — restarting advertising");
    s->startAdvertising();
  }
};

// ═══════════════════════════════════════════════════════════════
//  BLE: init
// ═══════════════════════════════════════════════════════════════
void bleInit() {
  BLEDevice::init(BLE_DEVICE_NAME);
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new BLEServerCB());

  BLEService* svc = pServer->createService(BLE_SERVICE_UUID);

  pTxChar = svc->createCharacteristic(
    BLE_TX_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pTxChar->addDescriptor(new BLE2902());

  // RX (phone → bat) — not used in V1 but scaffold is here
  BLECharacteristic* pRxChar = svc->createCharacteristic(
    BLE_RX_UUID,
    BLECharacteristic::PROPERTY_WRITE
  );
  (void)pRxChar;

  svc->start();

  BLEAdvertising* adv = BLEDevice::getAdvertising();
  adv->addServiceUUID(BLE_SERVICE_UUID);
  adv->setScanResponse(true);
  adv->setMinPreferred(0x06);
  BLEDevice::startAdvertising();
  Serial.printf("[BLE] Advertising as '%s'\n", BLE_DEVICE_NAME);
}

// ═══════════════════════════════════════════════════════════════
//  BLE: send string
// ═══════════════════════════════════════════════════════════════
void bleSend(const char* msg) {
  if (!ENABLE_BLE || !bleConnected || !pTxChar) return;
  pTxChar->setValue((uint8_t*)msg, strlen(msg));
  pTxChar->notify();
}

// ═══════════════════════════════════════════════════════════════
//  ZONE DETECTION — ratio-based
// ═══════════════════════════════════════════════════════════════
const char* detectZone(int v1, int v2, int v3) {
  float total = (float)(v1 + v2 + v3);
  if (total < 1.0f) return "unknown";

  float r1 = v1 / total;
  float r2 = v2 / total;
  float r3 = v3 / total;

  // One sensor clearly dominant
  if (r1 > ZONE_DOMINANT) return "top";
  if (r2 > ZONE_DOMINANT) return "left";
  if (r3 > ZONE_DOMINANT) return "right";

  // S1 is very weak → low on bat (toe)
  if (r1 < ZONE_LOW_THRESH) return "bottom";

  // All three reasonably balanced → sweet spot
  return "sweet";
}

// ═══════════════════════════════════════════════════════════════
//  POWER CALCULATION — normalized 0–100
// ═══════════════════════════════════════════════════════════════
uint8_t calcPower(int maxVal) {
  int clamped = constrain(maxVal, POWER_MIN_RAW, POWER_MAX_RAW);
  int mapped  = map(clamped, POWER_MIN_RAW, POWER_MAX_RAW, 0, 100);
  return (uint8_t)mapped;
}

// ═══════════════════════════════════════════════════════════════
//  UPDATE BASELINE — exponential moving average
//  Only update when bat is quiet (no hit in progress)
// ═══════════════════════════════════════════════════════════════
void updateBaseline(int v1, int v2, int v3) {
  float currentMax = (float)max({v1, v2, v3});
  baseline = (baseline * (1.0f - BASELINE_ALPHA)) + (currentMax * BASELINE_ALPHA);
  dynamicThreshold = baseline * HIT_MULTIPLIER;

  // Clamp threshold to reasonable range
  dynamicThreshold = constrain(dynamicThreshold, 300.0f, 2500.0f);
}

// ═══════════════════════════════════════════════════════════════
//  PROCESS HIT — called once per confirmed hit
// ═══════════════════════════════════════════════════════════════
void processHit(int v1, int v2, int v3, float gyroMag) {
  int maxVal        = max({v1, v2, v3});
  const char* zone  = detectZone(v1, v2, v3);
  uint8_t power     = calcPower(maxVal);

  // Update session stats
  session.totalHits++;
  session.powerSum += power;
  if (power > session.peakPower) session.peakPower = power;

  if      (strcmp(zone, "sweet")  == 0) session.sweetSpotHits++;
  else if (strcmp(zone, "top")    == 0) session.topHits++;
  else if (strcmp(zone, "left")   == 0) session.leftHits++;
  else if (strcmp(zone, "right")  == 0) session.rightHits++;
  else if (strcmp(zone, "bottom") == 0) session.bottomHits++;

  uint8_t sweetPct = (session.totalHits > 0)
    ? (uint8_t)(session.sweetSpotHits * 100 / session.totalHits)
    : 0;
  uint8_t avgPower = (session.totalHits > 0)
    ? (uint8_t)(session.powerSum / session.totalHits)
    : 0;

  // ── Serial output ──────────────────────────────────────────
  Serial.println("──────────────────────────");
  Serial.printf("  HIT #%d\n", session.totalHits);
  Serial.printf("  Zone   : %s\n", zone);
  Serial.printf("  Power  : %d%%\n", power);
  Serial.printf("  Swing  : %.1f °/s\n", gyroMag);
  Serial.printf("  Raw    : S1=%d S2=%d S3=%d\n", v1, v2, v3);
  Serial.printf("  Base   : %.0f  Thresh: %.0f\n", baseline, dynamicThreshold);
  Serial.println("  — Session —");
  Serial.printf("  Sweet%%  : %d%%  AvgPow: %d%%  Peak: %d%%\n",
                sweetPct, avgPower, session.peakPower);
  Serial.println("──────────────────────────");

  // ── JSON for BLE / app ─────────────────────────────────────
  char json[256];
  snprintf(json, sizeof(json),
    "{\"hit\":%d,\"zone\":\"%s\",\"power\":%d,"
    "\"swing\":%.1f,\"sweet_pct\":%d,\"avg_power\":%d,"
    "\"total_hits\":%d}\n",
    session.totalHits, zone, power,
    gyroMag, sweetPct, avgPower, session.totalHits
  );
  bleSend(json);
  Serial.print("[JSON] "); Serial.print(json);
}

// ═══════════════════════════════════════════════════════════════
//  PRINT SESSION SUMMARY
// ═══════════════════════════════════════════════════════════════
void printSessionSummary() {
  if (session.totalHits == 0) return;
  uint32_t elapsed = (millis() - session.sessionStartMs) / 1000;
  uint8_t avgPower  = (uint8_t)(session.powerSum / session.totalHits);
  uint8_t sweetPct  = (uint8_t)(session.sweetSpotHits * 100 / session.totalHits);

  Serial.println("\n╔══════════════════════════════╗");
  Serial.println("║      SESSION SUMMARY         ║");
  Serial.println("╚══════════════════════════════╝");
  Serial.printf("  Duration    : %lu s\n",   elapsed);
  Serial.printf("  Total hits  : %d\n",      session.totalHits);
  Serial.printf("  Sweet spot  : %d (%d%%)\n", session.sweetSpotHits, sweetPct);
  Serial.printf("  Top hits    : %d\n",      session.topHits);
  Serial.printf("  Left hits   : %d\n",      session.leftHits);
  Serial.printf("  Right hits  : %d\n",      session.rightHits);
  Serial.printf("  Bottom hits : %d\n",      session.bottomHits);
  Serial.printf("  Avg power   : %d%%\n",    avgPower);
  Serial.printf("  Peak power  : %d%%\n",    session.peakPower);
  Serial.println("══════════════════════════════");

  char summary[256];
  snprintf(summary, sizeof(summary),
    "{\"summary\":true,\"total\":%d,\"sweet_pct\":%d,"
    "\"avg_power\":%d,\"peak_power\":%d,\"duration_s\":%lu}\n",
    session.totalHits, sweetPct, avgPower,
    session.peakPower, elapsed
  );
  bleSend(summary);
}

// ═══════════════════════════════════════════════════════════════
//  SETUP
// ═══════════════════════════════════════════════════════════════
void setup() {
  Serial.begin(115200);
  delay(500);

  Serial.println("\n╔══════════════════════════════╗");
  Serial.println("║   KnoQ Smart Bat — V1        ║");
  Serial.println("╚══════════════════════════════╝");

  // ADC config
  analogReadResolution(ADC_RESOLUTION);
  analogSetAttenuation(ADC_11db); // 0–3.3V range

  // Warm up ADC — first few readings after boot are unstable
  for (int i = 0; i < 20; i++) {
    analogRead(PIN_S1); analogRead(PIN_S2); analogRead(PIN_S3);
    delay(5);
  }
  Serial.println("[ADC] Pins 34, 35, 36 ready (ADC1)");

  // MPU-9250
  bool mpuOk = false;
  if (ENABLE_MPU) {
    mpuOk = mpuInit();
    if (!mpuOk) Serial.println("[MPU] Running without IMU — gyro data = 0");
  }

  // BLE
  if (ENABLE_BLE) bleInit();

  // Baseline warm-up — 200 readings to establish quiet floor
  Serial.println("[CAL] Calibrating baseline (keep bat still)...");
  float sum = 0;
  for (int i = 0; i < 200; i++) {
    int v1 = readADC(PIN_S1);
    int v2 = readADC(PIN_S2);
    int v3 = readADC(PIN_S3);
    sum += max({v1, v2, v3});
    delay(5);
  }
  baseline = sum / 200.0f;
  dynamicThreshold = baseline * HIT_MULTIPLIER;
  Serial.printf("[CAL] Baseline=%.0f  Threshold=%.0f\n", baseline, dynamicThreshold);

  session.sessionStartMs = millis();
  Serial.println("[OK] Ready. Hit the bat!\n");
}

// ═══════════════════════════════════════════════════════════════
//  MAIN LOOP
// ═══════════════════════════════════════════════════════════════
void loop() {
  uint32_t now = millis();

  // ── Read piezo sensors ───────────────────────────────────────
  int v1 = readADC(PIN_S1);
  int v2 = readADC(PIN_S2);
  int v3 = readADC(PIN_S3);
  int maxVal = max({v1, v2, v3});

  // ── Read IMU ─────────────────────────────────────────────────
  ImuData imu = {};
  if (ENABLE_MPU) imu = mpuReadData();
  swinging = (imu.gyroMag > SWING_GYRO_THRESH);

  // ── Raw debug print (optional) ───────────────────────────────
  if (SERIAL_RAW) {
    Serial.printf("RAW S1:%4d S2:%4d S3:%4d | gyro:%.1f | base:%.0f thr:%.0f\n",
                  v1, v2, v3, imu.gyroMag, baseline, dynamicThreshold);
  }

  // ── HIT DETECTION ────────────────────────────────────────────
  bool debounceOk = (now - lastHitMs) > DEBOUNCE_MS;

  if (maxVal > dynamicThreshold && debounceOk) {
    lastHitMs = now;
    processHit(v1, v2, v3, imu.gyroMag);

    // Print summary every 10 hits
    if (session.totalHits % 10 == 0) {
      printSessionSummary();
    }
  }
  else {
    // Quiet period — update baseline slowly
    // Only update if clearly below threshold (not ringing from a hit)
    if (maxVal < dynamicThreshold * 0.5f) {
      updateBaseline(v1, v2, v3);
    }
  }

  // ── Loop timing ──────────────────────────────────────────────
  // ADC + IMU read takes ~2ms; 3ms delay → ~200Hz effective sample rate
  delay(3);
}
