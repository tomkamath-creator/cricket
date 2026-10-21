# TestStumpCollision.gd - CricStrike 3D
# Headless unit test suite for wickets, stumps and bails physical dislodging
class_name TestStumpCollision

static func run_all_tests() -> bool:
	var passed: bool = true
	print("--- Running TestStumpCollision ---")
	
	var stumps_scene := load("res://scenes/stumps_set.tscn") as PackedScene
	if stumps_scene == null:
		printerr("  [FAIL] Could not load stumps_set.tscn")
		return false
		
	var stumps_instance := stumps_scene.instantiate() as StumpsSet
	if stumps_instance == null:
		printerr("  [FAIL] Could not instantiate StumpsSet")
		return false

	# Add to tree temporarily for _ready execution
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		tree.root.add_child(stumps_instance)
		
	# Test 1: Verify 3 Stumps and 2 Bails found
	if not _assert_true(stumps_instance.stumps.size() == 3, "StumpsSet found exactly 3 stumps"):
		passed = false
	if not _assert_true(stumps_instance.bails.size() == 2, "StumpsSet found exactly 2 bails"):
		passed = false

	# Test 2: Verify Initial Unbroken State
	if not _assert_true(not stumps_instance.is_broken(), "Stumps are initially unbroken"):
		passed = false

	# Test 3: Trigger Shatter
	var middle_stump := stumps_instance.stumps[1]
	stumps_instance.shatter_wickets(middle_stump, 25.0, Vector3(0.0, 0.2, 1.0))
	if not _assert_true(stumps_instance.is_broken(), "Stumps are broken after shatter_wickets call"):
		passed = false

	# Test 4: Reset Stumps
	stumps_instance.reset_wickets()
	if not _assert_true(not stumps_instance.is_broken(), "Stumps are restored after reset_wickets call"):
		passed = false

	# Cleanup
	if stumps_instance.get_parent():
		stumps_instance.get_parent().remove_child(stumps_instance)
	stumps_instance.queue_free()

	return passed

static func _assert_true(condition: bool, description: String) -> bool:
	if condition:
		print("  [PASS] %s" % description)
		return true
	else:
		printerr("  [FAIL] %s: Assertion failed" % description)
		return false
