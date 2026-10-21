# TestUmpireRules.gd - CricStrike 3D
# Headless unit test suite for complete Cricket Umpire rulebook (Bowled, Caught, LBW, No-Ball, Wide, 4, 6)
class_name TestUmpireRules
extends RefCounted

const GameConstants = preload("res://scripts/core/game_constants.gd")
const UmpireRules = preload("res://scripts/umpire/umpire_rules.gd")

func run_all_tests() -> bool:
	var passed: bool = true
	print("--- Running TestUmpireRules ---")
	
	# Test 1: Front Foot No-Ball (Crease overstepping)
	# Popping crease is at -8.84m. Landing at -8.5m is past the crease.
	var no_ball_crease := UmpireRules.evaluate_delivery_legality(-8.5, Vector3(0.1, 0.5, 9.0), true)
	if not _assert_true(no_ball_crease != null and no_ball_crease.decision == UmpireRules.DecisionType.NO_BALL, "Overstepping popping crease yields NO_BALL"):
		passed = false

	# Test 2: Waist-High Full Toss No-Ball
	var no_ball_toss := UmpireRules.evaluate_delivery_legality(-9.5, Vector3(0.0, 1.35, 9.0), true)
	if not _assert_true(no_ball_toss != null and no_ball_toss.decision == UmpireRules.DecisionType.NO_BALL, "Waist-high full toss (>1.15m) yields NO_BALL"):
		passed = false

	# Test 3: Wide Balls (Off-Side tramline & Down Leg)
	var wide_off := UmpireRules.evaluate_delivery_legality(-9.5, Vector3(0.95, 0.4, 9.0), true)
	if not _assert_true(wide_off != null and wide_off.decision == UmpireRules.DecisionType.WIDE, "Passing wide outside off tramline (>0.85m) yields WIDE"):
		passed = false

	var wide_leg := UmpireRules.evaluate_delivery_legality(-9.5, Vector3(-0.45, 0.4, 9.0), true)
	if not _assert_true(wide_leg != null and wide_leg.decision == UmpireRules.DecisionType.WIDE, "Passing down leg side yields WIDE"):
		passed = false

	# Test 4: Legal Delivery
	var legal_ball := UmpireRules.evaluate_delivery_legality(-9.5, Vector3(0.15, 0.4, 9.0), true)
	if not _assert_true(legal_ball == null, "Ball inside tramlines and behind crease is legal (null)"):
		passed = false

	# Test 5: LBW - Inside Edge Defense
	var lbw_edge := UmpireRules.evaluate_lbw(Vector3(0.05, 0.02, 6.0), Vector3(0.02, 0.4, 8.9), 0.35, true, true)
	if not _assert_true(not lbw_edge.is_wicket, "LBW with bat contact is NOT OUT (Inside Edge)"):
		passed = false

	# Test 6: LBW - Pitched Outside Leg
	var lbw_outside_leg := UmpireRules.evaluate_lbw(Vector3(-0.25, 0.02, 6.0), Vector3(0.02, 0.4, 8.9), 0.35, false, true)
	if not _assert_true(not lbw_outside_leg.is_wicket, "LBW pitching outside leg stump is NOT OUT"):
		passed = false

	# Test 7: LBW - Out! (Pitched in line, impact in line, wickets hitting)
	var lbw_out := UmpireRules.evaluate_lbw(Vector3(0.05, 0.02, 6.0), Vector3(0.04, 0.4, 8.9), 0.38, false, true)
	if not _assert_true(lbw_out.is_wicket and lbw_out.decision == UmpireRules.DecisionType.LBW, "Hawkeye 3-point in-line contact yields OUT LBW"):
		passed = false

	# Test 8: Bowled & Caught
	var bowled_call := UmpireRules.evaluate_bowled(true)
	if not _assert_true(bowled_call.is_wicket and bowled_call.decision == UmpireRules.DecisionType.BOWLED, "Stump shatter yields OUT BOWLED"):
		passed = false

	var caught_call := UmpireRules.evaluate_caught(true, true)
	if not _assert_true(caught_call.is_wicket and caught_call.decision == UmpireRules.DecisionType.CAUGHT, "Bat hit + catch on the full yields OUT CAUGHT"):
		passed = false

	# Test 9: Boundary 4 and 6
	var four_call := UmpireRules.evaluate_boundary(true)
	if not _assert_true(four_call.runs_awarded == 4, "Boundary after pitch awards 4 runs"):
		passed = false

	var six_call := UmpireRules.evaluate_boundary(false)
	if not _assert_true(six_call.runs_awarded == 6, "Boundary on the full awards 6 runs"):
		passed = false

	return passed

func _assert_true(condition: bool, description: String) -> bool:
	if condition:
		print("  [PASS] %s" % description)
		return true
	else:
		printerr("  [FAIL] %s: Assertion failed" % description)
		return false
