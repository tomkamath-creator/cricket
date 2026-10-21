# TestTimingEngine.gd - CricStrike 3D
# Headless unit test suite for 8-way directional batting and millisecond timing window engine
class_name TestTimingEngine

static func run_all_tests() -> bool:
	var passed: bool = true
	print("--- Running TestTimingEngine ---")
	
	# Test 1: 8-Way Joystick Sector Mapping
	# Up = (0, -1) -> STRAIGHT
	var straight := ShotLibrary.vector_to_direction(Vector2(0.0, -1.0))
	if not _assert_true(straight == GameConstants.ShotDirection.STRAIGHT, "Joystick Up maps to STRAIGHT"):
		passed = false

	# Up-Left = (-0.7, -0.7) -> COVER
	var cover := ShotLibrary.vector_to_direction(Vector2(-0.707, -0.707))
	if not _assert_true(cover == GameConstants.ShotDirection.COVER, "Joystick Up-Left maps to COVER"):
		passed = false

	# Left = (-1, 0) -> POINT
	var point := ShotLibrary.vector_to_direction(Vector2(-1.0, 0.0))
	if not _assert_true(point == GameConstants.ShotDirection.POINT, "Joystick Left maps to POINT"):
		passed = false

	# Right = (1, 0) -> SQUARE_LEG
	var sq_leg := ShotLibrary.vector_to_direction(Vector2(1.0, 0.0))
	if not _assert_true(sq_leg == GameConstants.ShotDirection.SQUARE_LEG, "Joystick Right maps to SQUARE_LEG"):
		passed = false

	# Test 2: Shot Launch Angles (Grounded vs Lofted)
	var straight_grounded := ShotLibrary.get_shot(GameConstants.ShotDirection.STRAIGHT, GameConstants.ShotElevation.GROUNDED)
	var straight_lofted := ShotLibrary.get_shot(GameConstants.ShotDirection.STRAIGHT, GameConstants.ShotElevation.LOFTED)
	
	if not _assert_true(straight_grounded.base_launch_angle_deg <= 8.0, "Grounded drive launch angle <= 8° (stays low)"):
		passed = false
	if not _assert_true(straight_lofted.base_launch_angle_deg >= 22.0, "Lofted drive launch angle >= 22° (clears field)"):
		passed = false

	# Test 3: Timing Ratings Evaluation
	var fake_ball_vel := Vector3(0.0, 0.0, 36.0) # 130 km/h delivery
	var fake_ball_pos := Vector3(0.0, 0.6, 9.05)
	
	# A. Perfect Timing (Delta = 0 ms)
	var res_perfect := TimingEngine.evaluate_contact(fake_ball_pos, fake_ball_vel, 9.05, straight_grounded, GameConstants.Difficulty.MEDIUM, 0.0, true)
	if not _assert_true(res_perfect.rating == GameConstants.TimingRating.PERFECT, "Delta 0 ms produces PERFECT rating"):
		passed = false
	if not _assert_true(res_perfect.exit_speed_kmh > 100.0, "Perfect drive exit speed > 100 km/h"):
		passed = false

	# B. Early Timing (Delta = -40 ms on Medium)
	var res_early := TimingEngine.evaluate_contact(fake_ball_pos, fake_ball_vel, 9.05, straight_grounded, GameConstants.Difficulty.MEDIUM, -40.0, true)
	if not _assert_true(res_early.rating == GameConstants.TimingRating.EARLY, "Delta -40 ms produces EARLY rating"):
		passed = false

	# C. Late Timing (Delta = +40 ms on Medium)
	var res_late := TimingEngine.evaluate_contact(fake_ball_pos, fake_ball_vel, 9.05, straight_grounded, GameConstants.Difficulty.MEDIUM, 40.0, true)
	if not _assert_true(res_late.rating == GameConstants.TimingRating.LATE, "Delta +40 ms produces LATE rating"):
		passed = false

	# D. Too Late (Delta = +95 ms on Medium -> Edge)
	var res_too_late := TimingEngine.evaluate_contact(fake_ball_pos, fake_ball_vel, 9.05, straight_grounded, GameConstants.Difficulty.MEDIUM, 95.0, true)
	if not _assert_true(res_too_late.rating == GameConstants.TimingRating.TOO_LATE, "Delta +95 ms produces TOO_LATE rating"):
		passed = false
	if not _assert_true(res_too_late.is_edge, "Too late timing registers as an edge"):
		passed = false

	# E. Missed (Delta = 250 ms)
	var res_missed := TimingEngine.evaluate_contact(fake_ball_pos, fake_ball_vel, 9.05, straight_grounded, GameConstants.Difficulty.MEDIUM, 250.0, true)
	if not _assert_true(res_missed.rating == GameConstants.TimingRating.MISSED, "Delta +250 ms produces MISSED rating"):
		passed = false

	return passed

static func _assert_true(condition: bool, description: String) -> bool:
	if condition:
		print("  [PASS] %s" % description)
		return true
	else:
		printerr("  [FAIL] %s: Assertion failed" % description)
		return false
