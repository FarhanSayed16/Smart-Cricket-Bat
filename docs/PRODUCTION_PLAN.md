# KnoQ Smart Bat — Production Plan

**A complete production-level plan for manufacturing and selling the Smart Bat to cricket training centres and academies.**

> **Related:** See [PROJECT_UNDERSTANDING.md](PROJECT_UNDERSTANDING.md) for product vision, features, and technical architecture.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Production Hardware Specification](#2-production-hardware-specification)
3. [Custom PCB Design](#3-custom-pcb-design)
4. [Housing & Enclosure](#4-housing--enclosure)
5. [Bat Manufacturing](#5-bat-manufacturing)
6. [Production Software Stack](#6-production-software-stack)
7. [Quality Assurance & Testing](#7-quality-assurance--testing)
8. [Certifications & Compliance](#8-certifications--compliance)
9. [Business Model for Training Centres](#9-business-model-for-training-centres)
10. [Pricing Strategy](#10-pricing-strategy)
11. [Supply Chain & Sourcing](#11-supply-chain--sourcing)
12. [Manufacturing Timeline](#12-manufacturing-timeline)
13. [Go-to-Market for Training Centres](#13-go-to-market-for-training-centres)
14. [Warranty, Support & After-Sales](#14-warranty-support--after-sales)
15. [Risk Mitigation](#15-risk-mitigation)

---

## 1. Executive Summary

### 1.1 Objective

Transition KnoQ Smart Bat from **prototype** to **production-grade product** for sale to cricket training centres, academies, and sports clubs across India.

### 1.2 Key Production Differentiators

| Aspect | Prototype | Production |
|--------|-----------|------------|
| **MCU** | ESP32 Dev Board | ESP32-WROOM-32E module (soldered) |
| **PCB** | Breadboard / hand-wired | Custom 4-layer PCB, SMT assembly |
| **Housing** | 3D-printed | Injection-molded TPU/silicone |
| **Battery** | Generic LiPo | BIS-certified LiPo (IS 16046) |
| **Piezo** | Bare discs | Potting/encapsulation for durability |
| **Testing** | Ad-hoc | Drop, shock, vibration, environmental |
| **Certification** | None | BIS, CE (export), battery CRS |

### 1.3 Target Customers (B2B Focus)

- Cricket academies (5–50 bats per centre)
- Sports clubs and training facilities
- School/college cricket programmes
- State/district cricket associations
- Corporate cricket leagues

---

## 2. Production Hardware Specification

### 2.1 Microcontroller (MCU)

| Parameter | Prototype | Production | Rationale |
|-----------|-----------|------------|------------|
| **Part** | ESP32-WROOM-32 Dev Board | **ESP32-WROOM-32E** or **ESP32-WROOM-32UE** module | Pre-certified (FCC, CE); no USB connector; smaller footprint |
| **Flash** | 4 MB | 4 MB (32E) or 8 MB (32UE) | 32UE for OTA updates, future features |
| **Antenna** | PCB antenna (dev board) | PCB antenna (module) or external | PCB antenna sufficient for BLE range |
| **Source** | Generic | Espressif official / authorized distributor | Traceability, quality |

**Why module over SoC:** Pre-certified modules avoid costly RF certification. Custom SoC only at 100K+ volume.

### 2.2 Inertial Measurement Unit (IMU)

| Parameter | Prototype | Production | Rationale |
|-----------|-----------|------------|------------|
| **Primary** | BNO055 (discontinued) | **ICM-20948** (TDK InvenSense) | BNO055 EOL; ICM-20948 hermetically sealed, -40°C to +85°C, low power |
| **Alternative** | MPU-6050 | **MPU-6050** (InvenSense) | Cheaper; requires software fusion |
| **Package** | Breakout board | Direct SMT on PCB | Smaller, fewer failure points |

**Recommendation:** ICM-20948 for production — 9-axis, industrial temp range, hermetically sealed MEMS.

### 2.3 Impact Sensors (Piezoelectric)

| Parameter | Prototype | Production | Rationale |
|-----------|-----------|------------|------------|
| **Part** | Generic 27mm piezo disc | **Ruggedized piezo** or **encapsulated** | Potting/lamination for durability (research: polyetherimide lamination) |
| **Quantity** | 3–4 per bat | 4 per bat (redundancy) | Better triangulation; one failure still works |
| **Mounting** | Adhesive tape | Silicone potting + adhesive | Protects from moisture, vibration, bond failure |
| **Signal** | Direct to MCU | Amplifier + filter (optional) | Cleaner signal, less noise |

**Durability:** Encapsulation critical — sensor cracking and bond failure are main failure modes under impact.

### 2.4 Power System

| Parameter | Prototype | Production | Rationale |
|-----------|-----------|------------|------------|
| **Battery** | Generic 400–500mAh LiPo | **BIS-certified LiPo** (IS 16046 Part 2) | Mandatory for India; use certified cell/pack |
| **Capacity** | 400–500mAh | 500–600mAh | Longer session time for training centres |
| **Connector** | JST-PH 2P | JST-PH 2P or custom | Standard, reliable |
| **Charging IC** | TP4056 | **BQ24075** or **BQ25606** | Industry standard; overcharge, OVP, thermal protection |
| **USB** | Micro-USB / USB-C | **USB-C** only | Future-proof; training centre durability |

**BIS for battery:** IS 16046 (Part 2): 2018 — mandatory for portable LiPo in India. Plan 4–6 months for certification.

### 2.5 Production Hardware Bill of Materials (BOM) Summary

| Component | Part Number / Spec | Qty | Notes |
|-----------|-------------------|-----|-------|
| MCU Module | ESP32-WROOM-32E or 32UE | 1 | 4-layer PCB, keep antenna clearance |
| IMU | ICM-20948 (QFN) or MPU-6050 | 1 | ICM preferred |
| Piezo | 27mm encapsulated / potted | 4 | With amplifier if needed |
| Battery | 3.7V 500mAh LiPo, BIS certified | 1 | JST-PH 2P |
| Charging IC | BQ24075 or BQ25606 | 1 | USB-C input |
| USB-C Connector | Through-hole or SMT | 1 | Robust for training use |
| Passives | 0402/0603 | As per schematic | Standard |
| Housing | Injection-molded TPU | 1 | See Section 4 |

---

## 3. Custom PCB Design

### 3.1 PCB Specifications

| Parameter | Specification |
|-----------|---------------|
| **Layers** | 4-layer (signal, GND, PWR, signal) |
| **Thickness** | 1.6 mm |
| **Material** | FR4, Tg 150°C+ |
| **Copper** | 1 oz (inner), 1 oz (outer) |
| **Finish** | ENIG (gold) for reliability |
| **Size** | Target: < 50mm × 30mm (fits in bat spine cavity) |

### 3.2 Design Considerations

- **Antenna keep-out:** Follow Espressif layout guidelines for ESP32 module
- **Shock/vibration:** Use larger vias, no 90° traces; strain relief on connectors
- **Moisture:** Conformal coating (optional) for sweat/humidity
- **Test points:** Include for factory testing (power, BLE, IMU, piezo)

### 3.3 Assembly

- **SMT:** JLCPCB, PCBWay, or local EMS (India: Kaynes, Syrma, etc.)
- **Stencil:** Laser-cut for paste
- **Reflow:** Lead-free (SAC305) profile
- **Programming:** JTAG/SWD or UART header for firmware flash; or pre-programmed at factory

---

## 4. Housing & Enclosure

### 4.1 Material Selection

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| **Injection-molded TPU** | Flexible, shock-absorbent, durable | Tooling cost (~₹2–5L) | **Best for 1000+ units** |
| **Injection-molded silicone** | Excellent shock absorption | Higher cost, complex molding | Premium tier |
| **CNC-machined aluminium + rubber insert** | Strong, professional | Heavier, expensive | Not recommended (weight) |
| **3D-printed TPU (batch)** | Low tooling, flexible | Slower, less consistent | **For 100–500 units** |

### 4.2 Design Requirements

- **Shock absorption:** Minimum 20G shock rating (ball impact)
- **Weight:** Total electronics + housing < 60g (bat balance)
- **Placement:** Spine of bat, offset from face; NOT on edge, toe, sweet spot
- **Foam isolation:** Between PCB and housing walls
- **IP rating:** IP54 minimum (splash, dust) — sweat, outdoor use

### 4.3 Cavity in Bat

- **Dimensions:** Match housing + 2mm clearance
- **Depth:** Housing flush or slightly recessed
- **Sealing:** Silicone gasket or adhesive seal to prevent moisture ingress

---

## 5. Bat Manufacturing

### 5.1 Bat Sourcing

| Option | Pros | Cons |
|--------|------|------|
| **OEM bat manufacturer** | Custom cavity, bulk pricing | MOQ 500–1000; lead time 2–3 months |
| **Local bat maker (Kashmir, Meerut, etc.)** | Flexible, smaller MOQ | Quality variance; need strict specs |
| **Off-the-shelf + retrofit** | Fast, low MOQ | Cavity cutting adds cost; consistency |

**Recommendation:** Partner with 1–2 bat manufacturers for custom cavity. Provide housing dimensions; they cut cavity during production.

### 5.2 Integration Process

1. Bat blank with pre-cut cavity (spine, above sweet spot)
2. Insert housing with electronics (pre-assembled)
3. Secure with adhesive + mechanical clip (if designed)
4. Seal cavity edges
5. Final QC: weight, balance, BLE test

### 5.3 Bat Specifications for Training Centres

- **Type:** Tennis cricket bat (lightweight, durable)
- **Size:** Senior (full size) — primary for academies
- **Weight:** Standard + 50–60g (electronics) — total within normal range
- **Grip:** Standard; USB-C port accessible near handle (discreet)

---

## 6. Production Software Stack

### 6.1 Firmware

| Aspect | Specification |
|--------|---------------|
| **Framework** | ESP-IDF (not Arduino) for production |
| **BLE** | NimBLE or Bluedroid stack |
| **OTA** | Supported for field updates |
| **Power** | Deep sleep when idle; < 10mA active |
| **Calibration** | Factory calibration stored in NVS |

### 6.2 Mobile App

| Aspect | Specification |
|--------|---------------|
| **Framework** | Flutter (recommended) — single codebase, good performance |
| **Min SDK** | Android 9, iOS 14 |
| **BLE** | flutter_blue_plus or similar |
| **MediaPipe** | Pose estimation, on-device |
| **Backend** | Firebase (start) or custom (scale) |

### 6.3 Backend (Production Scale)

| Scale | Stack | Notes |
|-------|------|-------|
| **0–5K users** | Firebase (Auth, Firestore, Storage) | Fast, low ops |
| **5K–50K** | Firebase + Cloud Functions | Add serverless logic |
| **50K+** | Custom (Node/Go + PostgreSQL + S3) | Cost control, flexibility |

**Training Centre Features (B2B):**

- Multi-bat management (dashboard)
- Per-player profiles under centre
- Bulk session export
- Centre-level analytics (coach view)
- White-label option (centre branding)

### 6.4 Infrastructure

- **App distribution:** Google Play, Apple App Store
- **Analytics:** Firebase Analytics / Mixpanel
- **Crash reporting:** Firebase Crashlytics / Sentry
- **OTA server:** Custom or Espressif cloud for firmware updates

---

## 7. Quality Assurance & Testing

### 7.1 Incoming QC (Components)

- Visual inspection of PCB
- Continuity test
- Power-on test

### 7.2 In-Circuit Testing (ICT)

- Power rails
- BLE broadcast
- IMU response
- Piezo response (tap test)

### 7.3 Functional Testing

- BLE pairing with app
- Swing detection (automated jig or manual)
- Impact detection
- Battery charge/discharge cycle

### 7.4 Environmental & Durability Testing

| Test | Specification | Pass Criteria |
|------|---------------|---------------|
| **Drop test** | 1.5m onto concrete, 6 faces | No damage, BLE works |
| **Shock test** | 20G, 11ms half-sine, 3 axes | No damage |
| **Vibration** | 10–500 Hz, 2g, 2 hrs | No loosening, works |
| **Temperature** | 0°C to 45°C operating | Full functionality |
| **Humidity** | 90% RH, 48 hrs | No corrosion, works |
| **Impact simulation** | 1000 simulated ball impacts | Sensors still responsive |

### 7.5 Bat-Level Testing

- Weight and balance check
- USB charging test
- Full session simulation (10 min)

---

## 8. Certifications & Compliance

### 8.1 India (Primary Market)

| Certification | Applicable To | Standard | Timeline |
|---------------|---------------|----------|----------|
| **BIS CRS (Battery)** | LiPo battery | IS 16046 (Part 2): 2018 | 4–6 months |
| **BIS (Electronics)** | Charger, PCB assembly | IS 302 / IEC 60335 (if applicable) | 3–6 months |
| **WPC (Wireless)** | BLE radio | Mandatory for wireless in India | Often covered by module |

**Note:** Use BIS-certified battery cells/packs from approved suppliers to avoid full battery certification.

### 8.2 Export (If Applicable)

| Certification | Region | Notes |
|---------------|--------|-------|
| **CE** | EU | ESP32 module often pre-certified; EMC testing for end product |
| **FCC** | USA | Similar to CE |
| **RoHS** | EU/Global | Lead-free assembly |

### 8.3 Certification Strategy

1. **Phase 1:** Ship in India with BIS-certified battery; ensure charger has protection circuits
2. **Phase 2:** Full BIS for electronics if required by product category
3. **Phase 3:** CE/FCC if exporting

---

## 9. Business Model for Training Centres

### 9.1 Revenue Streams

| Stream | Description | Target |
|--------|-------------|--------|
| **Hardware (Bat)** | One-time sale of Smart Bat | Primary |
| **App Subscription** | Monthly/yearly for premium features | Secondary |
| **Bulk Licences** | Centre-level dashboard, multi-bat | B2B |
| **Accessories** | Tripod, spare battery, carry case | Add-on |

### 9.2 Training Centre Value Proposition

- **For academies:** Differentiate with tech; attract students; data-driven coaching
- **For coaches:** Save time; objective metrics; progress reports per player
- **For players/parents:** Measurable improvement; professional feedback

### 9.3 Centre Tiers

| Tier | Bats | Features | Price Model |
|------|------|----------|-------------|
| **Starter** | 1–5 | Basic app, single bat | Per-bat + basic app |
| **Growth** | 6–20 | Centre dashboard, multi-bat | Bulk discount + subscription |
| **Enterprise** | 21+ | White-label, API, dedicated support | Custom pricing |

---

## 10. Pricing Strategy

### 10.1 Cost Estimation (Per Unit, 1000 Units)

| Item | Cost (₹) | Notes |
|------|---------|-------|
| PCB + components | 800–1200 | SMT assembly |
| Battery (BIS certified) | 150–250 | 500mAh LiPo |
| Housing | 200–400 | Injection molding at volume |
| Bat (OEM) | 800–1500 | Depends on quality |
| Assembly + testing | 200–300 | Labour |
| Packaging | 100–150 | Box, manual, cable |
| **COGS** | **2250–3900** | |

### 10.2 Recommended Pricing (B2B)

| Segment | Price (₹) | Margin |
|---------|-----------|--------|
| **Single bat (retail)** | 8,000–12,000 | 50–60% |
| **Training centre (5 bats)** | 7,000–10,000 per bat | 45–55% |
| **Academy (20+ bats)** | 6,000–8,500 per bat | 40–50% |

### 10.3 App Subscription (Optional)

| Plan | Price | Features |
|------|-------|----------|
| **Free** | ₹0 | Basic metrics, 1 bat |
| **Pro** | ₹199/month or ₹1,999/year | Full Coach's Eye AI, history, export |
| **Centre** | ₹4,999/year (up to 20 bats) | Dashboard, multi-bat, coach analytics |

---

## 11. Supply Chain & Sourcing

### 11.1 Component Suppliers (India)

| Component | Supplier Type | Notes |
|-----------|---------------|-------|
| ESP32 module | Robu, ProtoCentral, Mouser India | Authorized distributors |
| ICM-20948 | Mouser, DigiKey, LCSC | TDK InvenSense |
| Battery | Local BIS-certified pack maker | Critical — verify certification |
| PCB | JLCPCB, PCBWay, or India EMS | 4-layer, ENIG |
| Housing | Local injection molder | Tooling 2–4 weeks |
| Bat | Kashmir/Meerut manufacturers | MOQ 100–500 |

### 11.2 MOQ & Lead Times

| Item | MOQ | Lead Time |
|------|-----|-----------|
| PCB | 5–10 | 1–2 weeks |
| PCB Assembly | 50–100 | 2–3 weeks |
| Housing (molded) | 500–1000 | 4–6 weeks (first run) |
| Bat (custom) | 100–500 | 4–8 weeks |
| Battery | 100–500 | 2–4 weeks |

### 11.3 Inventory Strategy

- **Safety stock:** 2–4 weeks of demand
- **Batch size:** Align with bat MOQ (e.g., 200 units per batch)
- **Local assembly:** Prefer India assembly for faster turnaround, lower import dependency

---

## 12. Manufacturing Timeline

### 12.1 Pre-Production (8–12 Weeks)

| Week | Activity |
|------|----------|
| 1–2 | Finalize production BOM; order samples |
| 2–4 | PCB design, prototype, test |
| 4–6 | Housing design, tooling (if injection mold) |
| 5–7 | Bat manufacturer partnership; cavity design |
| 6–8 | Firmware/app production hardening |
| 8–10 | Pilot run (50–100 units) |
| 10–12 | QA, certification prep, packaging |

### 12.2 Production Ramp

| Phase | Volume | Duration |
|-------|--------|----------|
| **Pilot** | 50–100 | 2 weeks |
| **Soft launch** | 200–500 | 4–6 weeks |
| **Scale** | 1000+ | Ongoing |

---

## 13. Go-to-Market for Training Centres

### 13.1 Sales Channels

| Channel | Approach |
|---------|----------|
| **Direct sales** | Visit academies; demo; close |
| **Partnerships** | Cricket associations, state bodies |
| **Online** | Website, Amazon B2B, IndiaMART |
| **Events** | Cricket expos, coaching workshops |

### 13.2 Demo Kit

- 2–3 Smart Bats
- Tripod
- Tablet/phone with app
- 15-min demo script
- Leave-behind brochure + pricing

### 13.3 Training Centre Pitch

1. **Problem:** Coaches can't give personalized feedback to every player
2. **Solution:** Smart Bat = AI coach for each player
3. **Proof:** Demo live; show bat speed, sweet spot, replay
4. **ROI:** Attract more students; differentiate from competitors
5. **Offer:** Pilot programme (2 weeks free) or bulk discount

### 13.4 Marketing Materials

- One-pager (features, pricing)
- Demo video (2 min)
- Case study (after first 2–3 centres)
- Coach training guide (how to use data)

---

## 14. Warranty, Support & After-Sales

### 14.1 Warranty Policy

| Item | Warranty | Exclusions |
|------|----------|------------|
| **Electronics** | 12 months | Intentional impact on housing, water damage, misuse |
| **Bat (wood)** | 6 months | Normal wear, cracks from misuse |
| **Battery** | 6 months or 300 cycles | Swelling from wrong charger |

**Warranty wording (critical):** *"Damage caused due to intentional impact on electronics housing is not covered."*

### 14.2 Support Tiers

| Tier | Response | Channels |
|------|----------|----------|
| **Standard** | 48 hrs | Email, WhatsApp |
| **Centre (paid)** | 24 hrs | Dedicated number |
| **Enterprise** | 4 hrs | SLA |

### 14.3 Replacement & Repair

- **DOA:** Replace within 7 days
- **Repair:** Turnaround 7–10 days; consider swap programme for centres
- **Spare parts:** Stock batteries, charging cables for quick replacement

---

## 15. Risk Mitigation

### 15.1 Technical Risks

| Risk | Mitigation |
|------|------------|
| Sensor failure in field | Redundant piezo (4 instead of 3); confidence levels in app |
| BLE dropout | Retry logic; "Low confidence – not counted" |
| Battery swelling | BIS-certified cells; BQ24075; warranty exclusion for misuse |

### 15.2 Business Risks

| Risk | Mitigation |
|------|------------|
| Low adoption | Pilot programmes; money-back guarantee for first 10 centres |
| Competition | First-mover in India; lock in with centre dashboard, data |
| Supply chain | Dual sourcing for critical parts; 4-week safety stock |

### 15.3 Operational Risks

| Risk | Mitigation |
|------|------------|
| Quality variance | Strict QC; batch traceability; reject rate target < 2% |
| Certification delay | Start BIS process early; use pre-certified components |
| Returns/refunds | Clear warranty; demo before purchase; training |

---

## Summary Checklist

- [ ] Finalize production BOM (ESP32 module, ICM-20948, BIS battery, BQ24075)
- [ ] Design 4-layer PCB; prototype and test
- [ ] Design injection-molded housing; get tooling
- [ ] Partner with bat manufacturer for custom cavity
- [ ] Set up EMS for PCB assembly (India or overseas)
- [ ] Implement production firmware (ESP-IDF, OTA)
- [ ] Harden app for production (analytics, crash reporting)
- [ ] Define QA process (ICT, functional, environmental)
- [ ] Obtain BIS certification for battery (or use certified supplier)
- [ ] Create demo kit and sales materials
- [ ] Pilot with 2–3 training centres
- [ ] Launch and scale

---

*Document created for production readiness. Update as design and supply chain evolve. Last updated: February 2025.*
