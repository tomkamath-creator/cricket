# run_tests.gd - CricStrike 3D
# Headless CI Test Runner for GitHub Actions and Local Testing
extends SceneTree

const TestPitchPhysics = preload("res://test/test_pitch_physics.gd")
const TestTimingEngine = preload("res://test/test_timing_engine.gd")
const TestStumpCollision = preload("res://test/test_stump_collision.gd")
const TestAIBowler = preload("res://test/test_ai_bowler.gd")
const TestBowlingMeters = preload("res://test/test_bowling_meters.gd")

func _init() -> void:
	print("==================================================")
	print("   CRICSTRIKE 3D - HEADLESS TEST RUNNER (PHASE 2)  ")
	print("==================================================")
	
	var all_passed: bool = true
	
	# Suite 1: Pitch Arena & Ball Bounce Physics
	var pitch_ok: bool = TestPitchPhysics.run_all_tests()
	if not pitch_ok:
		all_passed = false
	print("")

	# Suite 2: Batting Direction & Millisecond Timing Engine
	var timing_ok: bool = TestTimingEngine.run_all_tests()
	if not timing_ok:
		all_passed = false
	print("")

	# Suite 3: Stumps & Bails Dislodging Collision
	var stumps_ok: bool = TestStumpCollision.run_all_tests()
	if not stumps_ok:
		all_passed = false
	print("")

	# Suite 4: AI Bowler Delivery Planning & Pitch Adaptation
	var ai_ok: bool = TestAIBowler.run_all_tests()
	if not ai_ok:
		all_passed = false
	print("")

	# Suite 5: Oscillating Swing & Speed Meters
	var meters_ok: bool = TestBowlingMeters.run_all_tests()
	if not meters_ok:
		all_passed = false
	print("")

	print("==================================================")
	if all_passed:
		print("   ALL TESTS PASSED SUCCESSFULLY! (PHASE 2 READY) ")
		print("==================================================")
		quit(0)
	else:
		printerr("   TEST SUITE FAILED! CHECK LOGS ABOVE.         ")
		print("==================================================")
		quit(1)
