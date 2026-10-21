# run_tests.gd - CricStrike 3D
# Headless CI Test Runner for GitHub Actions and Local Testing
extends SceneTree

func _init() -> void:
	print("==================================================")
	print("   CRICSTRIKE 3D - HEADLESS TEST RUNNER (PHASE 1)  ")
	print("==================================================")
	
	var all_passed: bool = true
	
	# Suite 1: Pitch Arena & Ball Bounce Physics
	var pitch_ok := TestPitchPhysics.run_all_tests()
	if not pitch_ok:
		all_passed = false
	print("")

	# Suite 2: Batting Direction & Millisecond Timing Engine
	var timing_ok := TestTimingEngine.run_all_tests()
	if not timing_ok:
		all_passed = false
	print("")

	# Suite 3: Stumps & Bails Dislodging Collision
	var stumps_ok := TestStumpCollision.run_all_tests()
	if not stumps_ok:
		all_passed = false
	print("")

	print("==================================================")
	if all_passed:
		print("   ALL TESTS PASSED SUCCESSFULLY! (PHASE 1 READY) ")
		print("==================================================")
		quit(0)
	else:
		printerr("   TEST SUITE FAILED! CHECK LOGS ABOVE.         ")
		print("==================================================")
		quit(1)
