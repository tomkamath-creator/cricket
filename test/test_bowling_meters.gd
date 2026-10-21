# TestBowlingMeters.gd - CricStrike 3D
# Headless unit test suite for oscillating swing & speed meters
class_name TestBowlingMeters

const BowlingMeters = preload("res://scripts/bowling/bowling_meters.gd")

static func run_all_tests() -> bool:
	var passed: bool = true
	print("--- Running TestBowlingMeters ---")
	
	var meters := BowlingMeters.new()
	
	# Test 1: Swing Meter Oscillation
	meters.start_swing_meter(0.5, 1.0)
	if not _assert_true(meters.current_state == BowlingMeters.MeterState.SWING_OSCILLATING, "Swing meter starts in SWING_OSCILLATING state"):
		passed = false

	# Advance time and verify value changes
	meters.update_process(0.1)
	if not _assert_true(meters.swing_value != 0.0, "Swing value oscillates over time"):
		passed = false

	# Test 2: Perfect Swing Sweetspot Lock
	meters.swing_value = 0.52 # Very close to target 0.50
	var swing_res := meters.lock_swing()
	if not _assert_true(bool(swing_res["sweetspot"]), "Locking within sweetspot yields perfect swing"):
		passed = false

	# Test 3: Speed Meter Sweep
	meters.start_speed_meter(110.0, 150.0, 1.0)
	if not _assert_true(meters.current_state == BowlingMeters.MeterState.SPEED_OSCILLATING, "Speed meter starts in SPEED_OSCILLATING state"):
		passed = false

	# Advance speed meter
	meters.update_process(0.25)
	if not _assert_true(meters.current_speed_kmh >= 110.0 and meters.current_speed_kmh <= 150.0, "Speed meter stays within 110-150 km/h range"):
		passed = false

	# Test 4: Peak Pace Sweetspot Lock
	meters.speed_meter_pos = 0.85 # Inside sweetspot [0.78, 0.94]
	var speed_res := meters.lock_speed()
	if not _assert_true(bool(speed_res["sweetspot"]), "Locking near peak yields express pace sweetspot"):
		passed = false
	if not _assert_true(float(speed_res["speed"]) >= 135.0, "Express pace speed >= 135 km/h"):
		passed = false

	return passed

static func _assert_true(condition: bool, description: String) -> bool:
	if condition:
		print("  [PASS] %s" % description)
		return true
	else:
		printerr("  [FAIL] %s: Assertion failed" % description)
		return false
