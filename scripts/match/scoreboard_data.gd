# ScoreboardData.gd - CricStrike 3D
# Complete Cricket Scoreboard, In-Game Statistics, Strike Rotation & Wagon Wheel Engine
class_name ScoreboardData
extends RefCounted

signal score_updated()
signal over_completed(over_number: int, maiden: bool)
signal innings_completed(total_runs: int, total_wickets: int)
signal strike_rotated(striker_name: String, non_striker_name: String)
signal half_century_achieved(batsman_name: String, runs: int, balls_faced: int)

class BatsmanStats:
	var name: String
	var runs: int = 0
	var balls_faced: int = 0
	var fours: int = 0
	var sixes: int = 0
	var is_out: bool = false
	var dismissal_info: String = "not out"
	var celebrated_fifty: bool = false

	func _init(p_name: String) -> void:
		name = p_name

	func get_strike_rate() -> float:
		if balls_faced == 0: return 0.0
		return (float(runs) / float(balls_faced)) * 100.0

class BowlerStats:
	var name: String
	var balls_bowled: int = 0
	var maidens: int = 0
	var runs_conceded: int = 0
	var wickets: int = 0
	var _runs_in_current_over: int = 0

	func _init(p_name: String) -> void:
		name = p_name

	func get_overs_string() -> String:
		var complete_overs := balls_bowled / 6
		var rem_balls := balls_bowled % 6
		return "%d.%d" % [complete_overs, rem_balls]

	func get_economy() -> float:
		if balls_bowled == 0: return 0.0
		var overs := float(balls_bowled) / 6.0
		return float(runs_conceded) / overs

class WagonWheelEntry:
	var heading_deg: float
	var distance_m: float
	var runs: int
	var is_lofted: bool

	func _init(p_heading: float, p_dist: float, p_runs: int, p_lofted: bool) -> void:
		heading_deg = p_heading
		distance_m = p_dist
		runs = p_runs
		is_lofted = p_lofted

# Match State
var total_overs_allocated: int = 5
var target_runs: int = -1 # -1 if 1st innings
var current_runs: int = 0
var current_wickets: int = 0
var total_legal_balls: int = 0
var extras_wides: int = 0
var extras_noballs: int = 0

# Lineup
var batting_team: String = "India"
var bowling_team: String = "Australia"
var striker: BatsmanStats
var non_striker: BatsmanStats
var current_bowler: BowlerStats
var current_over_balls: Array[String] = []
var wagon_wheel_records: Array[WagonWheelEntry] = []

func _init(p_overs: int = 5, p_target: int = -1) -> void:
	total_overs_allocated = p_overs
	target_runs = p_target
	striker = BatsmanStats.new("Rohit Sharma")
	non_striker = BatsmanStats.new("Virat Kohli")
	current_bowler = BowlerStats.new("Mitchell Starc")

func record_delivery(call: UmpireRules.UmpireCall, shot_heading_deg: float = 0.0, shot_distance: float = 0.0, is_lofted: bool = false) -> void:
	var runs := call.runs_awarded
	current_runs += runs
	
	if current_bowler:
		current_bowler.runs_conceded += runs
		current_bowler._runs_in_current_over += runs
		
	# 1. Extras Handling
	if call.is_extra:
		if call.decision == UmpireRules.DecisionType.WIDE:
			extras_wides += 1
			current_over_balls.append("Wd")
		elif call.decision == UmpireRules.DecisionType.NO_BALL:
			extras_noballs += 1
			current_over_balls.append("Nb")
		score_updated.emit()
		return # Extras do not count as legal delivery

	# 2. Legal Delivery Handling
	total_legal_balls += 1
	if current_bowler:
		current_bowler.balls_bowled += 1
		
	if striker:
		striker.balls_faced += 1
		var prev_runs := striker.runs
		striker.runs += runs
		if runs == 4: striker.fours += 1
		elif runs == 6: striker.sixes += 1
		
		# Check Half-Century milestone
		if not striker.celebrated_fifty and striker.runs >= 50 and prev_runs < 50:
			striker.celebrated_fifty = true
			half_century_achieved.emit(striker.name, striker.runs, striker.balls_faced)
		
	# Record Wagon Wheel
	if runs > 0 or shot_distance > 5.0:
		wagon_wheel_records.append(WagonWheelEntry.new(shot_heading_deg, shot_distance, runs, is_lofted))

	# 3. Wicket Handling
	if call.is_wicket:
		current_wickets += 1
		if current_bowler:
			current_bowler.wickets += 1
		if striker:
			striker.is_out = true
			striker.dismissal_info = call.call_text
		current_over_balls.append("W")
	else:
		current_over_balls.append(str(runs))

	# 4. Strike Rotation on Odd Runs (1, 3)
	if runs % 2 == 1:
		rotate_strike()

	# 5. Over Completion Check
	if total_legal_balls % 6 == 0:
		var completed_over_num := total_legal_balls / 6
		var is_maiden: bool = current_bowler._runs_in_current_over == 0
		if is_maiden:
			current_bowler.maidens += 1
		current_bowler._runs_in_current_over = 0
		
		# Rotate strike at end of over
		rotate_strike()
		over_completed.emit(completed_over_num, is_maiden)
		current_over_balls.clear()

	score_updated.emit()

	# 6. Innings Finish Check
	if current_wickets >= 10 or (total_legal_balls >= total_overs_allocated * 6) or (target_runs > 0 and current_runs >= target_runs):
		innings_completed.emit(current_runs, current_wickets)

func rotate_strike() -> void:
	var temp := striker
	striker = non_striker
	non_striker = temp
	strike_rotated.emit(striker.name, non_striker.name)

func get_overs_string() -> String:
	var complete_overs := total_legal_balls / 6
	var rem_balls := total_legal_balls % 6
	return "%d.%d" % [complete_overs, rem_balls]

func get_current_run_rate() -> float:
	if total_legal_balls == 0: return 0.0
	var overs := float(total_legal_balls) / 6.0
	return float(current_runs) / overs

func get_required_run_rate() -> float:
	if target_runs <= 0: return 0.0
	var balls_remaining := (total_overs_allocated * 6) - total_legal_balls
	if balls_remaining <= 0: return 0.0
	var runs_needed := target_runs - current_runs
	if runs_needed <= 0: return 0.0
	return (float(runs_needed) / float(balls_remaining)) * 6.0
