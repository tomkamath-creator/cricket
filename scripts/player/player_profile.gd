# PlayerProfile.gd - CricStrike 3D
# Data model for customizable player appearance, gear, and metadata
class_name PlayerProfile
extends Resource

const SAVE_PATH: String = "user://custom_players.json"

enum BuildType {
	SLIM,
	ATHLETIC,
	HEAVY
}

enum BatWillow {
	ENGLISH_WILLOW,
	KASHMIR_WILLOW
}

# Player Metadata
var player_name: String = "R. SHARMA"
var jersey_number: int = 45
var is_right_handed: bool = true

# Body & Skin
var skin_tone_index: int = 1 # 0: Fair, 1: Medium/Tan, 2: Deep Brown, 3: Dark
var build_type: BuildType = BuildType.ATHLETIC
var hair_style_index: int = 1 # 0: Buzzcut, 1: Medium fade, 2: Long spikes
var beard_style_index: int = 1 # 0: Clean, 1: Stubble, 2: Full beard

# Team Kit Colors
var jersey_primary_color: Color = Color(0.12, 0.35, 0.85, 1.0) # India Blue
var jersey_accent_color: Color = Color(0.98, 0.55, 0.12, 1.0) # Saffron Orange
var trousers_color: Color = Color(0.12, 0.35, 0.85, 1.0)

# Equipment
var bat_willow: BatWillow = BatWillow.ENGLISH_WILLOW
var bat_sticker_index: int = 0 # 0: Strike, 1: Thunder, 2: Classic Gold
var pads_color: Color = Color(0.95, 0.95, 0.95, 1.0) # Traditional white pads
var gloves_color: Color = Color(0.12, 0.35, 0.85, 1.0)
var helmet_color: Color = Color(0.08, 0.20, 0.50, 1.0)
var has_face_grill: bool = true

# Preset palettes
const SKIN_TONES: Array[Color] = [
	Color(0.92, 0.78, 0.68, 1.0), # Fair
	Color(0.78, 0.58, 0.45, 1.0), # Medium Tan
	Color(0.55, 0.38, 0.28, 1.0), # Deep Brown
	Color(0.32, 0.20, 0.14, 1.0)  # Dark
]

const BAT_COLORS: Array[Color] = [
	Color(0.90, 0.82, 0.62, 1.0), # English Willow (pale golden)
	Color(0.78, 0.64, 0.45, 1.0)  # Kashmir Willow (darker grain)
]

const STICKER_NAMES: Array[String] = [
	"Strike Blast",
	"Thunder Bolt",
	"Classic Gold"
]

func _init(p_name: String = "R. SHARMA", p_number: int = 45) -> void:
	player_name = p_name
	jersey_number = p_number

func get_skin_color() -> Color:
	var idx := clampi(skin_tone_index, 0, SKIN_TONES.size() - 1)
	return SKIN_TONES[idx]

func get_bat_color() -> Color:
	var idx := clampi(int(bat_willow), 0, BAT_COLORS.size() - 1)
	return BAT_COLORS[idx]

func get_build_scale() -> Vector3:
	match build_type:
		BuildType.SLIM:
			return Vector3(0.90, 1.02, 0.90)
		BuildType.ATHLETIC:
			return Vector3(1.00, 1.00, 1.00)
		BuildType.HEAVY:
			return Vector3(1.15, 0.98, 1.15)
		_:
			return Vector3.ONE

func to_dict() -> Dictionary:
	return {
		"player_name": player_name,
		"jersey_number": jersey_number,
		"is_right_handed": is_right_handed,
		"skin_tone_index": skin_tone_index,
		"build_type": int(build_type),
		"hair_style_index": hair_style_index,
		"beard_style_index": beard_style_index,
		"jersey_primary_color": [jersey_primary_color.r, jersey_primary_color.g, jersey_primary_color.b, jersey_primary_color.a],
		"jersey_accent_color": [jersey_accent_color.r, jersey_accent_color.g, jersey_accent_color.b, jersey_accent_color.a],
		"trousers_color": [trousers_color.r, trousers_color.g, trousers_color.b, trousers_color.a],
		"bat_willow": int(bat_willow),
		"bat_sticker_index": bat_sticker_index,
		"pads_color": [pads_color.r, pads_color.g, pads_color.b, pads_color.a],
		"gloves_color": [gloves_color.r, gloves_color.g, gloves_color.b, gloves_color.a],
		"helmet_color": [helmet_color.r, helmet_color.g, helmet_color.b, helmet_color.a],
		"has_face_grill": has_face_grill
	}

static func _array_or_string_to_color(val: Variant, default_color: Color) -> Color:
	if val is Array and (val as Array).size() >= 3:
		var arr: Array = val as Array
		var r: float = float(arr[0])
		var g: float = float(arr[1])
		var b: float = float(arr[2])
		var a: float = float(arr[3]) if arr.size() >= 4 else 1.0
		return Color(r, g, b, a)
	elif val is String:
		return Color.from_string(val, default_color)
	return default_color

func from_dict(dict: Dictionary) -> void:
	player_name = dict.get("player_name", player_name)
	jersey_number = int(dict.get("jersey_number", jersey_number))
	is_right_handed = bool(dict.get("is_right_handed", is_right_handed))
	skin_tone_index = int(dict.get("skin_tone_index", skin_tone_index))
	build_type = int(dict.get("build_type", int(build_type))) as BuildType
	hair_style_index = int(dict.get("hair_style_index", hair_style_index))
	beard_style_index = int(dict.get("beard_style_index", beard_style_index))
	
	if dict.has("jersey_primary_color"):
		jersey_primary_color = _array_or_string_to_color(dict["jersey_primary_color"], jersey_primary_color)
	if dict.has("jersey_accent_color"):
		jersey_accent_color = _array_or_string_to_color(dict["jersey_accent_color"], jersey_accent_color)
	if dict.has("trousers_color"):
		trousers_color = _array_or_string_to_color(dict["trousers_color"], trousers_color)
	if dict.has("bat_willow"):
		bat_willow = int(dict["bat_willow"]) as BatWillow
	if dict.has("bat_sticker_index"):
		bat_sticker_index = int(dict["bat_sticker_index"])
	if dict.has("pads_color"):
		pads_color = _array_or_string_to_color(dict["pads_color"], pads_color)
	if dict.has("gloves_color"):
		gloves_color = _array_or_string_to_color(dict["gloves_color"], gloves_color)
	if dict.has("helmet_color"):
		helmet_color = _array_or_string_to_color(dict["helmet_color"], helmet_color)
	if dict.has("has_face_grill"):
		has_face_grill = bool(dict["has_face_grill"])

func save_to_file(path: String = SAVE_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("PlayerProfile: Failed to open %s for write: %s" % [path, FileAccess.get_open_error()])
		return false
	var json_str := JSON.stringify(to_dict(), "\t")
	file.store_string(json_str)
	file.close()
	return true

func load_from_file(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var content := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(content)
	if parsed is Dictionary:
		from_dict(parsed)
		return true
	return false
