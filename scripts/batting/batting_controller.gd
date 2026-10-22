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

# Procedural bat swing & idle stance animation
var _swing_time: float = 0.0
var _swing_duration: float = 0.38
var _bat_initial_rot: Vector3 = Vector3.ZERO
var _bat_initial_pos: Vector3 = Vector3.ZERO
var _idle_time: float = 0.0

@onready var humanoid_model: Node3D = get_node_or_null("HumanoidModel")
var anim_player: AnimationPlayer

func _ready() -> void:
	_setup_character_animations()
	if bat_node:
		_bat_initial_rot = bat_node.rotation_degrees
		_bat_initial_pos = bat_node.position
	else:
		var found_bat := find_child("Bat", true, false)
		if found_bat and found_bat is Node3D:
			bat_node = found_bat
			_bat_initial_rot = bat_node.rotation_degrees
			_bat_initial_pos = bat_node.position

func _setup_character_animations() -> void:
	if humanoid_model == null:
		humanoid_model = get_node_or_null("HumanoidModel")
	if humanoid_model == null:
		return
		
	var armature := humanoid_model.get_node_or_null("Armature")
	if armature:
		anim_player = armature.get_node_or_null("AnimationPlayer") as AnimationPlayer
		if anim_player == null:
			anim_player = AnimationPlayer.new()
			anim_player.name = "AnimationPlayer"
			armature.add_child(anim_player)
			
		var anim_lib: AnimationLibrary = load("res://assets/animations/cricket_animations.tres")
		if anim_lib and not anim_player.has_animation_library(""):
			anim_player.add_animation_library("", anim_lib)
			
		if anim_player.has_animation("stance"):
			anim_player.play("stance")
			
		# Attach bat to hand bone if available
		var skel: Skeleton3D = armature.get_node_or_null("Skeleton3D")
		if skel and bat_node and bat_node.get_parent() != skel:
			var hand_bone := skel.find_bone("mixamorig_RightHand")
			if hand_bone >= 0:
				var bone_attach = BoneAttachment3D.new()
				bone_attach.bone_name = "mixamorig_RightHand"
				skel.add_child(bone_attach)
				bat_node.reparent(bone_attach)
				bat_node.position = Vector3(0.04, -0.05, 0.08)
				bat_node.rotation_degrees = Vector3(15.0, 45.0, -90.0)
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
	
	if anim_player:
		if shot_data.elevation == GameConstants.ShotElevation.LOFTED:
			anim_player.play("pull")
			anim_player.speed_scale = 1.6
		else:
			anim_player.play("swing")
			anim_player.speed_scale = 1.4
	
	if bat_node:
		# Dynamic bat swing rotation based on shot direction and elevation
		var target_yaw := shot_data.bat_arc_angle_deg
		var target_pitch := -45.0 if shot_data.elevation == GameConstants.ShotElevation.LOFTED else -15.0
		
		var tween := create_tween()
		tween.tween_property(bat_node, "rotation_degrees", Vector3(target_pitch, target_yaw, 30.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(bat_node, "rotation_degrees", Vector3(20.0, target_yaw + 60.0, -40.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(bat_node, "rotation_degrees", _bat_initial_rot, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.finished.connect(func():
			is_swinging = false
			if anim_player and anim_player.has_animation("stance"):
				anim_player.play("stance")
				anim_player.speed_scale = 1.0
		)
	else:
		get_tree().create_timer(_swing_duration).timeout.connect(func():
			is_swinging = false
			if anim_player and anim_player.has_animation("stance"):
				anim_player.play("stance")
				anim_player.speed_scale = 1.0
		)

func _process(delta: float) -> void:
	# Subtle natural breathing & bat tapping idle cycle (Real Cricket / WCC2 stance)
	if not is_swinging and bat_node:
		_idle_time += delta * 4.5
		var bat_tap: float = sin(_idle_time) * 4.0
		bat_node.rotation_degrees.x = _bat_initial_rot.x + bat_tap
		if humanoid_model:
			humanoid_model.position.y = (sin(_idle_time * 0.5) * 0.012)
			
	# Keyboard / Desktop fallback controls for testing
	if Input.is_action_just_pressed("shot_grounded"):
		trigger_shot(GameConstants.ShotElevation.GROUNDED)
	elif Input.is_action_just_pressed("shot_lofted"):
		trigger_shot(GameConstants.ShotElevation.LOFTED)
