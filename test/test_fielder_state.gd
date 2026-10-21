# TestFielderState.gd - CricStrike 3D
# Headless unit test suite for Fielder AI State Machine and Interception Kinematics
class_name TestFielderState
extends RefCounted

const GameConstants = preload("res://scripts/core/game_constants.gd")
const FielderController = preload("res://scripts/fielding/fielder_controller.gd")
const CricketBall = preload("res://scripts/physics/cricket_ball.gd")

func run_all_tests() -> bool:
	var passed: bool = true
	print("--- Running TestFielderState ---")
	
	# Instantiate within a dummy root node in tree so global_transform/look_at works cleanly
	var root := Node3D.new()
	var fielder_scene: PackedScene = load("res://scenes/fielder.tscn")
	if fielder_scene == null:
		printerr("  [FAIL] Could not load fielder.tscn")
		return false
		
	var fielder: FielderController = fielder_scene.instantiate() as FielderController
	if fielder == null:
		printerr("  [FAIL] Could not instantiate FielderController")
		return false
	
	root.add_child(fielder)
	fielder.assign_home_position(Vector3(15.0, 0.0, 10.0))
	
	# Test 1: Initial Idle State
	if not _assert_true(fielder.current_state == FielderController.FielderState.IDLE, "Fielder initializes in IDLE state"):
		passed = false

	# Test 2: React to Shot as Primary Chaser
	var ball := CricketBall.new()
	ball.position = Vector3(18.0, 0.5, 12.0)
	ball.has_pitched = true
	fielder.react_to_shot(ball, true)
	
	if not _assert_true(fielder.current_state == FielderController.FielderState.CHASE_BALL, "Primary chaser transitions to CHASE_BALL state"):
		passed = false

	# Test 3: Ground Pickup Trigger
	fielder.position = Vector3(18.2, 0.0, 12.0) # Within 0.85m pickup radius
	fielder._process_chase(0.016)
	if not _assert_true(fielder.current_state == FielderController.FielderState.SLIDE_OR_PICKUP, "Reaching ball transitions to SLIDE_OR_PICKUP"):
		passed = false
	if not _assert_true(fielder.has_ball, "Fielder secures ball during pickup"):
		passed = false

	# Test 4: Return to Home Position
	fielder.reset_to_home()
	if not _assert_true(fielder.current_state == FielderController.FielderState.IDLE, "reset_to_home() restores IDLE state"):
		passed = false
	if not _assert_true(fielder.position == fielder.home_position, "Fielder returns to assigned home coordinates"):
		passed = false

	# Cleanup
	ball.free()
	fielder.free()
	root.free()

	return passed

func _assert_true(condition: bool, description: String) -> bool:
	if condition:
		print("  [PASS] %s" % description)
		return true
	else:
		printerr("  [FAIL] %s: Assertion failed" % description)
		return false
