# BroadcastCamera.gd - CricStrike 3D
# Dynamic TV Broadcast and Batting camera tracking system
class_name BroadcastCamera
extends Camera3D

signal camera_mode_changed(mode_name: String)

enum CameraMode {
	BEHIND_BATSMAN,
	BROADCAST_SIDE,
	BALL_TRACKING,
	BOWLER_END,
	UMPIRE_POV,
	BATSMAN_HELMET_POV
}

@export var current_mode: CameraMode = CameraMode.BEHIND_BATSMAN
@export var ball_target: CricketBall
@export var batsman_target: Node3D
@export var follow_damping: float = 6.0

# Target presets (WCC2 & Real Cricket camera style: higher angle looking down pitch towards bowler)
var _pos_behind_batsman := Vector3(0.0, 3.2, 14.5)
var _look_behind_batsman := Vector3(0.0, 0.85, 0.0)

var _pos_broadcast_side := Vector3(-26.0, 10.5, 2.0)
var _pos_bowler_end := Vector3(0.0, 3.2, -15.5)
var _look_bowler_end := Vector3(0.0, 0.9, 8.0)

var _pos_umpire_pov := Vector3(0.0, 1.82, -12.4)
var _look_umpire_pov := Vector3(0.0, 0.85, 9.5)

var _pos_batsman_pov := Vector3(0.15, 1.68, 9.15)
var _look_batsman_pov := Vector3(0.0, 0.9, -10.0)

var _target_pos: Vector3
var _target_look_at: Vector3

func _ready() -> void:
	current = true
	set_camera_mode(current_mode)
	global_position = _target_pos
	look_at(_target_look_at, Vector3.UP)

func get_mode_name() -> String:
	match current_mode:
		CameraMode.BEHIND_BATSMAN: return "Behind Batsman"
		CameraMode.BROADCAST_SIDE: return "Broadcast TV"
		CameraMode.BALL_TRACKING: return "Ball Tracking"
		CameraMode.BOWLER_END: return "Bowler POV"
		CameraMode.UMPIRE_POV: return "Umpire POV"
		CameraMode.BATSMAN_HELMET_POV: return "Helmet POV"
	return "Camera"

func set_camera_mode(mode: CameraMode) -> void:
	current_mode = mode
	match mode:
		CameraMode.BEHIND_BATSMAN:
			_target_pos = _pos_behind_batsman
			_target_look_at = _look_behind_batsman
			fov = 58.0
		CameraMode.BROADCAST_SIDE:
			_target_pos = _pos_broadcast_side
			_target_look_at = Vector3(0.0, 0.7, 4.0)
			fov = 48.0
		CameraMode.BOWLER_END:
			_target_pos = _pos_bowler_end
			_target_look_at = _look_bowler_end
			fov = 55.0
		CameraMode.UMPIRE_POV:
			_target_pos = _pos_umpire_pov
			_target_look_at = _look_umpire_pov
			fov = 52.0
		CameraMode.BATSMAN_HELMET_POV:
			_target_pos = _pos_batsman_pov
			_target_look_at = _look_batsman_pov
			fov = 68.0
		CameraMode.BALL_TRACKING:
			fov = 52.0
	camera_mode_changed.emit(get_mode_name())

func _physics_process(delta: float) -> void:
	if current_mode == CameraMode.BALL_TRACKING:
		if ball_target and is_instance_valid(ball_target) and ball_target.is_active:
			var ball_pos := ball_target.global_position
			# Camera tracks behind and slightly above the ball flight
			var offset := Vector3(0.0, 3.5, 6.5)
			if ball_target.linear_velocity.length() > 2.0:
				var vel_dir := ball_target.linear_velocity.normalized()
				offset = -vel_dir * 5.5 + Vector3(0.0, 2.5, 0.0)
			
			_target_pos = ball_pos + offset
			_target_look_at = ball_pos
		else:
			# Return to behind batsman when ball comes to rest
			set_camera_mode(CameraMode.BEHIND_BATSMAN)

	elif current_mode == CameraMode.BROADCAST_SIDE:
		if ball_target and is_instance_valid(ball_target) and ball_target.is_active:
			_target_look_at = ball_target.global_position
		elif batsman_target and is_instance_valid(batsman_target):
			_target_look_at = batsman_target.global_position

	# Smoothly interpolate position and orientation
	global_position = global_position.lerp(_target_pos, delta * follow_damping)
	
	var cur_rot := global_transform.basis
	var target_transform := global_transform.looking_at(_target_look_at, Vector3.UP)
	global_transform.basis = cur_rot.slerp(target_transform.basis, delta * follow_damping * 1.5)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_camera"):
		cycle_camera_mode()

func cycle_camera_mode() -> void:
	var next_mode := (int(current_mode) + 1) % 6
	set_camera_mode(next_mode as CameraMode)
