# TestAIBowler.gd - CricStrike 3D
# Headless unit test suite for AI Bowler delivery planning, difficulty modes & pitch adaptation
class_name TestAIBowler

const GameConstants = preload("res://scripts/core/game_constants.gd")
const BowlerTypes = preload("res://scripts/bowling/bowler_types.gd")
const PitchConditions = preload("res://scripts/core/pitch_conditions.gd")
const AIBowler = preload("res://scripts/bowling/ai_bowler.gd")

static func run_all_tests() -> bool:
	var passed: bool = true
	print("--- Running TestAIBowler ---")
	
	var flat_pitch := PitchConditions.new(GameConstants.PitchType.FLAT)
	var green_pitch := PitchConditions.new(GameConstants.PitchType.GREEN)
	var dusty_pitch := PitchConditions.new(GameConstants.PitchType.DUSTY)
	
	# Test 1: Easy Mode AI Planning
	var ai_easy := AIBowler.new(GameConstants.Difficulty.EASY)
	var del_easy := ai_easy.plan_next_delivery(flat_pitch, true)
	if not _assert_true(del_easy.speed_kmh <= 128.0, "Easy AI bowls friendly slow-to-medium pace (<= 128 km/h)"):
		passed = false
	if not _assert_true(del_easy.marker_fade_time_sec > 10.0, "Easy AI marker stays visible throughout (> 10s)"):
		passed = false
	if not _assert_true(abs(del_easy.swing_intensity) <= 0.25, "Easy AI applies minimal swing"):
		passed = false

	# Test 2: Legend / Pro Mode AI Planning
	var ai_legend := AIBowler.new(GameConstants.Difficulty.LEGEND)
	var del_legend := ai_legend.plan_next_delivery(flat_pitch, true)
	if not _assert_true(del_legend.marker_fade_time_sec <= 0.25, "Legend AI marker fades almost immediately (<= 0.25s)"):
		passed = false
	if not _assert_true(del_legend.speed_kmh >= 115.0, "Legend AI bowls with realistic variation speeds"):
		passed = false

	# Test 3: Green Pitch Seam Exploitation on Hard Mode
	var ai_hard := AIBowler.new(GameConstants.Difficulty.HARD)
	var del_green := ai_hard.plan_next_delivery(green_pitch, true)
	if not _assert_true(abs(del_green.seam_deviation_deg) >= 1.5, "Hard AI on Green Pitch applies sharp seam deviation (>= 1.5°)"):
		passed = false

	# Test 4: Dusty Pitch Cutters on Hard Mode
	var del_dusty := ai_hard.plan_next_delivery(dusty_pitch, true)
	if not _assert_true(del_dusty.delivery_type == BowlerTypes.DeliveryType.OFF_CUTTER, "Hard AI on Dusty Pitch bowls off-cutters"):
		passed = false

	# Test 5: Length Categorization
	if not _assert_true(BowlerTypes.categorize_length(8.8) == BowlerTypes.PitchLengthZone.YORKER, "8.8m categorized as YORKER"):
		passed = false
	if not _assert_true(BowlerTypes.categorize_length(7.2) == BowlerTypes.PitchLengthZone.FULL, "7.2m categorized as FULL"):
		passed = false
	if not _assert_true(BowlerTypes.categorize_length(5.5) == BowlerTypes.PitchLengthZone.GOOD_LENGTH, "5.5m categorized as GOOD_LENGTH"):
		passed = false
	if not _assert_true(BowlerTypes.categorize_length(2.8) == BowlerTypes.PitchLengthZone.SHORT, "2.8m categorized as SHORT"):
		passed = false

	return passed

static func _assert_true(condition: bool, description: String) -> bool:
	if condition:
		print("  [PASS] %s" % description)
		return true
	else:
		printerr("  [FAIL] %s: Assertion failed" % description)
		return false
