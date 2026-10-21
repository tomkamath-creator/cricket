# VirtualJoystick.gd - CricStrike 3D
# 8-Directional Mobile Touch & Mouse Virtual Joystick
class_name VirtualJoystick
extends Control

signal joystick_vector_changed(vector: Vector2)
signal shot_sector_changed(direction: GameConstants.ShotDirection)

@export var max_radius: float = 65.0
@export var deadzone: float = 0.18

var current_vector: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var touch_finger_id: int = -1

var _center_pos: Vector2
var _current_sector: GameConstants.ShotDirection = GameConstants.ShotDirection.STRAIGHT

func _ready() -> void:
	custom_minimum_size = Vector2(max_radius * 2.4, max_radius * 2.4)
	_center_pos = size * 0.5
	resized.connect(func(): _center_pos = size * 0.5)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_finger_id == -1:
			touch_finger_id = event.index
			is_dragging = true
			_update_joystick(event.position)
		elif not event.pressed and event.index == touch_finger_id:
			_reset_joystick()
			
	elif event is InputEventScreenDrag and event.index == touch_finger_id:
		_update_joystick(event.position)
		
	# Mouse fallback for editor / desktop
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				_update_joystick(event.position)
			else:
				_reset_joystick()
				
	elif event is InputEventMouseMotion and is_dragging:
		_update_joystick(event.position)

func _update_joystick(pos: Vector2) -> void:
	var delta := pos - _center_pos
	var dist := delta.length()
	
	if dist < deadzone * max_radius:
		current_vector = Vector2.ZERO
	else:
		var clamped_dist := minf(dist, max_radius)
		current_vector = delta.normalized() * (clamped_dist / max_radius)
		
	var new_sector := ShotLibrary.vector_to_direction(current_vector)
	if new_sector != _current_sector:
		_current_sector = new_sector
		shot_sector_changed.emit(_current_sector)
		
	joystick_vector_changed.emit(current_vector)
	queue_redraw()

func _reset_joystick() -> void:
	is_dragging = false
	touch_finger_id = -1
	current_vector = Vector2.ZERO
	_current_sector = GameConstants.ShotDirection.STRAIGHT
	joystick_vector_changed.emit(current_vector)
	shot_sector_changed.emit(_current_sector)
	queue_redraw()

func _draw() -> void:
	_center_pos = size * 0.5
	
	# Outer boundary circle
	draw_circle(_center_pos, max_radius, Color(0.12, 0.16, 0.24, 0.55))
	draw_arc(_center_pos, max_radius, 0, TAU, 32, Color(0.35, 0.65, 0.95, 0.8), 2.5)
	
	# Draw 8 directional guide notches
	for i in range(8):
		var angle := i * (TAU / 8.0) - PI * 0.5
		var notch_start := _center_pos + Vector2(cos(angle), sin(angle)) * (max_radius - 8.0)
		var notch_end := _center_pos + Vector2(cos(angle), sin(angle)) * max_radius
		draw_line(notch_start, notch_end, Color(0.5, 0.8, 1.0, 0.6), 2.0)
		
	# Inner knob
	var knob_pos := _center_pos + (current_vector * max_radius)
	var knob_color := Color(0.2, 0.75, 1.0, 0.9) if is_dragging else Color(0.8, 0.85, 0.95, 0.65)
	draw_circle(knob_pos, 22.0, knob_color)
	draw_arc(knob_pos, 22.0, 0, TAU, 24, Color.WHITE, 2.0)
