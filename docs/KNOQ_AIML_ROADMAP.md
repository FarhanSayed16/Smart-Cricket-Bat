# KnoQ AI/ML Roadmap — Complete Technical Plan

> **Last updated:** April 2026  
> **Status:** Pre-implementation — planning complete  
> **Companion doc:** `Cricket_Shot_Analysis_AI_System.md` (raw ideation notes)

---

## 1. The Problem Statement

KnoQ's bat hardware already tells you **where** the ball hit and **how hard**. But it cannot tell you:

- **What delivery was bowled** (yorker, short ball, good length)
- **What shot was played** (cover drive, pull, defensive block)
- **Whether the shot was the RIGHT response to THAT delivery**
- **Whether the technique was executed correctly** (head position, foot placement, follow-through)

The AI system bridges this gap by combining **camera vision** with **bat sensor data** to produce coaching-grade feedback automatically.

---

## 2. What You Already Have (Your Unfair Advantage)

| Data Source | What It Gives You | Status |
|---|---|---|
| Bat IMU (via BLE) | Impact zone (Sweet/Top/Left/Right/Bottom), power (0–100), swing speed (°/s), hit sequence number | ✅ Live in app |
| Session metadata | Start/end time, player ID, device ID, per-shot timestamps | ✅ Live in app |
| Hive WAL + PostgreSQL | Every shot persisted locally and synced to cloud | ✅ Live in app |
| Coach notes | Human expert annotations per session | ✅ Live in app |

**What you do NOT have yet:**
- Video recordings of sessions (camera not integrated)
- Body joint positions (pose estimation not running)
- Ball tracking (speed, length, line)
- Shot type labels (no classification model)

All four of these come from one thing: **the phone camera**. This is why camera integration is step zero of the AI plan.

---

## 3. The Four AI Components

The system is a pipeline of four models, each feeding into the next:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐    ┌────────────────────────┐
│  Component 1    │    │  Component 2     │    │  Component 3        │    │  Component 4           │
│  Ball Analysis  │───▶│  Pose Estimation │───▶│  Shot Classification│───▶│  Technique Evaluation  │
│  (delivery type)│    │  (body landmarks)│    │  (what shot played) │    │  (was it correct?)     │
└─────────────────┘    └──────────────────┘    └─────────────────────┘    └────────────────────────┘
     Camera                 Camera               Pose + BLE data           All combined
```

### Component 1 — Ball Analysis Model

**Purpose:** Detect delivery type from camera footage.

| Property | Detail |
|---|---|
| Input | Video frames from phone camera (pre-impact window, ~1 second) |
| Output | `{ length: "good_length", line: "off_stump", speed_estimate: "medium" }` |
| Base model | YOLOv8-nano (pre-trained object detection, fine-tuned on cricket ball) |
| Runs on | On-device (V1 — lightweight YOLO), cloud (V2 — higher accuracy) |
| Training data needed | 500+ labelled clips with delivery type annotations |
| V1 workaround | **Player manually tags delivery type** in app after each shot. This is the critical insight — you don't need the ball detection model to ship V1. Manual tags give you training data AND a working product simultaneously. |

**Delivery type taxonomy (8 classes):**

| Class | Description |
|---|---|
| `yorker` | Pitched at/near the crease, hitting base of stumps |
| `full` | Pitched in the first ~2m from the crease |
| `good_length` | The "corridor of uncertainty" — 4–6m from crease |
| `short` | Pitched halfway down, bounces to waist/chest height |
| `bouncer` | Pitched short, rises above chest height |
| `full_toss` | Doesn't bounce — arrives above stump height |
| `wide_off` | Outside off stump, wide line |
| `wide_leg` | Down leg side |

**Ball line taxonomy (5 classes):** `off_stump`, `outside_off`, `middle`, `leg`, `wide_leg`

---

### Component 2 — Pose Estimation (MediaPipe)

**Purpose:** Extract batsman's body joint positions from every video frame.

| Property | Detail |
|---|---|
| Input | Single video frame |
| Output | 33 (x, y, z) landmark coordinates per frame |
| Model | **Google MediaPipe Pose** — pre-trained, no training needed |
| Runs on | On-device (MediaPipe is designed for mobile) |
| Flutter package | `google_mlkit_pose_detection` or direct MediaPipe SDK |
| Training data needed | **None** — this is a pre-trained model |

**Key landmarks for cricket analysis (subset of 33):**

| Joint | Why it matters |
|---|---|
| Nose (0) | Head position — should be over front knee on drives |
| Left/Right Shoulder (11, 12) | Shoulder alignment — side-on vs open |
| Left/Right Elbow (13, 14) | Front elbow height — critical for drives |
| Left/Right Wrist (15, 16) | Bat path and follow-through |
| Left/Right Hip (23, 24) | Hip rotation — weight transfer indicator |
| Left/Right Knee (25, 26) | Knee bend — front foot commitment |
| Left/Right Ankle (27, 28) | Foot position — stride length |

**What you compute FROM the landmarks (derived metrics):**

```
head_over_front_knee = nose.x relative to front_knee.x
shoulder_alignment = angle between shoulder line and crease
front_elbow_height = front_elbow.y relative to front_shoulder.y
hip_rotation_angle = angle change between stance and impact frames
stride_length = distance between ankles at impact
weight_transfer = hip midpoint shift from stance to impact
follow_through_completeness = wrist position 5 frames after impact
```

These derived metrics are the actual inputs to the technique evaluator.

---

### Component 3 — Shot Classification Model

**Purpose:** Given the body movement pattern + bat sensor data, classify what shot was played.

| Property | Detail |
|---|---|
| Input | Sequence of 15 pose landmark frames around impact + IMU swing data from bat |
| Output | One of 10 shot type labels |
| Architecture | LSTM or 1D-CNN on the time-series of pose coordinates |
| Model size | < 5MB (TFLite, runs on-device) |
| Training data needed | 50+ labelled examples per shot type = **500+ total** |
| V1 workaround | **Coach manually tags shot type during clip review** (Phase 18.8 AI Lab tagging interface). This gives you labels AND a working product. |

**Shot type taxonomy (10 classes):**

| Class | Key pose signature |
|---|---|
| `cover_drive` | Front foot forward, high elbow, bat sweeps through cover |
| `straight_drive` | Front foot to pitch, bat straight through V |
| `on_drive` | Front foot across, bat sweeps through mid-on |
| `pull` | Back foot pivot, horizontal bat, weight transfers back |
| `hook` | Similar to pull but higher, bat above shoulder |
| `cut` | Back foot, horizontal bat, arms away from body |
| `sweep` | Front knee down, horizontal bat close to ground |
| `defensive_front` | Front foot forward, bat close to pad, soft hands |
| `defensive_back` | Back foot, bat under eyes, controlled push |
| `slog` | Full rotation, high bat lift, open stance |

---

### Component 4 — Technique Evaluation Engine (The Core Product)

**Purpose:** Answer the question: "For THIS delivery, was THAT shot played with CORRECT technique?"

| Property | Detail |
|---|---|
| Input | Ball analysis output + shot classification output + pose metrics + bat sensor data |
| Output | Shot selection score (0–100), technique score (0–100), specific textual feedback |
| V1 approach | **Rule-based engine** — cricket coaching knowledge encoded as if/else logic |
| V2 approach | **ML regression model** trained on coach-rated sessions (needs 1000+ labelled) |
| Runs on | On-device (V1 rules), cloud (V2 ML model) |

**V1 Rule Engine Architecture:**

The rule engine has two layers:

**Layer A — Shot Selection Scoring**

Was this the right shot for this delivery?

```
DELIVERY → APPROPRIATE RESPONSES mapping:

yorker           → [defensive_front, on_drive]
full_off         → [cover_drive, straight_drive, on_drive]
full_leg         → [on_drive, flick, sweep]
good_length_off  → [defensive_front, defensive_back, cover_drive]
good_length_leg  → [defensive_front, defensive_back, on_drive]
short_off        → [cut, defensive_back]
short_leg        → [pull, hook, defensive_back]
bouncer          → [hook, duck, defensive_back]
full_toss        → [any aggressive shot]
```

Scoring logic:
- Shot is in the "appropriate" list → base score 70–100 (modified by execution)
- Shot is "risky but possible" → base score 40–60
- Shot is clearly wrong → base score 10–30
- Feedback string generated: `"Good choice — cover drive on a full ball outside off"`

**Layer B — Technique Scoring**

Was the chosen shot executed with correct body mechanics?

Each shot type has a checklist of 4–6 technique markers. Each marker is evaluated from the pose landmarks:

```
COVER DRIVE checklist:
├── front_foot_to_pitch     → ankle distance to estimated pitch point  [weight: 25%]
├── head_over_front_knee    → nose.x aligned with front_knee.x        [weight: 20%]
├── front_elbow_high        → elbow.y above shoulder.y at impact       [weight: 20%]
├── shoulder_side_on        → shoulder angle < 30° from crease         [weight: 15%]
├── follow_through_complete → wrist travels 60%+ of full arc post-impact [weight: 10%]
└── weight_forward          → hip midpoint shifted > 15% toward bowler  [weight: 10%]

PULL SHOT checklist:
├── back_foot_pivot         → back ankle rotates > 45°                 [weight: 25%]
├── head_stays_side_on      → nose stays within shoulder line          [weight: 20%]
├── bat_horizontal          → wrist.y ≈ shoulder.y at impact           [weight: 20%]
├── arms_extended           → elbow angle > 120° at impact             [weight: 15%]
├── weight_on_back_foot     → hip midpoint behind crease at impact     [weight: 10%]
└── controlled_follow       → swing decelerates post-impact            [weight: 10%]
```

Each marker gets a score 0–100 based on how close the measured value is to the ideal range. Weighted average = technique_score.

**Combined output per shot:**

```json
{
  "delivery": { "length": "good_length", "line": "off_stump" },
  "shot_played": "cover_drive",
  "shot_selection_score": 85,
  "technique_score": 72,
  "technique_breakdown": {
    "front_foot_to_pitch": 90,
    "head_over_front_knee": 65,
    "front_elbow_high": 80,
    "shoulder_side_on": 70,
    "follow_through_complete": 55,
    "weight_forward": 75
  },
  "feedback": [
    "Good shot selection — cover drive is correct for this delivery",
    "Head position needs work — try getting your head further over the front knee",
    "Follow-through was cut short — complete the swing through the line of the ball"
  ],
  "bat_data": {
    "zone": "Sweet",
    "power": 78,
    "swing_speed": 145.2,
    "timing": "slightly_early"
  }
}
```

---

## 4. Data Pipeline & Processing Flow

```
SESSION START
│
├── BLE stream active → shots arriving with timestamp + sensor data
├── Camera recording active → continuous video with frame timestamps
│
│ ... player bats ...
│
SESSION END
│
├── Video segmented into per-shot clips
│   └── Each clip = 2s before impact + 2s after impact (4s total)
│       └── Impact timestamp comes from BLE hit event
│
├── Per clip, pipeline runs:
│   │
│   ├── 1. MediaPipe Pose → 33 landmarks × ~30 frames = pose tensor
│   ├── 2. Ball Detection → delivery type (OR manual tag from player in V1)
│   ├── 3. Shot Classifier → shot type from pose sequence + IMU swing
│   ├── 4. Technique Engine → scores + feedback from all above
│   │
│   └── Results stored:
│       ├── Clip video → Firebase Storage (path: /sessions/{id}/clips/{hit}.mp4)
│       ├── Pose landmarks → PostgreSQL JSON column (or separate table)
│       ├── AI results → PostgreSQL (shot_type, delivery_type, scores, feedback)
│       └── Raw sensor data → already stored from BLE
│
└── Session summary includes AI aggregate:
    ├── "Shot selection accuracy: 73% (you chose correct shots 22/30 times)"
    ├── "Best technique: cover drive (avg 82/100)"
    ├── "Weakest technique: pull shot (avg 41/100) — review fundamentals"
    └── "Top 3 areas to improve: 1) Head position 2) Follow-through 3) Back-foot pivot"
```

**Processing location strategy:**

| Component | V1 (launch) | V2 (3 months) | V3 (scale) |
|---|---|---|---|
| MediaPipe Pose | On-device | On-device | On-device |
| Ball Detection | Manual tag | On-device (YOLO-nano) | Cloud (accuracy) |
| Shot Classifier | Manual tag | On-device (TFLite LSTM) | On-device |
| Technique Engine | On-device (rules) | Cloud (ML model) | Cloud |
| Video storage | Firebase Storage | Firebase Storage | S3/CDN |

---

## 5. Database Schema Changes for AI

New tables/columns needed in PostgreSQL:

```sql
-- Per-shot AI results (one row per shot in a session)
CREATE TABLE shot_analysis (
    id SERIAL PRIMARY KEY,
    session_id UUID REFERENCES sessions(id),
    shot_number INTEGER NOT NULL,
    
    -- From camera + models
    clip_url TEXT,                    -- Firebase Storage path
    delivery_type VARCHAR(20),       -- yorker, full, good_length, short, bouncer, full_toss
    delivery_line VARCHAR(20),       -- off_stump, outside_off, middle, leg, wide_leg
    shot_type VARCHAR(30),           -- cover_drive, pull, hook, defensive_front, etc.
    
    -- Scores
    shot_selection_score INTEGER,    -- 0-100
    technique_score INTEGER,         -- 0-100
    technique_breakdown JSONB,       -- { "front_foot": 90, "head_position": 65, ... }
    
    -- Pose data
    pose_landmarks JSONB,            -- Array of 33 landmarks × N frames
    
    -- From BLE (duplicated for fast queries without joining shots table)
    zone VARCHAR(10),
    power INTEGER,
    swing_speed DOUBLE PRECISION,
    
    -- Feedback
    feedback TEXT[],                 -- Array of feedback strings
    
    -- Tagging metadata (for training data collection)
    is_manually_tagged BOOLEAN DEFAULT false,
    tagged_by INTEGER REFERENCES users(id),
    tagged_at TIMESTAMP,
    tag_quality_rating INTEGER,      -- 1-5 stars (coach rates the clip quality)
    
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_shot_analysis_session ON shot_analysis(session_id);
CREATE INDEX idx_shot_analysis_shot_type ON shot_analysis(shot_type);
CREATE INDEX idx_shot_analysis_tagged ON shot_analysis(is_manually_tagged);

-- Model versioning
CREATE TABLE ai_models (
    id SERIAL PRIMARY KEY,
    model_name VARCHAR(50),          -- 'shot_classifier', 'ball_detector', 'technique_scorer'
    version VARCHAR(20),
    accuracy DOUBLE PRECISION,
    clips_used_for_training INTEGER,
    tflite_url TEXT,                 -- Firebase Storage path to .tflite file
    is_deployed BOOLEAN DEFAULT false,
    deployed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 6. Training Data Strategy

This is the most critical section. The AI is only as good as its training data, and you have a **cold-start problem** — you need data to train models, but you need models to make the product useful.

**The solution is the manual-tag-first approach:**

### Phase A — Collect Raw Data (start immediately)

Every session records video + sensor data. Even without AI processing, store everything:
- Video clips → Firebase Storage
- Sensor data → PostgreSQL (already happening)
- Pose landmarks → run MediaPipe offline, store results

**Target:** 100 sessions across 10 players in the first month.

### Phase B — Build the Tagging Pipeline (Phase 18.8 AI Lab)

The web dashboard's AI Lab lets coaches review clips and tag them:
- Delivery type (what ball was bowled)
- Shot type (what shot was played)
- Shot selection rating (correct/risky/wrong)
- Technique rating (1–5 stars)
- Specific notes

**Target:** 500 tagged clips in the first 2 months (2–3 coaches tagging 1 hour/week).

### Phase C — Train Shot Classifier

Once you have 50+ examples per shot type:
- Export pose landmark sequences + labels from the database
- Train LSTM/1D-CNN in Google Colab (Python + PyTorch)
- Convert to TFLite
- Deploy to app via Firebase Storage + model download

**Target:** V1 shot classifier with >75% accuracy at 3 months.

### Phase D — Train Technique Scorer

Once you have 1000+ tagged clips with technique ratings from coaches:
- Train regression model: pose + sensor → technique_score
- This replaces the hand-coded rule engine
- Validate against held-out coach ratings

**Target:** V2 ML technique scorer at 6 months.

### Data Volume Targets

| Milestone | Clips needed | Timeline | What it unlocks |
|---|---|---|---|
| MVP | 100 raw clips | Month 1 | MediaPipe overlay working, manual tags |
| Shot Classifier V1 | 500 tagged clips | Month 2–3 | Auto shot type detection |
| Ball Detector V1 | 500 tagged clips with delivery labels | Month 3–4 | Auto delivery detection |
| Technique Scorer V1 | 1,000 tagged + rated clips | Month 4–6 | ML-based technique feedback |
| Production quality | 5,000+ clips | Month 6–12 | Reliable, accurate system |

---

## 7. Implementation Phases (What To Build When)

### Phase 20.1 — Camera Integration (Build First)

**This is the foundation. Nothing else works without this.**

| Task | Detail |
|---|---|
| Camera permission + setup | Use `camera` package, rear camera, 720p, 30fps |
| Recording UI | "Start Recording" button on live session screen, red indicator |
| BLE-Camera timestamp sync | Record `DateTime.now()` on both BLE shot event and camera frame |
| Clip extraction | On session end, segment video into 4-second clips around each BLE impact timestamp |
| Storage | Upload clips to Firebase Storage: `/sessions/{session_id}/clips/{shot_number}.mp4` |
| Clip URL persistence | Store Firebase Storage URL in `shot_analysis.clip_url` |
| Playback | Session summary shows clips inline, tap to expand + replay |

**Camera placement assumption:** Phone on a tripod at the bowler's end, facing the batsman. This gives a front/slightly-angled view of the body, which is optimal for MediaPipe pose detection.

### Phase 20.2 — MediaPipe Pose Integration

| Task | Detail |
|---|---|
| Add `google_mlkit_pose_detection` to pubspec | Or use MediaPipe Flutter plugin |
| Run pose on each clip | Post-session batch processing, not real-time |
| Store landmarks | 33 joints × N frames → JSONB in `shot_analysis.pose_landmarks` |
| Skeleton overlay | Draw landmarks on clip replay (connect joints with lines) |
| Derived metrics | Compute head_position, elbow_height, hip_rotation, etc. from raw landmarks |

### Phase 20.3 — Rule-Based Technique Engine (V1 AI)

| Task | Detail |
|---|---|
| Manual tagging UI in app | After session, player tags each shot: delivery type + shot type |
| Rule engine (Dart) | Implement the shot selection + technique checklist logic |
| Feedback generation | Produce 2–3 coaching tips per shot based on rule violations |
| Display in app | Shot card shows: shot type badge, scores, feedback text, skeleton overlay |
| Store results | Save to `shot_analysis` table |

### Phase 20.4 — Data Collection Pipeline

| Task | Detail |
|---|---|
| AI Lab in dashboard (Phase 18.8) | Clip browser, tagging interface, keyboard shortcuts, progress tracking |
| Export pipeline | Download labelled data as CSV/ZIP for Colab training |
| Coach tagging workflow | Assign clips to coaches, track completion, quality review |

### Phase 20.5 — ML Models (V2 AI)

| Task | Detail |
|---|---|
| Shot classifier training | Python + PyTorch in Colab, LSTM on pose sequences |
| Convert to TFLite | Quantize and export for on-device inference |
| Deploy to app | Download model from Firebase Storage on app launch, run inference |
| Ball detector training | Fine-tune YOLOv8-nano on tagged delivery clips |
| Technique scorer training | Regression model replacing rule engine |
| A/B testing | Run both rule engine and ML model, compare with coach ratings |

### Phase 20.6 — Advanced Features (V3)

| Task | Detail |
|---|---|
| Real-time pose overlay | MediaPipe runs during session, not just post-session |
| Voice coaching | Text-to-speech feedback between shots: "Head down!", "More follow-through!" |
| Pro comparison | Overlay professional player's pose template alongside student's |
| Pressure simulation | "Match mode" with scoring, situation prompts, mental pressure metrics |

---

## 8. Tech Stack Summary

| Layer | Technology | Why |
|---|---|---|
| Pose estimation | Google MediaPipe Pose | Free, on-device, 33 landmarks, real-time capable |
| Ball detection | YOLOv8-nano (TFLite) | Lightweight object detection, fine-tunable |
| Shot classification | Custom LSTM (TFLite) | Small model, runs on-device, trained on your data |
| Technique evaluation V1 | Dart rule engine | No ML needed, ships immediately, cricket logic |
| Technique evaluation V2 | Python regression model (cloud) | Needs training data, replaces rules with learned patterns |
| Training environment | Google Colab + PyTorch | Free GPU, collaborative, exportable |
| Model format | TensorFlow Lite (.tflite) | Standard for on-device ML on Android/iOS |
| Model hosting | Firebase Storage + Remote Config | Download models dynamically, version control |
| Video storage | Firebase Storage | Already integrated, secure, CDN-backed |
| Labelling tool | React web dashboard (Phase 18.8 AI Lab) | Coaches tag clips from browser |

---

## 9. What You Can Start Right Now (Before Camera Integration)

Even before writing a single line of camera code, you can:

1. **Create the `shot_analysis` database table** — schema is ready above
2. **Add the manual tagging UI in the Flutter app** — after a session ends, let the player tag each shot with delivery type + shot type. This data is gold even without video.
3. **Build the rule engine in Dart** — using only bat sensor data + manual tags, you can already produce shot selection scores and basic feedback
4. **Design the AI Lab screens in the web dashboard** — the tagging interface, clip browser, and model management UI can be built before any clips exist

This means you can ship a "V0.5" AI experience using **only the bat sensor data + manual tags + rule engine**, with no camera at all. Coaches get: "You played a pull shot on a good length ball — risky choice. Shot selection: 35/100."

---

## 10. Risk Assessment

| Risk | Impact | Mitigation |
|---|---|---|
| Phone camera angle inconsistent | Pose detection fails if batsman partially occluded | Strict tripod placement guide, calibration screen in app |
| Insufficient training data | Models underperform with < 500 clips | Manual tags let you ship V1 without ML; collect data passively |
| Ball too small/fast for phone camera | Ball detection accuracy low at 720p/30fps | V1 uses manual tags; upgrade to 1080p/60fps if phone supports |
| MediaPipe accuracy in outdoor conditions | Sunlight, shadows affect pose detection | Test outdoor extensively; fall back to indoor-only V1 |
| Coach labelling inconsistency | Two coaches tag the same shot differently | Inter-rater reliability checks; majority vote on disputed clips |
| Model drift over time | Player technique changes, model stale | Retrain quarterly with new data; monitor prediction confidence |

---

## 11. Success Metrics

| Metric | V1 Target | V2 Target |
|---|---|---|
| Shot classification accuracy | N/A (manual tags) | > 75% |
| Shot selection score correlation with coach rating | > 0.6 | > 0.8 |
| Technique score correlation with coach rating | > 0.5 | > 0.75 |
| Clips processed per session (post-session) | < 2 min for 30 shots | < 1 min |
| User satisfaction with AI feedback | "Useful" > 60% | "Useful" > 80% |
| Clips tagged per month (data pipeline) | 200 | 500 |

---

*This document is the single source of truth for all AI/ML decisions in KnoQ. Update as models are trained and accuracy benchmarks are established.*
