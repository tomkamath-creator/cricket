# FieldingManager.gd - CricStrike 3D
# Coordinates all 11 fielders, field presets, pursuit assignment and catch evaluation
class_name FieldingManager
extends Node3D

signal ball_caught(fielder_name: String)
signal ball_stopped_by_field(fielder_name: String)
signal throw_received(is_striker_end: bool)

const GameConstants = preload("res://scripts/core/game_constants.gd")
const CricketBall = preload("res://scripts/physics/cricket_ball.gd")
const FielderController = preload("res://scripts/fielding/fielder_controller.gd")

enum FieldPreset {
	BALANCED,
	ATTACKING,
	DEFENSIVE
}

@export var ball_ref: CricketBall
@export var current_preset: FieldPreset = FieldPreset.BALANCED

var fielders: Array[FielderController] = []

# Position databases (Radius, Angle in degrees around striker stumps Z = 10.06)
var _field_positions_balanced: Dictionary = {
	"WicketKeeper": Vector3(0.0, 0.0, 14.5),
	"FirstSlip":    Vector3(-2.8, 0.0, 14.0),
	"Point":        Vector3(-18.0, 0.0, 9.5),
	"Cover":        Vector3(-19.0, 0.0, 2.5),
	"MidOff":       Vector3(-10.0, 0.0, -4.5),
	"MidOn":        Vector3(10.0, 0.0, -4.5),
	"MidWicket":    Vector3(18.0, 0.0, 2.5),
	"SquareLeg":    Vector3(19.0, 0.0, 10.5),
	"FineLeg":      Vector3(26.0, 0.0, 32.0),
	"ThirdMan":     Vector3(-28.0, 0.0, 30.0),
	"DeepCover":    Vector3(-46.0, 0.0, -10.0)
}

var _field_positions_attacking: Dictionary = {
	"WicketKeeper": Vector3(0.0, 0.0, 13.8),
	"FirstSlip":    Vector3(-2.2, 0.0, 13.2),
	"SecondSlip":   Vector3(-4.2, 0.0, 13.0),
	"Gully":        Vector3(-9.5, 0.0, 11.0),
	"Point":        Vector3(-16.0, 0.0, 9.0),
	"Cover":        Vector3(-17.0, 0.0, 3.0),
	"MidOff":       Vector3(-8.0, 0.0, -3.5),
	"MidOn":        Vector3(8.0, 0.0, -3.5),
	"ShortMidWkt":  Vector3(12.0, 0.0, 4.0),
	"SquareLeg":    Vector3(17.0, 0.0, 10.5),
	"FineLeg":      Vector3(22.0, 0.0, 28.0)
}

var _field_positions_defensive: Dictionary = {
	"WicketKeeper": Vector3(0.0, 0.0, 15.0),
	"Point":        Vector3(-18.0, 0.0, 9.5),
	"DeepPoint":    Vector3(-48.0, 0.0, 12.0),
	"DeepCover":    Vector3(-52.0, 0.0, -12.0),
	"LongOff":      Vector3(-24.0, 0.0, -48.0),
	"LongOn":       Vector3(24.0, 0.0, -48.0),
	"DeepMidWkt":   Vector3(50.0, 0.0, -8.0),
	"DeepSquare":   Vector3(52.0, 0.0, 15.0),
	"FineLeg":      Vector3(32.0, 0.0, 38.0),
	"ThirdMan":     Vector3(-34.0, 0.0, 36.0),
	"MidOff":       Vector3(-12.0, 0.0, -2.0)
}

func _ready() -> void:
	_gather_fielders()
	apply_field_preset(current_preset)

func _gather_fielders() -> void:
	fielders.clear()
	for child in get_children():
		if child is FielderController:
			fielders.append(child)
			child.ball_fielded.connect(_on_fielder_fielded)
			child.ball_thrown.connect(_on_fielder_thrown)

func apply_field_preset(preset: FieldPreset) -> void:
	current_preset = preset
	var layout: Dictionary
	match preset:
		FieldPreset.BALANCED: layout = _field_positions_balanced
		FieldPreset.ATTACKING: layout = _field_positions_attacking
		FieldPreset.DEFENSIVE: layout = _field_positions_defensive
		
	var names: Array = layout.keys()
	for i in range(min(fielders.size(), names.size())):
		var f_name: String = names[i]
		var f_pos: Vector3 = layout[f_name]
		fielders[i].fielder_name = f_name
		fielders[i].assign_home_position(f_pos)

func on_ball_hit(ball: CricketBall, exit_velocity: Vector3) -> void:
	if fielders.is_empty():
		return
		
	# Find primary fielder whose position is closest to projected trajectory
	var best_fielder: FielderController = fielders[0]
	var min_dist: float = 9999.0
	
	# Projected ground contact heading
	var ball_heading := Vector2(exit_velocity.x, exit_velocity.z).normalized()
	
	for f in fielders:
		var to_fielder := Vector2(f.home_position.x, f.home_position.z)
		var proj_dist := to_fielder.distance_to(ball_heading * to_fielder.length())
		
		# Weight by distance from striker
		var score := proj_dist * 0.7 + f.home_position.distance_to(ball.global_position) * 0.3
		if score < min_dist:
			min_dist = score
			best_fielder = f
			
	# Assign primary chaser and alerting backups
	for f in fielders:
		f.react_to_shot(ball, f == best_fielder)

func _on_fielder_fielded(f_name: String, was_catch: bool) -> void:
	if was_catch:
		ball_caught.emit(f_name)
	else:
		ball_stopped_by_field.emit(f_name)

func _on_fielder_thrown(to_striker: bool, _speed: float) -> void:
	throw_received.emit(to_striker)

func reset_all_fielders() -> void:
	for f in fielders:
		f.reset_to_home()
