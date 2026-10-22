# FielderController.gd - CricStrike 3D
# Individual 3D Fielder Agent with State Machine (Idle -> Chase -> Slide/Pickup -> Throw -> Return)
class_name FielderController
extends Node3D

signal ball_fielded(fielder_name: String, was_catch: bool)
signal ball_thrown(target_end_is_striker: bool, throw_speed: float)

const GameConstants = preload("res://scripts/core/game_constants.gd")
const CricketBall = preload("res://scripts/physics/cricket_ball.gd")

enum FielderState {
	IDLE,
	ANTICIPATING,
	CHASE_BALL,
	SLIDE_OR_PICKUP,
	THROW_TO_END,
	RETURN_TO_POSITION
}

@export var fielder_name: String = "Fielder"
@export var sprint_speed: float = 8.2  # m/s (~30 km/h sprint)
@export var acceleration: float = 12.0
@export var catch_radius: float = 1.3  # Catch range in meters
@export var pickup_radius: float = 0.85 # Ground pickup range in meters
@export var throw_speed_mps: float = 26.0 # ~94 km/h throw

var current_state: FielderState = FielderState.IDLE
var home_position: Vector3 = Vector3.ZERO
var target_ball: CricketBall
var has_ball: bool = false

# Internal kinematics
var _current_velocity: Vector3 = Vector3.ZERO
var _slide_timer: float = 0.0
var _throw_timer: float = 0.0
var _run_cycle_time: float = 0.0

@onready var mesh_root: Node3D = $MeshRoot
@onready var left_leg: Node3D = $MeshRoot/LeftLeg
@onready var right_leg: Node3D = $MeshRoot/RightLeg

func _ready() -> void:
	home_position = global_position

func assign_home_position(pos: Vector3) -> void:
	home_position = pos
	global_position = pos

func react_to_shot(ball: CricketBall, is_primary_chaser: bool) -> void:
	target_ball = ball
	has_ball = false
	if is_primary_chaser:
		current_state = FielderState.CHASE_BALL
	else:
		current_state = FielderState.ANTICIPATING

func _physics_process(delta: float) -> void:
	match current_state:
		FielderState.IDLE:
			_process_idle(delta)
		FielderState.ANTICIPATING:
			_process_anticipation(delta)
		FielderState.CHASE_BALL:
			_process_chase(delta)
		FielderState.SLIDE_OR_PICKUP:
			_process_pickup(delta)
		FielderState.THROW_TO_END:
			_process_throw(delta)
		FielderState.RETURN_TO_POSITION:
			_process_return(delta)

func _process_idle(_delta: float) -> void:
	# Face the pitch center
	var look_target := Vector3(0.0, global_position.y, 0.0)
	if global_position.distance_to(look_target) > 0.5:
		look_at(look_target, Vector3.UP)

func _process_anticipation(_delta: float) -> void:
	if not target_ball or not is_instance_valid(target_ball):
		current_state = FielderState.IDLE
		return
	# Turn to face ball flight
	var ball_pos := target_ball.global_position
	look_at(Vector3(ball_pos.x, global_position.y, ball_pos.z), Vector3.UP)

func _process_chase(delta: float) -> void:
	if not target_ball or not is_instance_valid(target_ball):
		current_state = FielderState.RETURN_TO_POSITION
		return
		
	var ball_pos := target_ball.global_position
	var flat_ball := Vector3(ball_pos.x, global_position.y, ball_pos.z)
	var dist_to_ball := global_position.distance_to(flat_ball)
	
	# Check for Catch on the full
	if not target_ball.has_pitched and ball_pos.y <= 2.2 and dist_to_ball <= catch_radius:
		_execute_catch()
		return
		
	# Check for Ground Pickup / Slide
	if target_ball.has_pitched and dist_to_ball <= pickup_radius:
		_execute_pickup()
		return
		
	# Move toward ball interception point
	var dir := (flat_ball - global_position).normalized()
	_current_velocity = _current_velocity.move_toward(dir * sprint_speed, acceleration * delta)
	global_position += _current_velocity * delta
	
	# Animate leg stride swing during pursuit sprint
	_run_cycle_time += delta * 12.0
	if left_leg and right_leg:
		left_leg.rotation_degrees.x = sin(_run_cycle_time) * 35.0
		right_leg.rotation_degrees.x = -sin(_run_cycle_time) * 35.0
	
	if _current_velocity.length() > 0.5:
		look_at(global_position + _current_velocity, Vector3.UP)

func _execute_catch() -> void:
	current_state = FielderState.THROW_TO_END
	has_ball = true
	_throw_timer = 0.25
	if target_ball:
		target_ball.freeze = true
		target_ball.global_position = global_position + Vector3(0.0, 1.2, 0.0)
	ball_fielded.emit(fielder_name, true)

func _execute_pickup() -> void:
	current_state = FielderState.SLIDE_OR_PICKUP
	has_ball = true
	_slide_timer = 0.35
	if target_ball:
		target_ball.linear_velocity = target_ball.linear_velocity * 0.1
	ball_fielded.emit(fielder_name, false)

func _process_pickup(delta: float) -> void:
	_slide_timer -= delta
	_current_velocity = _current_velocity.move_toward(Vector3.ZERO, acceleration * 1.5 * delta)
	global_position += _current_velocity * delta
	
	if _slide_timer <= 0.0:
		current_state = FielderState.THROW_TO_END
		_throw_timer = 0.2

func _process_throw(delta: float) -> void:
	_throw_timer -= delta
	if _throw_timer <= 0.0:
		# Decide target end: choose nearest wicket (Striker at Z = 10.06 or Non-striker at Z = -10.06)
		var dist_to_striker := global_position.distance_to(Vector3(0.0, 0.5, GameConstants.PITCH_LENGTH * 0.5))
		var dist_to_non_striker := global_position.distance_to(Vector3(0.0, 0.5, -GameConstants.PITCH_LENGTH * 0.5))
		var throw_to_striker: bool = dist_to_striker <= dist_to_non_striker
		
		_release_throw(throw_to_striker)
		current_state = FielderState.RETURN_TO_POSITION

func _release_throw(throw_to_striker: bool) -> void:
	var target_stump_pos := Vector3(0.0, 0.4, GameConstants.PITCH_LENGTH * 0.5 if throw_to_striker else -GameConstants.PITCH_LENGTH * 0.5)
	var throw_vector := target_stump_pos - global_position
	var flat_dist := Vector2(throw_vector.x, throw_vector.z).length()
	var flight_time := flat_dist / throw_speed_mps
	
	if flight_time < 0.1: flight_time = 0.1
	var v_y := (throw_vector.y + 0.5 * GameConstants.GRAVITY * flight_time * flight_time) / flight_time
	var v_horiz := Vector2(throw_vector.x, throw_vector.z).normalized() * throw_speed_mps
	
	if target_ball and is_instance_valid(target_ball):
		target_ball.freeze = false
		target_ball.global_position = global_position + Vector3(0.0, 1.4, 0.0)
		target_ball.linear_velocity = Vector3(v_horiz.x, v_y, v_horiz.y)
		
	has_ball = false
	ball_thrown.emit(throw_to_striker, throw_speed_mps)

func _process_return(delta: float) -> void:
	var dist_home := global_position.distance_to(home_position)
	if dist_home <= 0.4:
		global_position = home_position
		_current_velocity = Vector3.ZERO
		current_state = FielderState.IDLE
		return
		
	var dir := (home_position - global_position).normalized()
	_current_velocity = _current_velocity.move_toward(dir * (sprint_speed * 0.6), acceleration * delta)
	global_position += _current_velocity * delta
	look_at(global_position + _current_velocity, Vector3.UP)

func reset_to_home() -> void:
	global_position = home_position
	_current_velocity = Vector3.ZERO
	current_state = FielderState.IDLE
	has_ball = false
	if left_leg and right_leg:
		left_leg.rotation_degrees.x = 0.0
		right_leg.rotation_degrees.x = 0.0
