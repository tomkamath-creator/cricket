# PitchArena.gd - CricStrike 3D
# Master Scene Coordinator for Phase 1: 3D Pitch Arena, Ball Physics & Batting Timing Engine
class_name PitchArena
extends Node3D

@onready var stadium_builder: StadiumBuilder = $StadiumBuilder
@onready var striker_wickets: StumpsSet = $StrikerWickets
@onready var non_striker_wickets: StumpsSet = $NonStrikerWickets
@onready var ball: CricketBall = $CricketBall
@onready var batsman: BattingController = $Batsman
@onready var broadcast_camera: BroadcastCamera = $BroadcastCamera
@onready var hud: BattingHUD = $BattingHUD
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun_light: DirectionalLight3D = $SunLight

var current_pitch_conditions: PitchConditions

func _ready() -> void:
	current_pitch_conditions = PitchConditions.new(GameConstants.PitchType.FLAT)
	
	# Configure ball
	if ball:
		ball.pitch_conditions = current_pitch_conditions
		ball.ball_stopped.connect(_on_ball_stopped)
		
	# Connect HUD
	if hud:
		hud.deliver_requested.connect(bowl_delivery)
		hud.pitch_condition_changed.connect(set_pitch_condition)
		hud.difficulty_changed.connect(set_difficulty)
		hud.camera_toggle_requested.connect(_on_camera_toggle)
		
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

func bowl_delivery(speed_kmh: float, swing: float, seam: float, target_pos: Vector3) -> void:
	if not ball:
		return
		
	# Reset wickets if shattered on previous ball
	if striker_wickets and striker_wickets.is_broken():
		striker_wickets.reset_wickets()
		
	# Bowler delivery release point near bowling crease
	var bowler_release_point := Vector3(0.4, 2.15, -GameConstants.PITCH_LENGTH * 0.5 + 0.3)
	
	# Launch physics ball
	ball.launch_delivery(bowler_release_point, target_pos, speed_kmh, swing, seam)
	
	# Switch camera to broadcast or behind batsman if it was in ball tracking mode
	if broadcast_camera and broadcast_camera.current_mode == BroadcastCamera.CameraMode.BALL_TRACKING:
		broadcast_camera.set_camera_mode(BroadcastCamera.CameraMode.BEHIND_BATSMAN)

func set_pitch_condition(type: GameConstants.PitchType) -> void:
	current_pitch_conditions.apply_pitch_type(type)
	if ball:
		ball.pitch_conditions = current_pitch_conditions
		if ball.physics_material_override:
			ball.physics_material_override.bounce = current_pitch_conditions.restitution
			ball.physics_material_override.friction = current_pitch_conditions.friction
			
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

func _on_camera_toggle() -> void:
	if broadcast_camera:
		var next := (int(broadcast_camera.current_mode) + 1) % 4
		broadcast_camera.set_camera_mode(next as BroadcastCamera.CameraMode)

func _on_ball_stopped() -> void:
	# Ready for next delivery
	pass
