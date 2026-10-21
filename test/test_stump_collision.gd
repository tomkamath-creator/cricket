# TestStumpCollision.gd - CricStrike 3D
# Headless unit test suite for wickets, stumps and bails physical dislodging
class_name TestStumpCollision
extends RefCounted

const StumpsSet = preload("res://scripts/physics/stumps_set.gd")

func run_all_tests() -> bool:
	var passed: bool = true
	print("--- Running TestStumpCollision ---")
	
	var stumps_scene: PackedScene = load("res://scenes/stumps_set.tscn")
	if stumps_scene == null:
		printerr("  [FAIL] Could not load stumps_set.tscn")
		return false
		
	var stumps_instance: StumpsSet = stumps_scene.instantiate() as StumpsSet
	if stumps_instance == null:
		printerr("  [FAIL] Could not instantiate StumpsSet")
		return false

	# Explicitly call _ready to initialize children array without needing active scene window
	stumps_instance._ready()

	# Test 1: Verify 3 Stumps and 2 Bails found
	if not _assert_true(stumps_instance.stumps.size() == 3, "StumpsSet found exactly 3 stumps"):
		passed = false
	if not _assert_true(stumps_instance.bails.size() == 2, "StumpsSet found exactly 2 bails"):
		passed = false

	# Test 2: Verify Initial Unbroken State
	if not _assert_true(not stumps_instance.is_broken(), "Stumps are initially unbroken"):
		passed = false

	# Test 3: Trigger Shatter
	if stumps_instance.stumps.size() >= 2:
		var middle_stump: RigidBody3D = stumps_instance.stumps[1]
		stumps_instance.shatter_wickets(middle_stump, 25.0, Vector3(0.0, 0.2, 1.0))
		if not _assert_true(stumps_instance.is_broken(), "Stumps are broken after shatter_wickets call"):
			passed = false

		# Test 4: Reset Stumps
		stumps_instance.reset_wickets()
		if not _assert_true(not stumps_instance.is_broken(), "Stumps are restored after reset_wickets call"):
			passed = false

	# Cleanup
	stumps_instance.free()

	return passed

func _assert_true(condition: bool, description: String) -> bool:
	if condition:
		print("  [PASS] %s" % description)
		return true
	else:
		printerr("  [FAIL] %s: Assertion failed" % description)
		return false
