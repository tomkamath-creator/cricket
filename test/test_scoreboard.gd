# TestScoreboard.gd - CricStrike 3D
# Headless unit test suite for runs scoring, strike rotation, over tracking & wagon wheel
class_name TestScoreboard
extends RefCounted

const GameConstants = preload("res://scripts/core/game_constants.gd")
const UmpireRules = preload("res://scripts/umpire/umpire_rules.gd")
const ScoreboardData = preload("res://scripts/match/scoreboard_data.gd")

func run_all_tests() -> bool:
	var passed: bool = true
	print("--- Running TestScoreboard ---")
	
	var sb: ScoreboardData = ScoreboardData.new(2, 28) # 2 overs match, target 28
	
	# Initial check
	if not _assert_true(sb.striker.name == "Rohit Sharma", "Initial striker is Rohit Sharma"):
		passed = false

	# Test 1: Record 1 Run (Odd run -> Strike rotation)
	var single_call := UmpireRules.UmpireCall.new(UmpireRules.DecisionType.RUNS_SCORED, 1, false, false, true, "1 Run")
	sb.record_delivery(single_call, 45.0, 32.0, false)
	
	if not _assert_true(sb.current_runs == 1, "Score is 1 run"):
		passed = false
	if not _assert_true(sb.striker.name == "Virat Kohli", "Strike rotated to Virat Kohli on single"):
		passed = false
	if not _assert_true(sb.get_overs_string() == "0.1", "Overs string is 0.1"):
		passed = false

	# Test 2: Record Boundary 4 (Even run -> No strike rotation)
	var four_call := UmpireRules.UmpireCall.new(UmpireRules.DecisionType.FOUR, 4, false, false, true, "FOUR!")
	sb.record_delivery(four_call, 135.0, 68.0, false)
	
	if not _assert_true(sb.current_runs == 5, "Score is 5 runs"):
		passed = false
	if not _assert_true(sb.striker.name == "Virat Kohli", "Strike remains with Virat Kohli on four"):
		passed = false
	if not _assert_true(sb.striker.runs == 4 and sb.striker.fours == 1, "Virat has 4 runs and 1 four"):
		passed = false

	# Test 3: Record Wide (Extra run, ball does not increment)
	var wide_call := UmpireRules.UmpireCall.new(UmpireRules.DecisionType.WIDE, 1, false, true, false, "WIDE")
	sb.record_delivery(wide_call)
	
	if not _assert_true(sb.current_runs == 6, "Score is 6 runs after Wide"):
		passed = false
	if not _assert_true(sb.get_overs_string() == "0.2", "Wide does not count as legal ball (still 0.2)"):
		passed = false

	# Test 4: Complete the Over (Bowl remaining 4 legal balls)
	var dot_call := UmpireRules.UmpireCall.new(UmpireRules.DecisionType.DOT_BALL, 0, false, false, true, "Dot")
	sb.record_delivery(dot_call) # 0.3
	sb.record_delivery(dot_call) # 0.4
	sb.record_delivery(dot_call) # 0.5
	sb.record_delivery(dot_call) # 1.0 (End of Over 1!)
	
	if not _assert_true(sb.get_overs_string() == "1.0", "Overs string is 1.0 at end of over"):
		passed = false
	if not _assert_true(sb.striker.name == "Rohit Sharma", "Strike automatically rotated at end of over"):
		passed = false

	# Test 5: Wagon Wheel Records
	if not _assert_true(sb.wagon_wheel_records.size() >= 2, "Wagon wheel recorded shots"):
		passed = false

	# Test 6: Run Rates Calculation
	var crr: float = sb.get_current_run_rate()
	if not _assert_true(crr == 6.0, "CRR is exactly 6.0 (6 runs in 1.0 over)"):
		passed = false
	var rrr: float = sb.get_required_run_rate()
	if not _assert_true(rrr > 0.0, "RRR calculated for target chase"):
		passed = false

	return passed

func _assert_true(condition: bool, description: String) -> bool:
	if condition:
		print("  [PASS] %s" % description)
		return true
	else:
		printerr("  [FAIL] %s: Assertion failed" % description)
		return false
