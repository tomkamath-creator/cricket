# TestPitchPhysics.gd - CricStrike 3D
# Headless unit test suite for 3D pitch arena dimensions and surface bounce physics
class_name TestPitchPhysics

const GameConstants = preload("res://scripts/core/game_constants.gd")
const PitchConditions = preload("res://scripts/core/pitch_conditions.gd")

static func run_all_tests() -> bool:
	var passed: bool = true
	print("--- Running TestPitchPhysics ---")
	
	# Test 1: Pitch Length & Width
	if not _assert_equal(GameConstants.PITCH_LENGTH, 20.12, "GameConstants.PITCH_LENGTH == 20.12m (22 yards)"):
		passed = false
	if not _assert_equal(GameConstants.POPPING_CREASE_OFFSET, 1.22, "Popping crease offset == 1.22m"):
		passed = false
	if not _assert_equal(GameConstants.STUMP_HEIGHT, 0.711, "Stump height == 0.711m (28 inches)"):
		passed = false
	if not _assert_equal(GameConstants.BALL_MASS_KG, 0.160, "Ball regulation mass == 0.160kg"):
		passed = false

	# Test 2: Pitch Conditions Restitution & Friction
	var green_pitch: PitchConditions = PitchConditions.new(GameConstants.PitchType.GREEN)
	if not _assert_true(green_pitch.restitution > 0.8, "Green pitch has high bounce restitution (> 0.80)"):
		passed = false
	if not _assert_true(green_pitch.seam_factor > 1.3, "Green pitch seam movement is accentuated"):
		passed = false

	var dusty_pitch: PitchConditions = PitchConditions.new(GameConstants.PitchType.DUSTY)
	if not _assert_true(dusty_pitch.spin_grip > 1.4, "Dusty pitch has high spin grip (> 1.40)"):
		passed = false
	if not _assert_true(dusty_pitch.restitution < 0.7, "Dusty pitch has lower bounce restitution (< 0.70)"):
		passed = false

	var wet_pitch: PitchConditions = PitchConditions.new(GameConstants.PitchType.WET)
	if not _assert_true(wet_pitch.skid_factor > 1.3, "Wet pitch has high skid factor"):
		passed = false

	# Test 3: Ball Bounce Velocity Calculation
	var incoming_vel := Vector3(0.0, -8.0, 32.0) # Downwards at 32 m/s (~115 km/h)
	var post_bounce_flat: Vector3 = green_pitch.calculate_pitch_bounce(incoming_vel, Vector3.ZERO, deg_to_rad(5.0))
	if not _assert_true(post_bounce_flat.y > 0.0, "Post-bounce velocity points upward (Y > 0)"):
		passed = false
	if not _assert_true(abs(post_bounce_flat.x) > 0.0, "Seam angle creates lateral deviation"):
		passed = false

	return passed

static func _assert_equal(actual: float, expected: float, description: String, tolerance: float = 0.001) -> bool:
	if abs(actual - expected) <= tolerance:
		print("  [PASS] %s" % description)
		return true
	else:
		printerr("  [FAIL] %s: Expected %.4f, Got %.4f" % [description, expected, actual])
		return false

static func _assert_true(condition: bool, description: String) -> bool:
	if condition:
		print("  [PASS] %s" % description)
		return true
	else:
		printerr("  [FAIL] %s: Assertion failed" % description)
		return false
