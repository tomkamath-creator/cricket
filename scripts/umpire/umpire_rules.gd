# UmpireRules.gd - CricStrike 3D
# Complete Cricket Umpire Rulebook: Wickets (Bowled, Caught, LBW, Run Out), No Balls & Wides
class_name UmpireRules
extends RefCounted

const GameConstants = preload("res://scripts/core/game_constants.gd")

enum DecisionType {
	DOT_BALL,
	RUNS_SCORED,
	FOUR,
	SIX,
	BOWLED,
	CAUGHT,
	LBW,
	RUN_OUT,
	NO_BALL,
	WIDE
}

class UmpireCall:
	var decision: DecisionType
	var runs_awarded: int
	var is_wicket: bool
	var is_extra: bool
	var is_legal_delivery: bool
	var call_text: String

	func _init(p_dec: DecisionType, p_runs: int, p_wkt: bool, p_extra: bool, p_legal: bool, p_text: String) -> void:
		decision = p_dec
		runs_awarded = p_runs
		is_wicket = p_wkt
		is_extra = p_extra
		is_legal_delivery = p_legal
		call_text = p_text

# 1. Delivery Legality Check (No Ball & Wide)
static func evaluate_delivery_legality(front_foot_landing_z: float, ball_crease_pos: Vector3, is_rhb: bool = true) -> UmpireCall:
	# Front Foot No Ball: Bowler crease is at -10.06m, popping crease is at -8.84m
	# If front foot lands completely past popping crease (-8.84m)
	if front_foot_landing_z > -GameConstants.PITCH_LENGTH * 0.5 + GameConstants.POPPING_CREASE_OFFSET:
		return UmpireCall.new(DecisionType.NO_BALL, 1, false, true, false, "NO BALL! Overstepping Crease")
		
	# Waist-high Full Toss No Ball: Ball passes batsman without bouncing above waist height (~1.15m)
	if ball_crease_pos.z >= 8.5 and ball_crease_pos.y > 1.15:
		return UmpireCall.new(DecisionType.NO_BALL, 1, false, true, false, "NO BALL! Waist-High Full Toss")

	# Wide Tramline Check (Passing outside offside tramline or down leg side)
	var off_tramline_x: float = 0.85 if is_rhb else -0.85
	var leg_tramline_x: float = -0.32 if is_rhb else 0.32
	
	if is_rhb:
		if ball_crease_pos.x > off_tramline_x:
			return UmpireCall.new(DecisionType.WIDE, 1, false, true, false, "WIDE BALL (Off Side)")
		elif ball_crease_pos.x < leg_tramline_x and ball_crease_pos.z >= 8.2:
			return UmpireCall.new(DecisionType.WIDE, 1, false, true, false, "WIDE BALL (Down Leg)")
	else:
		if ball_crease_pos.x < off_tramline_x:
			return UmpireCall.new(DecisionType.WIDE, 1, false, true, false, "WIDE BALL (Off Side)")
		elif ball_crease_pos.x > leg_tramline_x and ball_crease_pos.z >= 8.2:
			return UmpireCall.new(DecisionType.WIDE, 1, false, true, false, "WIDE BALL (Down Leg)")

	return null # Delivery is legal

# 2. LBW Evaluation (Hawkeye 3-Point Check)
static func evaluate_lbw(
	pitch_point: Vector3,
	pad_impact_point: Vector3,
	projected_stump_impact_y: float,
	has_bat_contact: bool,
	is_rhb: bool = true
) -> UmpireCall:
	# Condition 1: No Bat Involved
	if has_bat_contact:
		return UmpireCall.new(DecisionType.DOT_BALL, 0, false, false, true, "NOT OUT - Inside Edge")

	# Condition 2: Pitching in line or outside off stump (Cannot pitch outside leg stump)
	var leg_stump_limit: float = -0.12 if is_rhb else 0.12
	var pitched_outside_leg: bool = (pitch_point.x < leg_stump_limit) if is_rhb else (pitch_point.x > leg_stump_limit)
	if pitched_outside_leg:
		return UmpireCall.new(DecisionType.DOT_BALL, 0, false, false, true, "NOT OUT - Pitched Outside Leg")

	# Condition 3: Impact in line with the stumps (|X| <= 0.16m)
	if abs(pad_impact_point.x) > 0.18:
		return UmpireCall.new(DecisionType.DOT_BALL, 0, false, false, true, "NOT OUT - Impact Outside Off")

	# Condition 4: Wickets Hitting (Projected height <= stump height 0.711m and > 0.05m)
	if projected_stump_impact_y >= 0.05 and projected_stump_impact_y <= GameConstants.STUMP_HEIGHT:
		return UmpireCall.new(DecisionType.LBW, 0, true, false, true, "OUT! LBW - Leg Before Wicket")

	return UmpireCall.new(DecisionType.DOT_BALL, 0, false, false, true, "NOT OUT - Missing Stumps (Height)")

# 3. Bowled Wicket Check
static func evaluate_bowled(stumps_shattered: bool) -> UmpireCall:
	if stumps_shattered:
		return UmpireCall.new(DecisionType.BOWLED, 0, true, false, true, "OUT! BOWLED!")
	return null

# 4. Caught Wicket Check
static func evaluate_caught(has_bat_hit: bool, is_caught_on_full: bool) -> UmpireCall:
	if has_bat_hit and is_caught_on_full:
		return UmpireCall.new(DecisionType.CAUGHT, 0, true, false, true, "OUT! CAUGHT!")
	return null

# 5. Boundary Check
static func evaluate_boundary(has_pitched: bool) -> UmpireCall:
	if has_pitched:
		return UmpireCall.new(DecisionType.FOUR, 4, false, false, true, "FOUR! Boundary 4 Runs")
	else:
		return UmpireCall.new(DecisionType.SIX, 6, false, false, true, "SIX! Maximum 6 Runs")
