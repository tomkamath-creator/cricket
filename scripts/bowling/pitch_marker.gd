# PitchMarker.gd - CricStrike 3D
# Interactive 3D delivery pitch target marker with length indicator and difficulty fading
class_name PitchMarker
extends Node3D

signal marker_position_changed(new_pos: Vector3, length_zone: BowlerTypes.PitchLengthZone)

const GameConstants = preload("res://scripts/core/game_constants.gd")
const BowlerTypes = preload("res://scripts/bowling/bowler_types.gd")

@export var is_interactive: bool = true
@export var min_pitch_z: float = 2.0  # Bouncer / Short Pitch
@export var max_pitch_z: float = 9.2  # Yorker / Blockhole
@export var min_pitch_x: float = -0.9 # Wide Outside Off
@export var max_pitch_x: float = 0.9  # Down Leg Side

var target_position: Vector3 = Vector3(0.2, 0.02, 5.5) # Default Good Length on 4th stump
var current_length: BowlerTypes.PitchLengthZone = BowlerTypes.PitchLengthZone.GOOD_LENGTH

# Visuals
@onready var ring_mesh: MeshInstance3D = $RingMesh
@onready var center_mesh: MeshInstance3D = $CenterMesh
@onready var length_label: Label3D = $LengthLabel

var _is_dragging: bool = false
var _fade_tween: Tween
var _pulse_time: float = 0.0

func _ready() -> void:
	update_marker_position(target_position)

func _process(delta: float) -> void:
	_pulse_time += delta * 4.0
	if ring_mesh and visible:
		# Subtle pulsing scale for clean visual feedback
		var pulse_scale := 1.0 + sin(_pulse_time) * 0.08
		ring_mesh.scale = Vector3(pulse_scale, 1.0, pulse_scale)

func update_marker_position(pos: Vector3) -> void:
	target_position.x = clamp(pos.x, min_pitch_x, max_pitch_x)
	target_position.y = 0.02 # Rest slightly above turf
	target_position.z = clamp(pos.z, min_pitch_z, max_pitch_z)
	
	global_position = target_position
	current_length = BowlerTypes.categorize_length(target_position.z)
	
	if length_label:
		length_label.text = BowlerTypes.get_length_name(current_length)
		# Color code length zone
		match current_length:
			BowlerTypes.PitchLengthZone.YORKER:
				length_label.modulate = Color(1.0, 0.25, 0.25) # Red for yorker
			BowlerTypes.PitchLengthZone.FULL:
				length_label.modulate = Color(0.25, 0.9, 1.0)  # Cyan for full
			BowlerTypes.PitchLengthZone.GOOD_LENGTH:
				length_label.modulate = Color(0.3, 0.95, 0.3)  # Green for good length
			BowlerTypes.PitchLengthZone.SHORT:
				length_label.modulate = Color(1.0, 0.75, 0.2)  # Orange for short
				
	marker_position_changed.emit(target_position, current_length)

func start_fade(fade_delay_sec: float, fade_duration_sec: float = 0.35) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
		
	visible = true
	modulate_tree(1.0)
	
	if fade_delay_sec <= 0.05:
		_execute_fade(fade_duration_sec)
	elif fade_delay_sec < 99.0:
		_fade_tween = create_tween()
		_fade_tween.tween_interval(fade_delay_sec)
		_fade_tween.tween_callback(func(): _execute_fade(fade_duration_sec))

func _execute_fade(duration: float) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_method(modulate_tree, 1.0, 0.0, duration)
	_fade_tween.tween_callback(func(): visible = false)

func show_immediate() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	visible = true
	modulate_tree(1.0)

func hide_immediate() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	visible = false

func modulate_tree(alpha: float) -> void:
	if ring_mesh and ring_mesh.material_override is StandardMaterial3D:
		(ring_mesh.material_override as StandardMaterial3D).albedo_color.a = alpha
	if center_mesh and center_mesh.material_override is StandardMaterial3D:
		(center_mesh.material_override as StandardMaterial3D).albedo_color.a = alpha
	if length_label:
		length_label.modulate.a = alpha

# Dragging & placement via touch or mouse
func handle_touch_drag(ray_origin: Vector3, ray_dir: Vector3) -> bool:
	if not is_interactive:
		return false
		
	# Raycast against ground plane Y = 0
	if abs(ray_dir.y) < 0.001:
		return false
		
	var t := (0.02 - ray_origin.y) / ray_dir.y
	if t < 0.0:
		return false
		
	var hit_pos := ray_origin + ray_dir * t
	# Check if hit is anywhere on the pitch strip
	if hit_pos.z >= min_pitch_z - 1.0 and hit_pos.z <= max_pitch_z + 1.0:
		update_marker_position(hit_pos)
		return true
		
	return false
