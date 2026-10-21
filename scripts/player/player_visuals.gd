# PlayerVisuals.gd - CricStrike 3D
# Dynamic procedural/shader-driven 3D player mesh customizer
# Manages skin tones, hair/beard, team jerseys, equipment, and build bone scaling
class_name PlayerVisuals
extends Node3D

const PlayerProfile = preload("res://scripts/player/player_profile.gd")

@export var profile: PlayerProfile

# Node references within the model hierarchy
@onready var root_rig: Node3D = $Rig
@onready var torso_mesh: MeshInstance3D = $Rig/Torso
@onready var head_mesh: MeshInstance3D = $Rig/Head
@onready var left_leg: MeshInstance3D = $Rig/LeftLeg
@onready var right_leg: MeshInstance3D = $Rig/RightLeg
@onready var left_pad: MeshInstance3D = $Rig/LeftPad
@onready var right_pad: MeshInstance3D = $Rig/RightPad
@onready var hair_mesh: MeshInstance3D = $Rig/Head/Hair
@onready var beard_mesh: MeshInstance3D = $Rig/Head/Beard
@onready var helmet_mesh: MeshInstance3D = $Rig/Head/Helmet
@onready var grill_mesh: MeshInstance3D = $Rig/Head/Helmet/Grill
@onready var bat_blade: MeshInstance3D = $Rig/BatPivot/Bat/Blade
@onready var bat_sticker: MeshInstance3D = $Rig/BatPivot/Bat/Sticker
@onready var jersey_text_label: Label3D = $Rig/Torso/JerseyBackLabel

func _ready() -> void:
	if profile == null:
		profile = PlayerProfile.new()
		# Try loading existing user profile if available
		profile.load_from_file()
	apply_profile(profile)

func apply_profile(p_profile: PlayerProfile) -> void:
	profile = p_profile
	if not is_inside_tree() or root_rig == null:
		return
		
	# 1. Apply Build Bone/Node Scaling
	root_rig.scale = profile.get_build_scale()
	
	# 2. Skin Material
	var skin_color: Color = profile.get_skin_color()
	if head_mesh:
		_set_mesh_color(head_mesh, skin_color, 0.7)
		
	# 3. Jersey & Number
	if torso_mesh:
		_set_mesh_color(torso_mesh, profile.jersey_primary_color, 0.6)
		
	if jersey_text_label:
		jersey_text_label.text = "%s\n%d" % [profile.player_name.to_upper(), profile.jersey_number]
		jersey_text_label.modulate = profile.jersey_accent_color
		
	# 4. Trousers (Legs)
	if left_leg:
		_set_mesh_color(left_leg, profile.trousers_color, 0.7)
	if right_leg:
		_set_mesh_color(right_leg, profile.trousers_color, 0.7)
		
	# 5. Batting Pads
	if left_pad:
		_set_mesh_color(left_pad, profile.pads_color, 0.5)
	if right_pad:
		_set_mesh_color(right_pad, profile.pads_color, 0.5)
		
	# 6. Hair & Beard Visibility / Shapes
	_apply_hair_and_beard()
	
	# 7. Helmet & Grill
	if helmet_mesh:
		_set_mesh_color(helmet_mesh, profile.helmet_color, 0.4)
	if grill_mesh:
		grill_mesh.visible = profile.has_face_grill
		
	# 8. Bat & Stickers
	if bat_blade:
		_set_mesh_color(bat_blade, profile.get_bat_color(), 0.45)
		
	if bat_sticker:
		_apply_bat_sticker()

func _set_mesh_color(mesh_inst: MeshInstance3D, col: Color, roughness: float = 0.5) -> void:
	if mesh_inst == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = roughness
	mesh_inst.material_override = mat

func _apply_hair_and_beard() -> void:
	if hair_mesh:
		hair_mesh.visible = (profile.hair_style_index > 0)
		if hair_mesh.visible:
			match profile.hair_style_index:
				1: hair_mesh.scale = Vector3(1.02, 1.02, 1.02) # Short fade
				2: hair_mesh.scale = Vector3(1.06, 1.15, 1.06) # Medium / spikes
				_: hair_mesh.scale = Vector3.ONE
	
	if beard_mesh:
		beard_mesh.visible = (profile.beard_style_index > 0)
		if beard_mesh.visible:
			match profile.beard_style_index:
				1: beard_mesh.scale = Vector3(1.01, 0.85, 1.02) # Stubble
				2: beard_mesh.scale = Vector3(1.05, 1.10, 1.05) # Full beard
				_: beard_mesh.scale = Vector3.ONE

func _apply_bat_sticker() -> void:
	if bat_sticker == null:
		return
	var sticker_mat := StandardMaterial3D.new()
	match profile.bat_sticker_index:
		0: # Strike Blast (Red & Gold)
			sticker_mat.albedo_color = Color(0.85, 0.20, 0.15, 1.0)
		1: # Thunder Bolt (Cyan & Blue)
			sticker_mat.albedo_color = Color(0.15, 0.75, 0.95, 1.0)
		2: # Classic Gold
			sticker_mat.albedo_color = Color(0.95, 0.82, 0.25, 1.0)
			sticker_mat.metallic = 0.6
		_:
			sticker_mat.albedo_color = Color.WHITE
	bat_sticker.material_override = sticker_mat
