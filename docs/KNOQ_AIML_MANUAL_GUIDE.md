# KnoQ AI/ML — Your Manual Tasks Guide

> **Who is this for:** You (Farhan). This document lists ONLY the things that you must do yourself — things that cannot be automated or coded by Antigravity. Everything else (Flutter code, API routes, database, model integration) will be handled for you.
>
> **How to use this:** Work through the sections in order. Each section tells you exactly what to do, what tools to use, where to save files, and when to hand off to me.

---

## Table of Contents

1. [Setup & Accounts (One-Time)](#1-setup--accounts-one-time)
2. [Camera Hardware Setup](#2-camera-hardware-setup)
3. [Recording Your First Training Sessions](#3-recording-your-first-training-sessions)
4. [Tagging Clips (The Most Important Manual Task)](#4-tagging-clips)
5. [Working With a Cricket Coach](#5-working-with-a-cricket-coach)
6. [Labelling Ball Positions for Ball Detection Model](#6-labelling-ball-positions)
7. [Running Model Training in Google Colab](#7-running-model-training-in-google-colab)
8. [Evaluating Model Results](#8-evaluating-model-results)
9. [Deploying a Trained Model](#9-deploying-a-trained-model)
10. [Ongoing Data Pipeline Maintenance](#10-ongoing-data-pipeline-maintenance)

---

## 1. Setup & Accounts (One-Time)

These are free accounts and tools you need before anything else.

### 1.1 Google Colab (Free GPU for training)

1. Go to [colab.research.google.com](https://colab.research.google.com)
2. Sign in with your Google account
3. That's it — you have free GPU access for model training
4. **Bookmark this.** You'll use it when we have enough tagged data.

### 1.2 Roboflow (Free tool for labelling ball positions)

1. Go to [roboflow.com](https://roboflow.com) → Sign up (free tier)
2. Create a project called `knoq-ball-detection`
3. Set project type to **Object Detection**
4. You'll use this later in Step 6 — not needed immediately

### 1.3 Firebase Storage (Already set up)

Your Firebase project already has Storage configured. Video clips will be uploaded here automatically by the app. No action needed from you.

### 1.4 Server: Install ffmpeg

When we deploy the clip extraction pipeline, your backend server needs `ffmpeg`:

- **If using Railway:** Add to your `Dockerfile` or `nixpacks.toml`:
  ```
  # In nixpacks.toml
  [phases.setup]
  aptPkgs = ["ffmpeg"]
  ```
- **If using Render:** Add a `render.yaml` build step or use their Docker support
- **Local dev (Windows):** Download from [ffmpeg.org/download.html](https://ffmpeg.org/download.html), add to PATH

### 1.5 Create the folder structure

Create this folder on your machine now. This is where ALL your manual AI work goes:

```
D:\KnoQ\ai_data\
├── raw_clips\          ← Clips downloaded from Firebase for labelling
├── tagged_exports\     ← CSV/ZIP exports from the AI Lab dashboard
├── ball_labels\        ← Ball position labels from Roboflow
├── trained_models\     ← .tflite files after Colab training
├── colab_notebooks\    ← Downloaded .ipynb notebooks for reference
└── coach_notes\        ← Coach technique criteria documents
```

Run this in PowerShell:
```powershell
New-Item -ItemType Directory -Force -Path D:\KnoQ\ai_data\raw_clips
New-Item -ItemType Directory -Force -Path D:\KnoQ\ai_data\tagged_exports
New-Item -ItemType Directory -Force -Path D:\KnoQ\ai_data\ball_labels
New-Item -ItemType Directory -Force -Path D:\KnoQ\ai_data\trained_models
New-Item -ItemType Directory -Force -Path D:\KnoQ\ai_data\colab_notebooks
New-Item -ItemType Directory -Force -Path D:\KnoQ\ai_data\coach_notes
```

---

## 2. Camera Hardware Setup

### What you need
- A phone (any phone with a decent camera — yours is fine)
- A phone tripod or stand (₹200–500 on Amazon)
- A cricket net/cage or open space

### Camera placement
```
        ← Bowler bowls from here
        
        |  Phone on tripod  |
        |    📱 (camera)     |
        |                    |
        ~~~~~~ pitch ~~~~~~~~~
        |                    |
        |  🏏 Batsman here   |
        |                    |
```

**Rules:**
- Phone at **bowler's end**, facing the batsman
- Height: approximately **stump height** (71cm / 28 inches)
- Distance: **3–5 meters** behind the bowler's crease
- Camera should capture: full body of batsman from head to feet
- Angle: slightly off-center is OK, but try to be as centered as possible
- **Lighting:** face the camera AWAY from the sun (sun behind the batsman, not behind the camera)

### Test recording checklist
Before recording real training data:
- [ ] Record a 30-second test clip
- [ ] Check: can you see the batsman's full body (head to feet)?
- [ ] Check: is the batsman reasonably centered in frame?
- [ ] Check: is the video stable (no shaking)?
- [ ] Check: is the lighting good enough to see body joints clearly?

**If any answer is NO:** adjust tripod position until all are YES.

---

## 3. Recording Your First Training Sessions

### When to start
Start recording as soon as the camera feature is live in the app (Phase 20.1). You don't need any AI models running — just record everything.

### What happens automatically
1. You start a BLE session in the app
2. Camera starts recording automatically
3. Player bats normally
4. Session ends → video uploads to Firebase Storage
5. Clips are extracted automatically (one per shot)
6. Clips appear in the AI Lab dashboard (Phase 18.8) as "untagged"

### What YOU need to do during recording
- **Nothing special** — just make sure the camera is set up correctly (Step 2)
- Make sure the phone doesn't run out of battery during the session
- For the first 10 sessions, after each session, check the clips in the AI Lab to verify quality

### Target: First month
- Record **at least 10 sessions** with different players
- Each session should have 20–40 shots
- That gives you **200–400 raw clips** to start tagging

---

## 4. Tagging Clips

> **This is the single most important manual task in the entire AI plan.** The quality and quantity of your tags directly determines how good the AI will be.

### What is tagging?
Watching a 4-second video clip and labelling:
1. **What delivery was bowled** (yorker, full, good length, short, bouncer)
2. **What ball line** (off stump, middle, leg)
3. **What shot the batsman played** (cover drive, pull, defensive, etc.)
4. **Was it the right shot for that ball** (perfect, good, risky, wrong)
5. **Technique quality** (1–5 stars)
6. **Optional notes** (free text — "front foot wasn't forward enough")

### Where to tag
In the **AI Lab** section of the web dashboard (`dashboard.knoq.in/ai-lab`).
The tagging interface will have:
- Video player on the left (with slow motion and loop)
- Tagging form on the right
- Keyboard shortcuts for speed

### How to tag (step by step)

1. Open AI Lab → Clip Browser
2. Filter: "Untagged only"
3. Click first clip → tagging interface opens
4. Watch the clip at normal speed once
5. Watch again at 0.5x speed
6. Fill in the form:

| Field | How to decide |
|---|---|
| **Delivery Type** | Where did the ball pitch? Near crease = yorker. Halfway = short. In between = good length. Didn't bounce = full toss. |
| **Ball Line** | Where was the ball relative to stumps? Outside off, on the stumps, or down leg side? |
| **Shot Played** | What did the batsman try to do? Drive? Pull? Block? Cut? Look at the bat path and body position. |
| **Shot Selection** | Knowing what the delivery was — was that the right shot to play? A pull shot on a yorker = wrong. A drive on a full ball = correct. |
| **Technique Rating** | How well was the shot executed? 5 stars = textbook. 3 = decent but flawed. 1 = completely wrong body position. |
| **Notes** | Anything specific: "late on the shot", "didn't get front foot forward", "good weight transfer" |

7. Click **"Save & Next"** → automatically loads the next untagged clip
8. Repeat

### Tagging speed
- First 50 clips: ~30 seconds each (you're learning)
- After practice: ~10–15 seconds each
- **1 hour of tagging = ~50–80 clips**

### Tagging targets

| Milestone | Clips Tagged | Time Investment | What It Unlocks |
|---|---|---|---|
| Week 1–2 | 100 | ~2 hours | Rule engine feedback works |
| Month 1 | 300 | ~5 hours | Patterns visible in data |
| Month 2 | 500 | ~8 hours total | **Ready to train shot classifier** |
| Month 3 | 1000 | ~15 hours total | Ball detector trainable |
| Month 4–6 | 2000 | ~30 hours total | **ML technique scorer trainable** |

### Who should tag?
- **You** — for the first 200 clips (to understand the process)
- **A cricket coach** — for quality ratings (their expertise matters)
- **Your team members** — anyone who understands cricket

### Quality rules
- If you can't tell what delivery it was → skip the clip (mark as "unclear")
- If the batsman isn't fully visible → mark as "unusable"
- If the clip is blurry or dark → mark as "unusable"
- **Be consistent.** If you call something a "cover drive" in clip 1, use the same definition in clip 500.

---

## 5. Working With a Cricket Coach

### Why you need a coach
The rule-based technique engine (Phase 20.4) needs **correct biomechanics thresholds** for each shot type. You can't guess these — they need to come from someone who has coached cricket.

### What to ask the coach

Sit with a cricket coach for **1–2 hours** and fill out this template for each shot type:

```
SHOT TYPE: Cover Drive

Q1: What should the front foot position be?
    → "Front foot should stride to the pitch of the ball, landing beside or just behind it"

Q2: Where should the head be at impact?
    → "Head should be over the front knee, eyes level, watching the ball"

Q3: What should the front elbow look like?
    → "Front elbow should be high — above shoulder level — to keep the bat face straight"

Q4: What should the shoulders look like?
    → "Shoulders should be side-on or slightly open at contact, not chest-on"

Q5: What does a good follow-through look like?
    → "Full follow-through — bat finishes high over the front shoulder"

Q6: Where should the weight be?
    → "60-70% of weight on front foot at impact"
```

**Do this for all 10 shot types:**
1. Cover drive
2. Straight drive
3. On drive
4. Pull shot
5. Hook shot
6. Cut shot
7. Sweep
8. Front foot defensive
9. Back foot defensive
10. Slog/cross-bat hit

### Where to save
Save the coach's answers as a document in:
```
D:\KnoQ\ai_data\coach_notes\technique_criteria.md
```

**Then hand this file to me.** I will convert the coach's descriptions into numeric thresholds for the pose landmark checks in the rule engine.

### Optional: Record the coach demonstrating

If the coach can demonstrate each shot type while being filmed:
- Record 5 repetitions of each shot type
- Label them clearly: `cover_drive_demo_1.mp4` through `cover_drive_demo_5.mp4`
- Save in: `D:\KnoQ\ai_data\coach_notes\demo_videos\`
- These become the "gold standard" pose templates for player comparison (Phase 20.9)

---

## 6. Labelling Ball Positions

> **When to do this:** Only after you have 500+ clips with delivery type tags. This is for the V2 automatic ball detection model. Not needed for V1.

### What you're doing
Drawing a box around the cricket ball in video frames. This teaches the YOLO model what a cricket ball looks like and where it is in different frames.

### Tool: Roboflow (free)

1. Go to your Roboflow project (`knoq-ball-detection`)
2. Upload video clips from `D:\KnoQ\ai_data\raw_clips\`
3. Roboflow will auto-extract frames from the video
4. For each frame where the ball is visible:
   - Draw a bounding box around the ball
   - Label it as `cricket_ball`
5. For frames where the ball is NOT visible: skip (no label needed)

### How many to label
- **Target: 500 clips, 3–5 frames per clip = 1500–2500 labelled frames**
- Focus on frames where the ball is in flight (after release, before it reaches batsman)
- The ball will be small — zoom in if needed
- Roboflow has keyboard shortcuts: press `B` to draw box, `Enter` to confirm

### Time investment
- ~5 seconds per frame once you get the hang of it
- 2500 frames ÷ 12 per minute = ~3.5 hours total
- Spread across a few sessions — don't do it all at once

### Export
1. In Roboflow: click **Generate** → **Export** → Format: **YOLOv8**
2. Download the ZIP file
3. Save to: `D:\KnoQ\ai_data\ball_labels\yolov8_dataset.zip`
4. **Hand this file to me.** I will use it in the YOLO fine-tuning script.

---

## 7. Running Model Training in Google Colab

> **When to do this:** Only when I tell you we have enough tagged data AND I've prepared the training notebook for you.

### What is Google Colab?
It's like Google Docs but for Python code. Google gives you a free GPU (graphics card) to run machine learning training. You don't need to install anything on your machine.

### Step-by-step process

**Step 1: I prepare the notebook**
- I will write a complete `.ipynb` (Jupyter notebook) file
- It will be saved at: `D:\KnoQ\ai_data\colab_notebooks\train_shot_classifier.ipynb`
- The notebook contains ALL the code — you don't need to write any Python

**Step 2: Upload to Colab**
1. Go to [colab.research.google.com](https://colab.research.google.com)
2. Click **File → Upload notebook**
3. Select the `.ipynb` file I prepared

**Step 3: Upload the training data**
1. In the Colab sidebar, click the **folder icon** 📁
2. Click the **upload button** ⬆️
3. Upload the data export ZIP from: `D:\KnoQ\ai_data\tagged_exports\`
4. Wait for upload to complete (may take a few minutes depending on size)

**Step 4: Enable GPU**
1. Click **Runtime → Change runtime type**
2. Set **Hardware accelerator** to **T4 GPU**
3. Click **Save**

**Step 5: Run the notebook**
1. Click **Runtime → Run all**
2. The notebook will:
   - Unzip and load your data
   - Split into train/validation/test sets
   - Train the LSTM model (takes 5–15 minutes)
   - Show accuracy graphs
   - Export the trained model as `.tflite`
3. **Watch the output.** You'll see messages like:
   ```
   Epoch 1/100 - accuracy: 0.3245 - val_accuracy: 0.2890
   Epoch 10/100 - accuracy: 0.6512 - val_accuracy: 0.5980
   Epoch 50/100 - accuracy: 0.8734 - val_accuracy: 0.8210
   ...
   Training complete! Final validation accuracy: 0.8340
   Model saved as shot_classifier.tflite
   ```

**Step 6: Download the model**
1. In the Colab file browser, find `shot_classifier.tflite`
2. Right-click → **Download**
3. Save to: `D:\KnoQ\ai_data\trained_models\shot_classifier.tflite`

**Step 7: Hand the model to me**
Tell me: "The trained model is at `D:\KnoQ\ai_data\trained_models\shot_classifier.tflite`"
I will integrate it into the Flutter app.

---

## 8. Evaluating Model Results

### What to look at after training

When the Colab notebook finishes, it will print:

```
=== Model Evaluation ===
Overall accuracy: 83.4%

Per-class accuracy:
  cover_drive:      89%  ← Great
  straight_drive:   76%  ← OK
  pull:             91%  ← Great
  hook:             68%  ← Needs more data
  cut:              82%  ← Good
  sweep:            74%  ← OK
  defensive_front:  88%  ← Great
  defensive_back:   85%  ← Great
  slog:             79%  ← OK
  on_drive:         72%  ← Needs more data

Confusion matrix: (see chart below)
```

### How to interpret

| Accuracy | What it means | Action |
|---|---|---|
| **> 85%** | Excellent — ready to deploy | ✅ Deploy this model |
| **75–85%** | Good — usable but can improve | Deploy, but keep collecting data |
| **60–75%** | Mediocre — model is guessing sometimes | Collect 2x more data for weak classes |
| **< 60%** | Bad — not ready | Don't deploy. Need more/better data |

### Confusion matrix
The notebook will show a grid chart. Look for:
- **Dark squares on the diagonal** = model is getting it right
- **Off-diagonal dark squares** = model is confusing two shot types
- Example: if the model confuses "cover drive" with "on drive" a lot → you need more examples of each, and make sure your tags are consistent

### What to do if accuracy is low
1. **Check tag consistency:** Are you and the coach tagging the same shot type the same way?
2. **Check data balance:** Do you have roughly equal examples per shot type? If you have 200 cover drives but only 30 hooks, the model will be bad at hooks.
3. **Collect more data:** The #1 fix for low accuracy is more tagged clips.
4. **Tell me the results** — I can adjust the model architecture or add data augmentation.

---

## 9. Deploying a Trained Model

### What "deploying" means
Putting the trained `.tflite` model file somewhere the Flutter app can download and use it.

### Your steps
1. After training, you have a `.tflite` file in `D:\KnoQ\ai_data\trained_models\`
2. **Tell me the file path and the accuracy numbers**
3. I will:
   - Upload it to Firebase Storage
   - Update the `ai_models` table in PostgreSQL
   - Configure the Flutter app to download and use it
   - Add a fallback to the previous model version

### Version tracking
Every time you train a new model, save it with a version number:
```
D:\KnoQ\ai_data\trained_models\
├── shot_classifier_v1.tflite    (accuracy: 78%)
├── shot_classifier_v2.tflite    (accuracy: 83%)
├── shot_classifier_v3.tflite    (accuracy: 87%)  ← current
├── ball_detector_v1.tflite      (accuracy: 71%)
└── technique_scorer_v1.tflite   (accuracy: 69%)
```

**Never delete old versions.** We may need to roll back.

---

## 10. Ongoing Data Pipeline Maintenance

### Weekly checklist (15 minutes)

- [ ] Check AI Lab dashboard: how many untagged clips are there?
- [ ] Tag at least 20–30 clips this week
- [ ] Check if any clips are marked "unusable" — are there camera setup issues to fix?
- [ ] Review any new coach notes — do they suggest new technique rules?

### Monthly checklist (1 hour)

- [ ] Export current tagged dataset from AI Lab
- [ ] Check data balance: do all shot types have roughly equal examples?
- [ ] If any shot type has < 50 examples, prioritize recording sessions with that shot type
- [ ] If total tagged clips > next training threshold → retrain model in Colab
- [ ] Compare new model accuracy vs deployed model — deploy if better

### Training thresholds (when to retrain)

| Total Tagged Clips | Action |
|---|---|
| 500 | Train shot classifier V1 |
| 750 | Retrain shot classifier V2 (expect +5% accuracy) |
| 1000 | Train ball detector V1 |
| 1500 | Retrain both models |
| 2000 | Train technique scorer V1 |
| 3000+ | Full pipeline retrain with all models |

---

## Quick Reference: File Handoff Cheat Sheet

When you complete a manual task, here's exactly what to tell me and where the files should be:

| Task | File Location | What to Say |
|---|---|---|
| Coach technique criteria | `D:\KnoQ\ai_data\coach_notes\technique_criteria.md` | "Coach criteria is ready" |
| Coach demo videos | `D:\KnoQ\ai_data\coach_notes\demo_videos\` | "Demo videos recorded for [shot types]" |
| Tagged data export | `D:\KnoQ\ai_data\tagged_exports\export_YYYY-MM-DD.zip` | "Tagged export ready, X clips" |
| Ball labels (Roboflow) | `D:\KnoQ\ai_data\ball_labels\yolov8_dataset.zip` | "Ball labels ready, X frames" |
| Trained model | `D:\KnoQ\ai_data\trained_models\[name]_v[N].tflite` | "Model trained, accuracy X%" |
| ffmpeg installed on server | N/A | "ffmpeg is installed on [Railway/Render]" |

---

## Summary: Your Time Investment

| Task | When | Time | Frequency |
|---|---|---|---|
| Camera setup | Once | 30 min | One-time |
| Account setup (Colab, Roboflow) | Once | 15 min | One-time |
| Create folder structure | Once | 2 min | One-time |
| Coach consultation | Once (update yearly) | 2 hours | One-time |
| Recording sessions | Ongoing | 0 min extra (happens during normal use) | Automatic |
| Tagging clips | Ongoing | 1–2 hours/week | Weekly |
| Ball labelling (V2 only) | Once | 3–4 hours | One-time |
| Colab training | Per model version | 30 min (mostly waiting) | Every 500 clips |
| Reviewing results | Per training | 15 min | Every 500 clips |

**Total time to get V1 AI running: ~10 hours over 2 months**
**Total time to get V2 ML models: ~30 hours over 6 months**

Most of that time is clip tagging, which you can do while watching TV. It's not hard — it's just repetitive.

---

*This guide will be updated as we progress through Phase 20. Save this file and refer back to it regularly.*
