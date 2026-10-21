# CricStrike 3D 🏏

A production-quality, 100% offline 3D mobile cricket game inspired by *Real Cricket*, built from the ground up for **Godot Engine 4.x** with mobile/Android performance optimization.

---

## 🎯 Phase 1 Completed: 3D Pitch Arena, Ball Physics & Batting Timing Engine

### 1. 3D Stadium & Regulation 20.12m Pitch Arena (`scripts/arena/`)
- **Pitch Strip**: Regulation 20.12-meter (22 yards) length with 3.05-meter width.
- **Crease Markings**:
  - Bowling creases ($Z = \pm 10.06\text{m}$, width $2.64\text{m}$).
  - Popping creases ($1.22\text{m}$ in front of bowling creases, width $3.66\text{m}$).
  - Return creases extending $2.44\text{m}$.
- **Stadium Architecture**:
  - Circular/elliptical outfield grass turf ($R = 80\text{m}$).
  - Boundary foam cushion rope ($R_x = 68\text{m}, R_z = 72\text{m}$).
  - Dual sight screens behind bowler and striker wickets.
  - 3-tiered grandstand perimeter and 4 corner floodlight towers.
- **Pitch Conditions Engine (`scripts/core/pitch_conditions.gd`)**:
  - **Green**: High bounce (restitution $0.82$), high seam deviation, boosted swing in damp air.
  - **Dusty**: Low bounce (restitution $0.64$), abrasive spin grip, variable turn.
  - **Flat**: True, predictable bounce (restitution $0.80$), consistent pace, batter's paradise.
  - **Wet**: Skidding low bounce (restitution $0.58$), reduced spin, high skid factor.

---

### 2. Physical Wickets & Stumps with Dislodging (`scripts/physics/stumps_set.gd`)
- 3 individual rigid body stumps (**Off**, **Middle**, **Leg**) regulation height ($0.711\text{m} / 28\text{"}$).
- 2 resting bails on top grooves.
- Realistic collision impulse detection:
  - Direct hits dislodge the bails with explosive upward and backward angular torque.
  - Stumps wobble, tilt, and tumble dynamically upon impact.
  - Instant state reset functionality for subsequent deliveries.

---

### 3. Aerodynamic Ball Physics Engine (`scripts/physics/cricket_ball.gd`)
- Standard $160\text{g}$ regulation mass and $3.6\text{cm}$ radius.
- Real-time **aerodynamic quadratic drag** ($F_d = \frac{1}{2} C_d \rho A v^2$).
- **Magnus & asymmetric boundary layer swing force** simulating conventional and reverse swing.
- Dynamic bounce calculation upon pitch impact factoring in seam tilt, spin vector, and pitch conditions.
- Continuous collision detection (`continuous_cd = true`) to prevent tunneling at high speeds ($150+\text{ km/h}$).

---

### 4. 8-Directional Batting & Millisecond Timing Window Engine (`scripts/batting/`)
- **8-Way Directional Mapping**:
  1. **Straight Drive / Lofted Straight Drive** (Up)
  2. **Cover Drive / Inside-out Lofted Cover** (Up-Left)
  3. **Square Cut / Upper Cut** (Left)
  4. **Late Cut / Ramp Scoop** (Down-Left)
  5. **Backfoot Defense / Helicopter Shot** (Down)
  6. **Leg Glance / Hook Shot** (Down-Right)
  7. **Square Leg / Pull Shot** (Right)
  8. **On Drive / Slog Sweep** (Up-Right)
- **Millisecond Timing Engine (`scripts/batting/timing_engine.gd`)**:
  - Evaluates contact delta $\Delta t = t_{\text{input}} - t_{\text{sweetspot}}$.
  - Categorizes into: `PERFECT`, `EARLY`, `LATE`, `TOO_EARLY`, `TOO_LATE`, `MISSED`.
  - Calculates exit speed (km/h) and launch angle based on bat speed, incoming pace, restitution, and timing accuracy.
  - Generates realistic inside/outside edges to keeper or slips on mistimed or wide balls.
- **Difficulty Multipliers**:
  - **Easy**: $\pm 45\text{ms}$ perfect window, $\pm 95\text{ms}$ normal.
  - **Medium**: $\pm 26\text{ms}$ perfect window, $\pm 62\text{ms}$ normal.
  - **Hard**: $\pm 16\text{ms}$ perfect window, $\pm 38\text{ms}$ normal.
  - **Legend**: $\pm 9\text{ms}$ ultra-tight window, $\pm 22\text{ms}$ normal.

---

### 5. Broadcast Camera System (`scripts/camera/broadcast_camera.gd`)
- Multi-mode dynamic broadcast camera rig:
  - `BEHIND_BATSMAN`: Default batting view behind the batsman.
  - `BROADCAST_SIDE`: TV broadcast side camera panning from the stadium gantry.
  - `BALL_TRACKING`: Follows the cricket ball on lofted hits and boundary trajectories.
  - `BOWLER_END`: Bowler's run-up perspective looking down the pitch.

---

### 6. Mobile Touch & Testing HUD (`scripts/ui/`)
- **Virtual 8-direction analog joystick** on bottom-left for touch and mouse.
- **Grounded & Lofted** buttons on bottom-right.
- **Timing Feedback Banner**: Displays color-coded real-time feedback (`PERFECT!`, `EARLY`, `LATE`, `EDGE`).
- **Pace & Launch Angle Telemetry**: Displays exit velocity in km/h, timing in ms, and launch angle in degrees.
- **Interactive Debug Bar**: Instant delivery pitching button (test Full, Good Length, Yorker, Bouncer, Outswinger), pitch condition switcher, and difficulty switcher.

---

## 🚀 Headless Testing & CI (GitHub Actions)

The repository includes a complete headless test runner (`test/run_tests.gd`) that runs automatically in GitHub Actions on every push/PR:

```bash
# Run headless tests locally using Godot 4.3:
godot --headless --script test/run_tests.gd
```

### GitHub Actions Workflow
The workflow `.github/workflows/godot_ci.yml` automatically:
1. Downloads and caches the headless Godot 4.3 engine on Ubuntu.
2. Validates project structure and GDScript syntax.
3. Executes `test/run_tests.gd` to test pitch geometry, aerodynamics, stumps dislodging, and timing accuracy.

---

## 📁 Repository Structure (Kept clean within GitHub limits)

```
├── .github/
│   └── workflows/
│       └── godot_ci.yml       # Automated GitHub Actions test workflow
├── scenes/
│   ├── cricket_ball.tscn      # RigidBody3D ball with collision
│   ├── stumps_set.tscn        # 3 stumps + 2 bails physical set
│   ├── batsman.tscn           # 3D Batsman with bat and swing animation
│   ├── ui_hud.tscn            # Virtual joystick, buttons, timing meter
│   └── main_arena.tscn        # Master 3D playable pitch arena scene
├── scripts/
│   ├── core/
│   │   ├── game_constants.gd  # Dimensions, physical constants, ratings
│   │   └── pitch_conditions.gd# Green, Dusty, Flat, Wet physics
│   ├── physics/
│   │   ├── cricket_ball.gd    # Ball aerodynamics, swing & bounce
│   │   └── stumps_set.gd      # Stumps & bails dislodging mechanics
│   ├── batting/
│   │   ├── shot_library.gd    # 8-way shot database & trajectory angles
│   │   ├── timing_engine.gd   # Millisecond timing window calculation
│   │   └── batting_controller.gd # Batsman control & swing execution
│   ├── camera/
│   │   └── broadcast_camera.gd # Multi-mode broadcast TV camera
│   ├── ui/
│   │   ├── virtual_joystick.gd # 8-way mobile touch virtual joystick
│   │   └── batting_hud.gd     # HUD overlay, telemetry & delivery tester
│   └── arena/
│       ├── stadium_builder.gd # 20.12m pitch, creases, stands, floodlights
│       └── pitch_arena.gd     # Main arena coordinator
├── test/
│   ├── run_tests.gd           # Headless CI runner
│   ├── test_pitch_physics.gd  # Dimensions & bounce unit tests
│   ├── test_timing_engine.gd  # Timing window & ratings tests
│   └── test_stump_collision.gd# Stumps shatter & reset tests
├── project.godot              # Godot 4 project configuration
└── icon.svg                   # Project icon
```

---

## 🎮 Desktop Keyboard Shortcuts
- `Space`: Grounded Shot
- `Shift` or `L`: Lofted Shot
- `B`: Bowl Debug Delivery
- `P`: Switch Pitch Condition (Green / Dusty / Flat / Wet)
- `C`: Switch Camera View
