# test_stadium_and_crowd.gd - CricStrike 3D
# Verification of international stadium 3D components, spectator cheering loops, flags, and flashlights
class_name TestStadiumAndCrowd
extends RefCounted

const StadiumBuilder = preload("res://scripts/arena/stadium_builder.gd")
const CrowdAnimator = preload("res://scripts/arena/crowd_animator.gd")

func run_all_tests() -> bool:
	var passed: bool = true
	print("--- Running TestStadiumAndCrowd ---")
	
	# 1. Instantiate StadiumBuilder
	var stadium := StadiumBuilder.new()
	stadium.build_on_ready = false
	stadium.build_stadium()
	
	if not _assert_true(stadium.has_node("PitchSurface"), "StadiumBuilder created pristine PitchSurface"):
		passed = false
	if not _assert_true(stadium.has_node("CreaseMarkings"), "StadiumBuilder created CreaseMarkings"):
		passed = false
	if not _assert_true(stadium.has_node("OutfieldTurf"), "StadiumBuilder created OutfieldTurf"):
		passed = false
	if not _assert_true(stadium.has_node("BoundaryRope"), "StadiumBuilder created BoundaryRope"):
		passed = false
	if not _assert_true(stadium.has_node("GrandstandTiers"), "StadiumBuilder created GrandstandTiers"):
		passed = false
	if not _assert_true(stadium.has_node("CrowdRoot"), "StadiumBuilder created CrowdRoot"):
		passed = false
	if not _assert_true(stadium.has_node("FlagsRoot"), "StadiumBuilder created FlagsRoot with waving team flags"):
		passed = false
	if not _assert_true(stadium.has_node("FlashlightsRoot"), "StadiumBuilder created FlashlightsRoot with spectator flashlights"):
		passed = false
	if not _assert_true(stadium.has_node("ElectronicJumboScoreboards"), "StadiumBuilder created dual ElectronicJumboScoreboards"):
		passed = false
	if not _assert_true(stadium.has_node("TeamDugouts"), "StadiumBuilder created TeamDugouts"):
		passed = false
	if not _assert_true(stadium.has_node("Floodlights"), "StadiumBuilder created giant LED Floodlights"):
		passed = false

	# 2. Verify Crowd Counts
	var crowd_root: Node3D = stadium.get_node_or_null("CrowdRoot") as Node3D
	if not _assert_true(crowd_root != null and crowd_root.get_child_count() >= 64, "Grandstands populated with >= 64 spectator nodes"):
		passed = false
		
	var flags_root: Node3D = stadium.get_node_or_null("FlagsRoot") as Node3D
	if not _assert_true(flags_root != null and flags_root.get_child_count() >= 12, "Perimeter populated with >= 12 waving team flags"):
		passed = false

	var flash_root: Node3D = stadium.get_node_or_null("FlashlightsRoot") as Node3D
	if not _assert_true(flash_root != null and flash_root.get_child_count() >= 32, "Grandstands populated with >= 32 twinkling spectator flashlights"):
		passed = false

	# 3. CrowdAnimator Verification
	var animator: CrowdAnimator = stadium.get_node_or_null("CrowdAnimator") as CrowdAnimator
	if not _assert_true(animator != null, "Stadium has active CrowdAnimator"):
		passed = false
	if animator:
		animator.trigger_cheer_surge(3.0, 2.0)
		if not _assert_true(animator.target_excitement == 3.0, "Cheer surge updates target excitement to 3.0"):
			passed = false
		# Simulate a delta frame of animation
		animator._process(0.016)
		if not _assert_true(animator.excitement_level > 1.0, "Excitement level increases during cheer surge"):
			passed = false

	stadium.free()
	return passed

func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		print("  [PASS] %s" % message)
		return true
	else:
		printerr("  [FAIL] %s" % message)
		return false
