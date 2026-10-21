# CricStrike 3D 🏏

A production-quality, 100% offline 3D mobile cricket game inspired by *Real Cricket*, built from the ground up for **Godot Engine 4.x** with mobile/Android performance optimization.

---

## 🎯 Phase 1 Completed: 3D Pitch Arena, Ball Physics & Batting Timing Engine
- **Regulation 20.12m Pitch Arena**: Stumps, bails, popping creases, boundary cushions, sight screens, and stadium grandstand.
- **Physical Wickets**: 3 individual stumps & 2 bails with collision dislodging.
- **Aerodynamic Ball Physics**: Quadratic drag, Magnus effect swing, pitch surface bounce modeling (Green, Dusty, Flat, Wet).
- **8-Way Directional Batting**: 8 compass directions x 2 elevation levels (Grounded vs Lofted) with millisecond timing ratings (`PERFECT`, `EARLY`, `LATE`, `TOO_EARLY`, `TOO_LATE`, `MISSED`, and Edges).
- **Broadcast Camera**: 4 dynamic camera tracking angles (`BEHIND_BATSMAN`, `BROADCAST_SIDE`, `BALL_TRACKING`, `BOWLER_END`).

---

## 🎯 Phase 2 Completed: Bowling System, AI Bowler & Difficulty Engine

### 1. Interactive 3D Pitch Delivery Marker (`scripts/bowling/pitch_marker.gd`)
- Drag-and-drop / touch target placement on the pitch strip.
- Length classification:
  - **Yorker**: $8.2\text{m} - 9.5\text{m}$ (aiming at the blockhole and batsman's toes).
  - **Full Length**: $6.5\text{m} - 8.0\text{m}$ (tempting drive length).
  - **Good Length**: $4.5\text{m} - 6.5\text{m}$ (corridor of uncertainty, inducing edges and seams).
  - **Short / Bouncer**: $1.5\text{m} - 4.5\text{m}$ (chest-height bouncers and ribs attacks).
- Dynamic difficulty-based marker fading.

### 2. Oscillating Swing & Speed Meters (`scripts/bowling/bowling_meters.gd`)
- **Step 1**: Line & Length target selection.
- **Step 2**: Oscillating swing meter (stop needle in the green zone for maximum outswing, inswing, off-break, or leg-break).
- **Step 3**: Speed power meter sweeping between $110\text{ km/h}$ and $152\text{ km/h}$ (hitting the peak sweetspot releases maximum pace without line dispersion).

### 3. Advanced AI Bowling Engine (`scripts/bowling/ai_bowler.gd`)
Features 4 distinct difficulty modes that dynamically adjust physics and tactics:
- **Easy**: Wide batting timing window ($\pm 45\text{ms}$), static pitch marker with long display time, predictable bowling ($118 - 126\text{ km/h}$), gentle pace.
- **Medium**: Balanced timing window ($\pm 26\text{ms}$), standard swing/seam movement ($130 - 138\text{ km/h}$), marker fades on pitch contact.
- **Hard**: Strict timing window ($\pm 16\text{ms}$), delayed pitch marker (fades halfway through run-up), deceptive slower balls ($112\text{ km/h}$) and reverse swing ($145\text{ km/h}$), actively targets batsman's weak zone outside off-stump to induce edges.
- **Legend / Pro**: Ultra-tight timing window ($\pm 9\text{ms}$), marker fades immediately upon bowler release ($0.18\text{s}$), express pace ($148 - 152\text{ km/h}$), lethal tactical traps (bouncers followed by toe-crushing yorkers).
- **Pitch Surface Intelligence**:
  - *Green Top*: AI exploits excessive seam movement and damp-air swing.
  - *Dusty / Cracking*: AI uses off-cutters and high-grip spin deviations.
  - *Flat Road*: AI utilizes changes of pace and yorkers in the blockhole.
  - *Wet / Damp*: AI aims low-skid deliveries straight at the stumps for LBW/bowled.

### 4. Seamless Role Switching
- Tap **Role: Batting** / **Role: Bowling** on the HUD to immediately swap between batting against the AI bowler or bowling with the interactive meters.

---

## 🚀 Headless Testing & CI (GitHub Actions)

Run headless physics, timing, and AI bowling tests:
```bash
godot --headless --script test/run_tests.gd
```

All 36 unit assertions are verified automatically on Ubuntu runners via GitHub Actions.

---

## 📦 Download Direct Android APK
Download the latest verified APK directly on your phone:
👉 **[Download CricStrike 3D APK (GitHub Release)](https://github.com/tomkamath-creator/cricket/releases)**
