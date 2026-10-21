# TestPlayerCustomization.gd - CricStrike 3D
# Headless unit test suite for PlayerProfile data model, serialization, bone scaling and custom loadout persistence
class_name TestPlayerCustomization
extends RefCounted

const PlayerProfile = preload("res://scripts/player/player_profile.gd")
const PlayerVisuals = preload("res://scripts/player/player_visuals.gd")

const TEST_SAVE_PATH: String = "user://test_custom_players.json"

func run_all_tests() -> bool:
	var passed: bool = true
	print("--- Running TestPlayerCustomization ---")
	
	# Test 1: Default Profile Initialization
	var p := PlayerProfile.new("V. KOHLI", 18)
	if not _assert_true(p.player_name == "V. KOHLI", "Default profile stores player name"):
		passed = false
	if not _assert_true(p.jersey_number == 18, "Default profile stores jersey number"):
		passed = false
	if not _assert_true(p.build_type == PlayerProfile.BuildType.ATHLETIC, "Default build is ATHLETIC"):
		passed = false
	if not _assert_true(p.get_build_scale() == Vector3.ONE, "Athletic build scale is (1, 1, 1)"):
		passed = false

	# Test 2: Build Bone Scaling Kinematics
	p.build_type = PlayerProfile.BuildType.SLIM
	if not _assert_true(p.get_build_scale().x < 1.0, "Slim build has reduced horizontal width"):
		passed = false
		
	p.build_type = PlayerProfile.BuildType.HEAVY
	if not _assert_true(p.get_build_scale().x > 1.0, "Heavy build has broadened torso/limb width"):
		passed = false

	# Test 3: Skin Tone and Bat Palettes
	p.skin_tone_index = 0
	if not _assert_true(p.get_skin_color() == PlayerProfile.SKIN_TONES[0], "Skin tone returns expected fair palette"):
		passed = false
		
	p.bat_willow = PlayerProfile.BatWillow.KASHMIR_WILLOW
	if not _assert_true(p.get_bat_color() == PlayerProfile.BAT_COLORS[1], "Kashmir willow returns darker wood grain"):
		passed = false

	# Test 4: Serialization to Dictionary & Back
	p.jersey_primary_color = Color(0.95, 0.82, 0.12, 1.0) # Yellow
	p.hair_style_index = 2
	p.beard_style_index = 2
	p.has_face_grill = false
	
	var serialized := p.to_dict()
	var restored := PlayerProfile.new()
	restored.from_dict(serialized)
	
	if not _assert_true(restored.player_name == "V. KOHLI", "Restored dictionary retains player name"):
		passed = false
	if not _assert_true(restored.jersey_number == 18, "Restored dictionary retains jersey number"):
		passed = false
	if not _assert_true(restored.hair_style_index == 2, "Restored dictionary retains hair style"):
		passed = false
	if not _assert_true(restored.has_face_grill == false, "Restored dictionary retains equipment config"):
		passed = false
	if not _assert_true(restored.jersey_primary_color.is_equal_approx(p.jersey_primary_color), "Restored dictionary retains hex color"):
		passed = false

	# Test 5: File Persistence (user:// save and load)
	var save_ok := p.save_to_file(TEST_SAVE_PATH)
	if not _assert_true(save_ok, "Player profile saves successfully to user:// directory"):
		passed = false
		
	var loaded_p := PlayerProfile.new()
	var load_ok := loaded_p.load_from_file(TEST_SAVE_PATH)
	if not _assert_true(load_ok, "Player profile loads successfully from user:// directory"):
		passed = false
	if not _assert_true(loaded_p.player_name == p.player_name and loaded_p.jersey_number == p.jersey_number, "Loaded profile matches saved profile data"):
		passed = false
		
	# Clean up test save file
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)

	# Test 6: Model Scene Instantiation & Material Binding
	var char_scene: PackedScene = load("res://scenes/character_model.tscn")
	if char_scene != null:
		var root := Node3D.new()
		var char_inst: PlayerVisuals = char_scene.instantiate() as PlayerVisuals
		root.add_child(char_inst)
		var rig_node = char_inst.get_node_or_null("Rig")
		if not _assert_true(rig_node != null, "CharacterModel rig instantiated correctly"):
			passed = false
		char_inst.free()
		root.free()
	else:
		printerr("  [FAIL] Could not load character_model.tscn")
		passed = false

	return passed

func _assert_true(condition: bool, description: String) -> bool:
	if condition:
		print("  [PASS] %s" % description)
		return true
	else:
		printerr("  [FAIL] %s: Assertion failed" % description)
		return false
