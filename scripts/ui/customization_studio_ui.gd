# CustomizationStudioUI.gd - CricStrike 3D
# User Interface for Player Locker Room & Modular Customizer
class_name CustomizationStudioUI
extends Control

signal player_saved()
signal back_pressed()

const PlayerProfile = preload("res://scripts/player/player_profile.gd")
const LockerRoomController = preload("res://scripts/customization/locker_room_controller.gd")

@export var locker_room_controller: LockerRoomController

# UI Node References
@onready var name_input: LineEdit = $Panel/VBox/PlayerInfo/NameInput
@onready var number_spin: SpinBox = $Panel/VBox/PlayerInfo/NumberSpin
@onready var skin_option: OptionButton = $Panel/VBox/Tabs/Body/SkinOption
@onready var build_option: OptionButton = $Panel/VBox/Tabs/Body/BuildOption
@onready var hair_option: OptionButton = $Panel/VBox/Tabs/Body/HairOption
@onready var beard_option: OptionButton = $Panel/VBox/Tabs/Body/BeardOption
@onready var kit_preset_option: OptionButton = $Panel/VBox/Tabs/Kit/KitPresetOption
@onready var willow_option: OptionButton = $Panel/VBox/Tabs/Gear/WillowOption
@onready var sticker_option: OptionButton = $Panel/VBox/Tabs/Gear/StickerOption
@onready var grill_check: CheckBox = $Panel/VBox/Tabs/Gear/GrillCheck
@onready var save_button: Button = $Panel/VBox/Actions/SaveBtn
@onready var back_button: Button = $Panel/VBox/Actions/BackBtn
@onready var status_label: Label = $Panel/VBox/StatusLabel

# Preset Team Kits
const KIT_PRESETS: Array[Dictionary] = [
	{
		"name": "India (Bleed Blue)",
		"jersey": Color(0.12, 0.35, 0.85, 1.0),
		"accent": Color(0.98, 0.55, 0.12, 1.0),
		"trousers": Color(0.12, 0.35, 0.85, 1.0),
		"pads": Color(0.15, 0.40, 0.90, 1.0),
		"helmet": Color(0.08, 0.20, 0.50, 1.0)
	},
	{
		"name": "Australia (Canary Yellow)",
		"jersey": Color(0.95, 0.82, 0.12, 1.0),
		"accent": Color(0.12, 0.42, 0.20, 1.0),
		"trousers": Color(0.12, 0.42, 0.20, 1.0),
		"pads": Color(0.95, 0.82, 0.12, 1.0),
		"helmet": Color(0.12, 0.42, 0.20, 1.0)
	},
	{
		"name": "England (Lions Red)",
		"jersey": Color(0.85, 0.15, 0.20, 1.0),
		"accent": Color(0.15, 0.25, 0.55, 1.0),
		"trousers": Color(0.15, 0.25, 0.55, 1.0),
		"pads": Color(0.85, 0.15, 0.20, 1.0),
		"helmet": Color(0.15, 0.25, 0.55, 1.0)
	},
	{
		"name": "Test Cricket (Classic White)",
		"jersey": Color(0.95, 0.95, 0.95, 1.0),
		"accent": Color(0.20, 0.20, 0.20, 1.0),
		"trousers": Color(0.95, 0.95, 0.95, 1.0),
		"pads": Color(0.95, 0.95, 0.95, 1.0),
		"helmet": Color(0.12, 0.15, 0.22, 1.0)
	}
]

func _ready() -> void:
	_populate_dropdowns()
	_connect_signals()
	_load_current_values()

func _populate_dropdowns() -> void:
	if skin_option:
		skin_option.clear()
		skin_option.add_item("Fair")
		skin_option.add_item("Medium / Tan")
		skin_option.add_item("Deep Brown")
		skin_option.add_item("Dark")
		
	if build_option:
		build_option.clear()
		build_option.add_item("Slim")
		build_option.add_item("Athletic")
		build_option.add_item("Heavy")
		
	if hair_option:
		hair_option.clear()
		hair_option.add_item("Buzzcut / None")
		hair_option.add_item("Short Fade")
		hair_option.add_item("Medium Spikes")
		
	if beard_option:
		beard_option.clear()
		beard_option.add_item("Clean Shaven")
		beard_option.add_item("Stubble")
		beard_option.add_item("Full Beard")
		
	if kit_preset_option:
		kit_preset_option.clear()
		for kit in KIT_PRESETS:
			kit_preset_option.add_item(kit["name"])
			
	if willow_option:
		willow_option.clear()
		willow_option.add_item("English Willow")
		willow_option.add_item("Kashmir Willow")
		
	if sticker_option:
		sticker_option.clear()
		for s_name in PlayerProfile.STICKER_NAMES:
			sticker_option.add_item(s_name)

func _connect_signals() -> void:
	if name_input:
		name_input.text_changed.connect(_on_name_changed)
	if number_spin:
		number_spin.value_changed.connect(_on_number_changed)
	if skin_option:
		skin_option.item_selected.connect(_on_skin_selected)
	if build_option:
		build_option.item_selected.connect(_on_build_selected)
	if hair_option:
		hair_option.item_selected.connect(_on_hair_selected)
	if beard_option:
		beard_option.item_selected.connect(_on_beard_selected)
	if kit_preset_option:
		kit_preset_option.item_selected.connect(_on_kit_preset_selected)
	if willow_option:
		willow_option.item_selected.connect(_on_willow_selected)
	if sticker_option:
		sticker_option.item_selected.connect(_on_sticker_selected)
	if grill_check:
		grill_check.toggled.connect(_on_grill_toggled)
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _load_current_values() -> void:
	if locker_room_controller == null or locker_room_controller.active_profile == null:
		return
	var p := locker_room_controller.active_profile
	if name_input: name_input.text = p.player_name
	if number_spin: number_spin.value = p.jersey_number
	if skin_option: skin_option.select(p.skin_tone_index)
	if build_option: build_option.select(int(p.build_type))
	if hair_option: hair_option.select(p.hair_style_index)
	if beard_option: beard_option.select(p.beard_style_index)
	if willow_option: willow_option.select(int(p.bat_willow))
	if sticker_option: sticker_option.select(p.bat_sticker_index)
	if grill_check: grill_check.button_pressed = p.has_face_grill

func _on_name_changed(new_text: String) -> void:
	if locker_room_controller:
		locker_room_controller.set_player_name(new_text)

func _on_number_changed(val: float) -> void:
	if locker_room_controller:
		locker_room_controller.set_jersey_number(int(val))

func _on_skin_selected(idx: int) -> void:
	if locker_room_controller:
		locker_room_controller.set_skin_tone(idx)

func _on_build_selected(idx: int) -> void:
	if locker_room_controller:
		locker_room_controller.set_build_type(idx as PlayerProfile.BuildType)

func _on_hair_selected(idx: int) -> void:
	if locker_room_controller:
		locker_room_controller.set_hair_style(idx)

func _on_beard_selected(idx: int) -> void:
	if locker_room_controller:
		locker_room_controller.set_beard_style(idx)

func _on_kit_preset_selected(idx: int) -> void:
	if idx >= 0 and idx < KIT_PRESETS.size() and locker_room_controller:
		var kit: Dictionary = KIT_PRESETS[idx]
		locker_room_controller.set_jersey_colors(kit["jersey"], kit["accent"])
		locker_room_controller.set_trousers_color(kit["trousers"])
		locker_room_controller.set_equipment_colors(kit["pads"], kit["helmet"], grill_check.button_pressed if grill_check else true)

func _on_willow_selected(idx: int) -> void:
	if locker_room_controller:
		locker_room_controller.set_bat_willow(idx as PlayerProfile.BatWillow)

func _on_sticker_selected(idx: int) -> void:
	if locker_room_controller:
		locker_room_controller.set_bat_sticker(idx)

func _on_grill_toggled(toggled_on: bool) -> void:
	if locker_room_controller:
		var p := locker_room_controller.active_profile
		locker_room_controller.set_equipment_colors(p.pads_color, p.helmet_color, toggled_on)

func _on_save_pressed() -> void:
	if locker_room_controller:
		var ok := locker_room_controller.save_customization()
		if status_label:
			status_label.text = "Saved to user://custom_players.json!" if ok else "Failed to save profile."
			status_label.modulate = Color.GREEN if ok else Color.RED
		player_saved.emit()

func _on_back_pressed() -> void:
	back_pressed.emit()
