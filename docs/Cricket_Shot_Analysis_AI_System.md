
**What you want the AI to do:**

Detect the **type of delivery** (length ball, short ball, yorker, full toss, good length) and then judge whether the **batsman's response** — their shot selection, body position, footwork, and technique — was correct for that specific delivery. Not just "did they hit it" but "did they play the RIGHT shot with the RIGHT technique for THAT ball."

Examples you gave:
- Length ball → is the batsman driving properly with full extension
- Short ball → is the batsman playing a proper hook or pull with correct head position and weight transfer
- Slot ball → is the batsman capitalising with the right aggressive shot
- Yorker → is the batsman getting into the right defensive position to protect the wicket

So the AI needs to understand **two things simultaneously** and connect them — the ball and the bat/body response to it.

---

**This is a multi-layer AI problem. Here is the complete plan:**

---

## Layer 1 — What data you have

**From the bat (hardware — already built):**
- Impact zone (sweet spot, toe, edge)
- Power (0–100)
- Swing speed (°/s)
- Timing (early/late/perfect)
- Shot direction (via IMU swing path)

**From the phone camera (bowler's end — Phase 20):**
- Full video of the delivery and shot
- Batsman's body visible from front/side

**What you do NOT have yet:**
- Ball tracking (speed, length, line)
- Body joint positions (pose)

Both of these come from the camera. This is why Phase 20 (camera integration) is the foundation of the entire AI plan.

---

## Layer 2 — The AI components needed

**Component 1 — Ball analysis model**

Detects from the camera video:
- Ball length: yorker / full / good length / short / bouncer
- Ball line: off stump / middle / leg / wide
- Ball speed (approximate from frame delta)
- Swing direction (if visible)

**How to build it:**
Use a pre-trained object detection model (YOLOv8 or similar) fine-tuned to detect cricket ball trajectory. You don't train from scratch — you take an existing ball detection model and fine-tune on cricket footage. There are open datasets available (IPL broadcast footage, CricViz data).

Input: video frames from phone camera
Output: `{ length: "good_length", line: "off_stump", speed: "medium" }`

---

**Component 2 — Pose estimation model**

Detects batsman's body joints in every frame:
- Head position
- Shoulder alignment
- Elbow angle
- Hip rotation
- Front foot position
- Weight transfer direction
- Follow-through completeness

**How to build it:**
Don't train this from scratch. Use **Google MediaPipe Pose** — it already detects 33 body landmarks in real time on a phone. Your job is not to build the pose model, it's to interpret the landmark data for cricket.

Input: video frame
Output: 33 (x,y,z) coordinates of body joints per frame

---

**Component 3 — Shot classification model**

Takes pose landmarks + bat sensor data and classifies the shot type:
- Cover drive
- Pull shot
- Hook shot
- Defensive block
- Sweep
- Cut shot
- Straight drive
- Yorker dig-out

**How to build it:**
This is where you train a custom model. Input is the sequence of pose landmarks across ~15 frames around impact + IMU swing direction from the bat. Output is shot type label.

Architecture: LSTM or Transformer on the time-series of pose coordinates. Relatively lightweight, can run on-device.

Training data: You need labelled examples. Start with 50 examples per shot type — a player plays each shot type deliberately while you record and label. 500 total labelled samples gets you a working V1 model.

---

**Component 4 — Technique evaluation model (the core)**

This is the most important and most complex part. It answers: "For THIS delivery, was THAT shot played with CORRECT technique?"

It combines:
- Ball analysis output (length, line)
- Shot classification output (what shot was played)
- Pose quality per frame (were the joints in the right position)
- Bat sensor data (timing, power, sweet spot)

And outputs:
- Shot selection score (was this the right shot for this ball — 0 to 100)
- Technique score (was the shot executed correctly — 0 to 100)
- Specific feedback (what was wrong)

**How to build this:**

Two-stage approach:

Stage 1 — Rule-based engine (V1, build now):
Define rules for each delivery type and correct response. This is cricket coaching knowledge encoded as logic.

```
IF length == "good_length" AND line == "off_stump":
    correct_shots = ["cover_drive", "back_foot_punch", "defensive"]
    IF played_shot NOT IN correct_shots:
        shot_selection_score = 20
        feedback = "Risky shot for this length and line"
    
    IF played_shot == "cover_drive":
        check: front_foot_position (should be to pitch of ball)
        check: head_position (should be over front knee)
        check: elbow_height (front elbow should be high)
        check: follow_through (should be complete)
        technique_score = weighted average of checks

IF length == "short" AND line == "middle_or_leg":
    correct_shots = ["pull", "hook", "duck"]
    IF played_shot == "pull":
        check: back_foot_pivot
        check: head_stays_side_on
        check: arms_extension_at_contact
        check: weight_transfer_to_back_foot
```

Stage 2 — ML scoring model (V2, after data collection):
Once you have 1000+ labelled sessions with expert coach ratings, train a regression model that predicts technique score from pose + sensor data. This replaces the hand-coded rules with learned patterns.

---

## Layer 3 — Integration with the app

**Data flow:**

```
Camera records video
    ↓
On session end, video is processed:
    ↓
Frame extraction around each impact timestamp (from BLE)
    ↓
Ball detection model runs on pre-impact frames → delivery type
    ↓
MediaPipe pose runs on impact frames → body landmarks
    ↓
Shot classifier runs on landmarks + IMU data → shot type
    ↓
Technique evaluator runs → scores + feedback
    ↓
Results stored with session in PostgreSQL
    ↓
App displays: shot replay + skeleton overlay + scores + coaching tip
```

**Processing location:**
- MediaPipe pose: on-device (phone handles this fine)
- Ball detection: on-device for V1 (lightweight YOLO), cloud for V2
- Shot classifier: on-device (small LSTM model, <5MB)
- Technique evaluator: on-device for rule-based V1, cloud for ML V2

---

## Layer 4 — Training data strategy

**Phase 1 — Collect your own data (start now even without AI)**

Every session recorded in the app is potential training data. Store all videos (Firebase Storage) and all sensor readings. Even without labels, this data is gold.

**Phase 2 — Label the data**

Get 2–3 cricket coaches to review recorded sessions and label:
- What delivery was bowled
- What shot was played
- Was the shot selection correct (yes/no/risky)
- Technique rating (1–5) with specific notes

Tools: Build a simple internal web tool where coaches watch the clip and fill a form. 1 hour of labelling per coach per week builds your dataset fast.

**Phase 3 — Train on your labelled data**

Once you have 500+ labelled shots per shot type, train the shot classifier and technique scorer. Use Python + PyTorch or TensorFlow. Host the trained model as a TFLite file for on-device inference or as a Flask/FastAPI endpoint for cloud inference.

---

## Phased rollout

**V1 (build now alongside camera integration):**
- MediaPipe pose overlay on replay video
- Rule-based shot selection feedback (correct/risky/wrong for delivery type)
- Basic technique checklist per shot type (head position, foot position)
- No ball tracking yet — player manually tags delivery type in the app

**V2 (after 3 months of data collection):**
- Automatic ball detection from camera
- Shot classifier model trained on your collected data
- Technique scoring model replacing rule-based system
- Full automated feedback without manual tagging

**V3 (scale):**
- Real-time feedback during session (not just post-session)
- Voice coaching ("Head down!", "More follow-through!")
- Comparison against professional player technique templates
- Pressure simulation scoring

---

**Bottom line:** The AI plan has four models working together — ball detection, pose estimation, shot classification, and technique evaluation. MediaPipe handles pose for free. Ball detection and shot classification need training data which you start collecting now. The technique evaluator starts rule-based and becomes ML once you have enough labelled data. Everything processes on-device for V1, moves to cloud as complexity grows. The app integration hooks into the existing BLE timestamp system to sync video frames with sensor data.

This is a 3-phase build — rule-based now, ML after data collection, real-time in V3. Start collecting and labelling data from day one even before the models exist.