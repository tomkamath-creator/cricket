# BattingHUD.gd - CricStrike 3D
# Complete Touch UI, Virtual Controls, Timing Feedback HUD & Debug Delivery Controls
class_name BattingHUD
extends CanvasLayer

signal deliver_requested(speed_kmh: float, swing: float, seam: float, target_pos: Vector3)
signal pitch_condition_changed(new_type: GameConstants.PitchType)
signal difficulty_changed(new_diff: GameConstants.Difficulty)
signal camera_toggle_requested()

@export var batsman: BattingController
@export var ball: CricketBall
@export var camera_controller: BroadcastCamera

# UI Elements
@onready var joystick: VirtualJoystick = $BottomLeftControls/VirtualJoystick
@onready var shot_name_label: Label = $TopCenter/ShotNameLabel
@onready var timing_banner: Label = $CenterContainer/TimingBanner
@onready var stats_label: Label = $TopCenter/StatsLabel
@onready var grounded_btn: Button = $BottomRightControls/VBoxContainer/GroundedButton
@onready var lofted_btn: Button = $BottomRightControls/VBoxContainer/LoftedButton
@onready var bowl_debug_btn: Button = $TopRightControls/BowlDebugButton
@onready var pitch_btn: Button = $TopRightControls/PitchButton
@onready var difficulty_btn: Button = $TopRightControls/DifficultyButton
@onready var camera_btn: Button = $TopRightControls/CameraButton

var current_difficulty: GameConstants.Difficulty = GameConstants.Difficulty.MEDIUM
var current_pitch_type: GameConstants.PitchType = GameConstants.PitchType.FLAT

# Sample delivery presets for testing
var _delivery_presets: Array[Dictionary] = [
	{"name": "Good Length Fast Outswinger", "speed": 142.0, "swing": -0.65, "seam": 2.0, "target": Vector3(0.25, 0.05, 5.5)},
	{"name": "Full Inswinger", "speed": 138.0, "swing": 0.70, "seam": -1.5, "target": Vector3(-0.15, 0.05, 7.2)},
	{"name": "Toe-Crusher Yorker", "speed": 148.0, "swing": 0.20, "seam": 0.0, "target": Vector3(0.0, 0.02, 8.8)},
	{"name": "Bouncer (Short Pitch)", "speed": 135.0, "swing": 0.0, "seam": 3.0, "target": Vector3(0.2, 0.05, 2.5)},
	{"name": "Slow Off-Cutter", "speed": 112.0, "swing": 0.0, "seam": -4.0, "target": Vector3(0.3, 0.05, 6.0)}
]
var _preset_index: int = 0

func _ready() -> void:
	# Connect Joystick
	if joystick:
		joystick.joystick_vector_changed.connect(_on_joystick_vector_changed)
		joystick.shot_sector_changed.connect(_on_shot_sector_changed)
		
	# Connect Buttons
	if grounded_btn:
		grounded_btn.pressed.connect(func(): _on_shot_button_pressed(GameConstants.ShotElevation.GROUNDED))
	if lofted_btn:
		lofted_btn.pressed.connect(func(): _on_shot_button_pressed(GameConstants.ShotElevation.LOFTED))
	if bowl_debug_btn:
		bowl_debug_btn.pressed.connect(_on_bowl_debug_pressed)
	if pitch_btn:
		pitch_btn.pressed.connect(_on_cycle_pitch_type)
	if difficulty_btn:
		difficulty_btn.pressed.connect(_on_cycle_difficulty)
	if camera_btn:
		camera_btn.pressed.connect(func(): camera_toggle_requested.emit())
		
	# Connect Batsman signals
	if batsman:
		batsman.shot_executed.connect(_on_shot_executed)
		batsman.shot_missed.connect(_on_shot_missed)
		
	# Connect Ball signals
	if ball:
		ball.ball_boundary.connect(_on_ball_boundary)
		ball.ball_stump_collision.connect(_on_stump_collision)
		
	_update_hud_display()
	_hide_timing_banner()

func _on_joystick_vector_changed(vector: Vector2) -> void:
	if batsman:
		batsman.set_joystick_direction(vector)

func _on_shot_sector_changed(direction: GameConstants.ShotDirection) -> void:
	var grounded_shot := ShotLibrary.get_shot(direction, GameConstants.ShotElevation.GROUNDED)
	var lofted_shot := ShotLibrary.get_shot(direction, GameConstants.ShotElevation.LOFTED)
	if shot_name_label:
		shot_name_label.text = "Target: %s / %s" % [grounded_shot.name, lofted_shot.name]

func _on_shot_button_pressed(elevation: GameConstants.ShotElevation) -> void:
	if batsman:
		var result := batsman.trigger_shot(elevation)
		if result:
			_display_timing_feedback(result)

func _on_shot_executed(result: TimingEngine.TimingResult) -> void:
	_display_timing_feedback(result)

func _on_shot_missed() -> void:
	if timing_banner:
		timing_banner.text = "BEATEN / MISSED"
		timing_banner.modulate = Color(0.65, 0.25, 0.25)
		timing_banner.visible = true
		_start_fade_timer()

func _display_timing_feedback(result: TimingEngine.TimingResult) -> void:
	if not timing_banner:
		return
		
	timing_banner.visible = true
	timing_banner.text = result.feedback_text
	timing_banner.modulate = result.rating_color
	
	if stats_label:
		if result.rating != GameConstants.TimingRating.MISSED:
			stats_label.text = "%s | Timing: %+.0f ms | Speed: %.1f km/h | Launch: %.1f°" % [
				result.shot_name,
				result.delta_ms,
				result.exit_speed_kmh,
				result.launch_angle_deg
			]
		else:
			stats_label.text = "%s | Timing: %+.0f ms" % [result.shot_name, result.delta_ms]
			
	# Camera automatic switch to ball chase on good hits
	if result.rating in [GameConstants.TimingRating.PERFECT, GameConstants.TimingRating.EARLY, GameConstants.TimingRating.LATE] and camera_controller:
		camera_controller.set_camera_mode(BroadcastCamera.CameraMode.BALL_TRACKING)
		
	_start_fade_timer()

func _start_fade_timer() -> void:
	var timer := get_tree().create_timer(2.2)
	timer.timeout.connect(_hide_timing_banner)

func _hide_timing_banner() -> void:
	if timing_banner:
		timing_banner.visible = false

func _on_bowl_debug_pressed() -> void:
	var preset: Dictionary = _delivery_presets[_preset_index]
	_preset_index = (_preset_index + 1) % _delivery_presets.size()
	
	if stats_label:
		stats_label.text = "Bowling: %s (%.0f km/h)" % [preset["name"], preset["speed"]]
		
	deliver_requested.emit(preset["speed"], preset["swing"], preset["seam"], preset["target"])

func _on_cycle_pitch_type() -> void:
	current_pitch_type = ((int(current_pitch_type) + 1) % 4) as GameConstants.PitchType
	pitch_condition_changed.emit(current_pitch_type)
	_update_hud_display()

func _on_cycle_difficulty() -> void:
	current_difficulty = ((int(current_difficulty) + 1) % 4) as GameConstants.Difficulty
	if batsman:
		batsman.difficulty = current_difficulty
	difficulty_changed.emit(current_difficulty)
	_update_hud_display()

func _update_hud_display() -> void:
	if pitch_btn:
		var p_name: String
		match current_pitch_type:
			GameConstants.PitchType.GREEN: p_name = "Pitch: Green"
			GameConstants.PitchType.DUSTY: p_name = "Pitch: Dusty"
			GameConstants.PitchType.FLAT:  p_name = "Pitch: Flat"
			GameConstants.PitchType.WET:   p_name = "Pitch: Wet"
		pitch_btn.text = p_name

	if difficulty_btn:
		var d_name: String
		match current_difficulty:
			GameConstants.Difficulty.EASY:   d_name = "Diff: Easy"
			GameConstants.Difficulty.MEDIUM: d_name = "Diff: Medium"
			GameConstants.Difficulty.HARD:   d_name = "Diff: Hard"
			GameConstants.Difficulty.LEGEND: d_name = "Diff: Legend"
		difficulty_btn.text = d_name

func _on_ball_boundary(runs: int) -> void:
	if timing_banner:
		timing_banner.visible = true
		timing_banner.text = "FOUR! BOUNDARY!" if runs == 4 else "MAXIMUM! SIX RUNS!"
		timing_banner.modulate = Color(0.2, 0.9, 1.0)
		_start_fade_timer()

func _on_stump_collision(_stump: Node, _speed: float) -> void:
	if timing_banner:
		timing_banner.visible = true
		timing_banner.text = "BOWLED! WICKET DOWN!"
		timing_banner.modulate = Color(1.0, 0.2, 0.2)
		_start_fade_timer()
