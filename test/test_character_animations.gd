# TestCharacterAnimations.gd - CricStrike 3D
# Verification of authentic 3D humanoid character models and motion-captured skeletal animations
class_name TestCharacterAnimations
extends RefCounted

func run_all_tests() -> bool:
	var passed: bool = true
	print("--- Running TestCharacterAnimations ---")
	
	# 1. Load Ty Character Model
	var char_scene: PackedScene = load("res://assets/models/Ty.glb")
	if not _assert_true(char_scene != null, "Ty.glb humanoid character loaded"):
		passed = false
	
	var char_inst: Node3D = char_scene.instantiate()
	var skels := char_inst.find_children("", "Skeleton3D", true, false)
	var skel: Skeleton3D = skels[0] if skels.size() > 0 else null
	if not _assert_true(skel != null and skel.get_bone_count() >= 65, "Skeleton3D has >= 65 bone Mixamo standard rig"):
		passed = false
	
	# 2. Verify Key Bones
	if skel:
		var hand_idx := skel.find_bone("mixamorig_RightHand")
		var head_idx := skel.find_bone("mixamorig_Head")
		var spine_idx := skel.find_bone("mixamorig_Spine")
		if not _assert_true(hand_idx >= 0 and head_idx >= 0 and spine_idx >= 0, "Essential bones present: RightHand, Head, Spine"):
			passed = false
	
	# 3. Load Cricket Animations Library
	var lib: AnimationLibrary = load("res://assets/animations/cricket_animations.tres")
	if not _assert_true(lib != null, "cricket_animations.tres loaded successfully"):
		passed = false
		
	if lib:
		var required_anims := ["stance", "swing", "pull", "bowl", "sprint", "runup", "keeper", "umpire_out"]
		var all_anims_ok := true
		for a_name in required_anims:
			if not lib.has_animation(a_name):
				all_anims_ok = false
				break
			var anim: Animation = lib.get_animation(a_name)
			if anim.length <= 0.2 or anim.get_track_count() < 40:
				all_anims_ok = false
				break
		if not _assert_true(all_anims_ok, "All 8 required cricket animations present with active bone tracks"):
			passed = false
	
		# 4. Verify Looping Modes
		var loops_ok: bool = (
			lib.get_animation("stance").loop_mode == Animation.LOOP_LINEAR and
			lib.get_animation("sprint").loop_mode == Animation.LOOP_LINEAR and
			lib.get_animation("runup").loop_mode == Animation.LOOP_LINEAR and
			lib.get_animation("keeper").loop_mode == Animation.LOOP_LINEAR
		)
		if not _assert_true(loops_ok, "Continuous looping configured for stance, sprint, run-up, and wicketkeeper"):
			passed = false
	
	# 5. Batsman Scene Verification
	var batsman_scene: PackedScene = load("res://scenes/batsman.tscn")
	var batsman: Node = batsman_scene.instantiate() if batsman_scene else null
	if not _assert_true(batsman != null and batsman.has_node("HumanoidModel") and batsman.has_node("BatPivot"), "Batsman scene instantiated with 3D Humanoid and Bat"):
		passed = false
	
	# 6. Bowler Scene Verification
	var bowler_scene: PackedScene = load("res://scenes/bowler.tscn")
	var bowler: Node = bowler_scene.instantiate() if bowler_scene else null
	if not _assert_true(bowler != null and bowler.has_node("HumanoidModel"), "Bowler scene instantiated with 3D Humanoid"):
		passed = false
	
	# 7. Fielder Scene Verification
	var fielder_scene: PackedScene = load("res://scenes/fielder.tscn")
	var fielder: Node = fielder_scene.instantiate() if fielder_scene else null
	if not _assert_true(fielder != null and fielder.has_node("MeshRoot/HumanoidModel"), "Fielder scene instantiated with 3D Humanoid"):
		passed = false
	
	# 8. Umpire Scene Verification
	var umpire_scene: PackedScene = load("res://scenes/umpire.tscn")
	var umpire: Node = umpire_scene.instantiate() if umpire_scene else null
	if not _assert_true(umpire != null and umpire.has_node("HumanoidModel"), "Umpire scene instantiated with 3D Humanoid"):
		passed = false
	
	if char_inst: char_inst.free()
	if batsman: batsman.free()
	if bowler: bowler.free()
	if fielder: fielder.free()
	if umpire: umpire.free()
	
	return passed

func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		print("  [PASS] %s" % message)
		return true
	else:
		printerr("  [FAIL] %s" % message)
		return false
