# BattingController.gd - CricStrike 3D
# Batsman controller, 8-way directional shot triggering, bat animation and contact handling
class_name BattingController
extends Node3D

signal shot_executed(result: TimingEngine.TimingResult)
signal shot_missed()

@export var is_right_handed: bool = true
@export var difficulty: GameConstants.Difficulty = GameConstants.Difficulty.MEDIUM

# Batting Nodes
@export var bat_node: Node3D
@export var ball_ref: CricketBall

# State
var current_shot_direction: GameConstants.ShotDirection = GameConstants.ShotDirection.STRAIGHT
var is_swinging: bool = false
var strike_plane_z: float = 9.05 # Ideal contact plane along Z (near popping crease)

# Procedural bat swing animation
var _swing_time: float = 0.0
var _swing_duration: float = 0.38
var _bat_initial_rot: Vector3 = Vector3.ZERO
var _bat_initial_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	if bat_node:
		_bat_initial_rot = bat_node.rotation_degrees
		_bat_initial_pos = bat_node.position
	else:
		# Search children for bat node
		var found_bat := find_child("Bat", true, false)
		if found_bat and found_bat is Node3D:
			bat_node = found_bat
			_bat_initial_rot = bat_node.rotation_degrees
			_bat_initial_pos = bat_node.position

func set_joystick_direction(input_vector: Vector2) -> void:
	current_shot_direction = ShotLibrary.vector_to_direction(input_vector)

func trigger_shot(elevation: GameConstants.ShotElevation) -> TimingEngine.TimingResult:
	if is_swinging:
		return null
		
	var shot_data := ShotLibrary.get_shot(current_shot_direction, elevation)
	_start_swing_animation(shot_data)
	
	var result: TimingEngine.TimingResult
	if ball_ref and is_instance_valid(ball_ref) and ball_ref.is_active and not ball_ref.has_been_hit:
		result = TimingEngine.evaluate_contact(
			ball_ref.global_position,
			ball_ref.linear_velocity,
			strike_plane_z,
			shot_data,
			difficulty
		)
		
		if result.rating != GameConstants.TimingRating.MISSED:
			ball_ref.apply_bat_hit(result.exit_velocity)
			shot_executed.emit(result)
		else:
			shot_missed.emit()
	else:
		# Free swing without ball
		result = TimingEngine.TimingResult.new()
		result.shot_name = shot_data.name
		result.rating = GameConstants.TimingRating.MISSED
		result.feedback_text = "SWING"
		shot_missed.emit()
		
	return result

func _start_swing_animation(shot_data: ShotLibrary.ShotData) -> void:
	is_swinging = true
	_swing_time = 0.0
	
	if bat_node:
		# Dynamic bat swing rotation based on shot direction and elevation
		var target_yaw := shot_data.bat_arc_angle_deg
		var target_pitch := -45.0 if shot_data.elevation == GameConstants.ShotElevation.LOFTED else -15.0
		
		var tween := create_tween()
		tween.tween_property(bat_node, "rotation_degrees", Vector3(target_pitch, target_yaw, 30.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(bat_node, "rotation_degrees", Vector3(20.0, target_yaw + 60.0, -40.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(bat_node, "rotation_degrees", _bat_initial_rot, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.finished.connect(func(): is_swinging = false)
	else:
		get_tree().create_timer(_swing_duration).timeout.connect(func(): is_swinging = false)

func _process(delta: float) -> void:
	# Keyboard / Desktop fallback controls for testing
	if Input.is_action_just_pressed("shot_grounded"):
		trigger_shot(GameConstants.ShotElevation.GROUNDED)
	elif Input.is_action_just_pressed("shot_lofted"):
		trigger_shot(GameConstants.ShotElevation.LOFTED)
