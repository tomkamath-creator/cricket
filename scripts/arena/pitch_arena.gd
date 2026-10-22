# PitchArena.gd - CricStrike 3D
# Master Scene Coordinator: Pitch Arena, Aerodynamics, Batting, Bowling AI & Broadcast Replay
class_name PitchArena
extends Node3D

const GameConstants = preload("res://scripts/core/game_constants.gd")
const PitchConditions = preload("res://scripts/core/pitch_conditions.gd")
const StadiumBuilder = preload("res://scripts/arena/stadium_builder.gd")
const StumpsSet = preload("res://scripts/physics/stumps_set.gd")
const CricketBall = preload("res://scripts/physics/cricket_ball.gd")
const BattingController = preload("res://scripts/batting/batting_controller.gd")
const BroadcastCamera = preload("res://scripts/camera/broadcast_camera.gd")
const BattingHUD = preload("res://scripts/ui/batting_hud.gd")
const PitchMarker = preload("res://scripts/bowling/pitch_marker.gd")
const BowlingController = preload("res://scripts/bowling/bowling_controller.gd")
const BowlerTypes = preload("res://scripts/bowling/bowler_types.gd")

@onready var stadium_builder: StadiumBuilder = $StadiumBuilder
@onready var striker_wickets: StumpsSet = $StrikerWickets
@onready var non_striker_wickets: StumpsSet = $NonStrikerWickets
@onready var ball: CricketBall = $CricketBall
@onready var batsman: BattingController = $Batsman
@onready var broadcast_camera: BroadcastCamera = $BroadcastCamera
@onready var hud: BattingHUD = $BattingHUD
@onready var pitch_marker: PitchMarker = $PitchMarker
@onready var bowling_controller: BowlingController = $BowlingController
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun_light: DirectionalLight3D = $SunLight

var current_pitch_conditions: PitchConditions
var is_player_bowling_mode: bool = false
var _auto_timer: SceneTreeTimer = null

func _ready() -> void:
	current_pitch_conditions = PitchConditions.new(GameConstants.PitchType.FLAT)
	
	# Configure ball
	if ball:
		ball.pitch_conditions = current_pitch_conditions
		ball.ball_stopped.connect(_on_ball_stopped)
		
	# Wire camera references
	if broadcast_camera:
		broadcast_camera.ball_target = ball
		broadcast_camera.batsman_target = batsman
		
	# Wire batsman references
	if batsman:
		batsman.ball_ref = ball
		
	# Position wickets
	if striker_wickets:
		striker_wickets.position = Vector3(0.0, 0.0, GameConstants.PITCH_LENGTH * 0.5)
	if non_striker_wickets:
		non_striker_wickets.position = Vector3(0.0, 0.0, -GameConstants.PITCH_LENGTH * 0.5)

	# Configure Bowling Controller
	if bowling_controller:
		bowling_controller.ball_ref = ball
		bowling_controller.pitch_marker = pitch_marker
		bowling_controller.set_pitch_conditions(current_pitch_conditions)
		bowling_controller.delivery_released.connect(_on_delivery_released)
		bowling_controller.delivery_completed.connect(_on_delivery_completed)

	# Connect HUD & Replay Director
	if hud:
		hud.deliver_requested.connect(_on_hud_deliver_requested)
		hud.pitch_condition_changed.connect(set_pitch_condition)
		hud.difficulty_changed.connect(set_difficulty)
		hud.camera_toggle_requested.connect(_on_camera_toggle)
		hud.role_toggled.connect(_on_role_toggled)
		
		var replay_dir := get_node_or_null("BroadcastReplayDirector")
		if replay_dir:
			hud.bind_replay_director(replay_dir)
		
		if hud.bowling_meters_ui and bowling_controller:
			hud.bowling_meters_ui.bind_meters(bowling_controller.meters)
			hud.bowling_meters_ui.confirm_spot_pressed.connect(_on_player_confirm_spot)
			hud.bowling_meters_ui.lock_swing_pressed.connect(_on_player_lock_swing)
			hud.bowling_meters_ui.lock_speed_pressed.connect(_on_player_lock_speed)

	# Auto-start first ball after short broadcast warm-up
	var warm_timer := get_tree().create_timer(1.2)
	warm_timer.timeout.connect(func():
		if bowling_controller and bowling_controller.current_state == BowlingController.BowlingState.IDLE:
			start_bowling_delivery(is_player_bowling_mode)
	)

func _on_role_toggled(is_bowling: bool) -> void:
	is_player_bowling_mode = is_bowling
	if is_bowling:
		start_bowling_delivery(true)
	else:
		if bowling_controller:
			bowling_controller.complete_delivery()

func _on_hud_deliver_requested(_speed_kmh: float, _swing: float, _seam: float, _target_pos: Vector3) -> void:
	_auto_timer = null
	start_bowling_delivery(is_player_bowling_mode)

func start_bowling_delivery(player_is_bowler: bool) -> void:
	if not ball or not bowling_controller:
		return
		
	if striker_wickets and striker_wickets.is_broken():
		striker_wickets.reset_wickets()
		
	bowling_controller.start_new_delivery(player_is_bowler, batsman.is_right_handed if batsman else true)
	
	if player_is_bowler and hud and hud.bowling_meters_ui:
		hud.bowling_meters_ui.show_aiming_step()

func _on_player_confirm_spot() -> void:
	if bowling_controller:
		bowling_controller.player_confirm_pitch_target()
		if hud and hud.bowling_meters_ui:
			hud.bowling_meters_ui.show_swing_step()

func _on_player_lock_swing() -> void:
	if bowling_controller:
		var res: Dictionary = bowling_controller.player_stop_swing_meter()
		if hud and hud.timing_banner:
			hud.timing_banner.text = res.get("rating", "SWING LOCKED")
			hud.timing_banner.visible = true
			hud._start_fade_timer()
		if hud and hud.bowling_meters_ui:
			hud.bowling_meters_ui.show_speed_step()

func _on_player_lock_speed() -> void:
	if bowling_controller:
		var res: Dictionary = bowling_controller.player_stop_speed_meter()
		if hud and hud.timing_banner:
			hud.timing_banner.text = res.get("rating", "RELEASED!")
			hud.timing_banner.visible = true
			hud._start_fade_timer()
		if hud and hud.bowling_meters_ui:
			hud.bowling_meters_ui.hide_meters()

func _on_delivery_released(del_config: BowlerTypes.DeliveryConfig) -> void:
	if hud and hud.stats_label:
		hud.stats_label.text = "Delivery: %s (%.1f km/h) -> %s" % [
			del_config.name,
			del_config.speed_kmh,
			BowlerTypes.get_length_name(BowlerTypes.categorize_length(del_config.target_pitch_pos.z))
		]

func _on_delivery_completed() -> void:
	# Automatically queue and start next ball after 2.2s so match flows continuously
	if _auto_timer:
		_auto_timer = null
	_auto_timer = get_tree().create_timer(2.2)
	_auto_timer.timeout.connect(func():
		if bowling_controller and bowling_controller.current_state == BowlingController.BowlingState.IDLE:
			start_bowling_delivery(is_player_bowling_mode)
	)

func set_pitch_condition(type: GameConstants.PitchType) -> void:
	current_pitch_conditions.apply_pitch_type(type)
	if ball:
		ball.pitch_conditions = current_pitch_conditions
		if ball.physics_material_override:
			ball.physics_material_override.bounce = current_pitch_conditions.restitution
			ball.physics_material_override.friction = current_pitch_conditions.friction
			
	if bowling_controller:
		bowling_controller.set_pitch_conditions(current_pitch_conditions)
		
	# Update pitch visual color
	var pitch_surface := find_child("PitchSurface", true, false)
	if pitch_surface:
		var mi := pitch_surface.get_node_or_null("MeshInstance3D") as MeshInstance3D
		if mi and mi.mesh and mi.mesh.material is StandardMaterial3D:
			(mi.mesh.material as StandardMaterial3D).albedo_color = current_pitch_conditions.surface_color
			(mi.mesh.material as StandardMaterial3D).roughness = current_pitch_conditions.roughness

func set_difficulty(diff: GameConstants.Difficulty) -> void:
	if batsman:
		batsman.difficulty = diff
	if bowling_controller:
		bowling_controller.set_difficulty(diff)

func _on_camera_toggle() -> void:
	pass

func _on_ball_stopped() -> void:
	if bowling_controller:
		bowling_controller.complete_delivery()
