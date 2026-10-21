# LockerRoomController.gd - CricStrike 3D
# Coordinates the 3D Locker Room & Customization Studio
# Handles 360-degree rotation inspection, UI tabs, and instant user:// persistence
class_name LockerRoomController
extends Node3D

signal customization_saved(profile: PlayerProfile)
signal exited_to_menu()

const PlayerProfile = preload("res://scripts/player/player_profile.gd")
const PlayerVisuals = preload("res://scripts/player/player_visuals.gd")

@onready var character_visuals: PlayerVisuals = $CharacterModel
@onready var camera_pivot: Node3D = $CameraPivot
@onready var inspection_camera: Camera3D = $CameraPivot/Camera3D

var active_profile: PlayerProfile
var _is_dragging: bool = false
var _drag_start_x: float = 0.0
var _current_orbit_angle: float = 0.0

func _ready() -> void:
	active_profile = PlayerProfile.new()
	if not active_profile.load_from_file():
		active_profile.save_to_file() # Save defaults on first run
		
	if character_visuals:
		character_visuals.apply_profile(active_profile)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_is_dragging = event.pressed
			_drag_start_x = event.position.x
	elif event is InputEventMouseMotion and _is_dragging:
		var delta_x: float = event.relative.x
		rotate_character(delta_x * 0.015)
	elif event is InputEventScreenDrag:
		rotate_character(event.relative.x * 0.015)

func rotate_character(angle_rad: float) -> void:
	if character_visuals:
		character_visuals.rotate_y(angle_rad)

# --- Customization API called by UI controls ---

func set_player_name(new_name: String) -> void:
	active_profile.player_name = new_name.strip_edges()
	_refresh_visuals()

func set_jersey_number(num: int) -> void:
	active_profile.jersey_number = clampi(num, 0, 99)
	_refresh_visuals()

func set_skin_tone(idx: int) -> void:
	active_profile.skin_tone_index = idx
	_refresh_visuals()

func set_build_type(build: PlayerProfile.BuildType) -> void:
	active_profile.build_type = build
	_refresh_visuals()

func set_hair_style(idx: int) -> void:
	active_profile.hair_style_index = idx
	_refresh_visuals()

func set_beard_style(idx: int) -> void:
	active_profile.beard_style_index = idx
	_refresh_visuals()

func set_jersey_colors(primary: Color, accent: Color) -> void:
	active_profile.jersey_primary_color = primary
	active_profile.jersey_accent_color = accent
	_refresh_visuals()

func set_trousers_color(col: Color) -> void:
	active_profile.trousers_color = col
	_refresh_visuals()

func set_bat_willow(willow: PlayerProfile.BatWillow) -> void:
	active_profile.bat_willow = willow
	_refresh_visuals()

func set_bat_sticker(idx: int) -> void:
	active_profile.bat_sticker_index = idx
	_refresh_visuals()

func set_equipment_colors(pads: Color, helmet: Color, has_grill: bool) -> void:
	active_profile.pads_color = pads
	active_profile.helmet_color = helmet
	active_profile.has_face_grill = has_grill
	_refresh_visuals()

func save_customization() -> bool:
	var success := active_profile.save_to_file()
	if success:
		customization_saved.emit(active_profile)
	return success

func _refresh_visuals() -> void:
	if character_visuals:
		character_visuals.apply_profile(active_profile)
