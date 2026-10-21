# ScoreboardUI.gd - CricStrike 3D
# Broadcast TV Scoreboard Overlay with Over Tracker, Run Rates & Wagon Wheel Dialog
class_name ScoreboardUI
extends Control

signal wagon_wheel_toggled()

const ScoreboardData = preload("res://scripts/match/scoreboard_data.gd")

var scoreboard: ScoreboardData

# UI References
@onready var team_score_label: Label = $ScorePanel/VBoxContainer/TopRow/TeamScoreLabel
@onready var overs_label: Label = $ScorePanel/VBoxContainer/TopRow/OversLabel
@onready var crr_label: Label = $ScorePanel/VBoxContainer/TopRow/CRRLabel
@onready var striker_label: Label = $ScorePanel/VBoxContainer/PlayerRow/StrikerLabel
@onready var non_striker_label: Label = $ScorePanel/VBoxContainer/PlayerRow/NonStrikerLabel
@onready var bowler_label: Label = $ScorePanel/VBoxContainer/PlayerRow/BowlerLabel
@onready var over_tracker_container: HBoxContainer = $ScorePanel/VBoxContainer/OverTrackerRow/BallsContainer
@onready var wagon_btn: Button = $ScorePanel/VBoxContainer/TopRow/WagonWheelButton

func _ready() -> void:
	if wagon_btn:
		wagon_btn.pressed.connect(func(): wagon_wheel_toggled.emit())

func bind_scoreboard(p_scoreboard: ScoreboardData) -> void:
	scoreboard = p_scoreboard
	scoreboard.score_updated.connect(refresh_display)
	refresh_display()

func refresh_display() -> void:
	if not scoreboard:
		return
		
	# Team Score & Overs
	if team_score_label:
		team_score_label.text = "%s  %d / %d" % [scoreboard.batting_team, scoreboard.current_runs, scoreboard.current_wickets]
		
	if overs_label:
		overs_label.text = "(%s / %d ov)" % [scoreboard.get_overs_string(), scoreboard.total_overs_allocated]
		
	if crr_label:
		if scoreboard.target_runs > 0:
			crr_label.text = "CRR: %.2f | RRR: %.2f (Need %d off %d)" % [
				scoreboard.get_current_run_rate(),
				scoreboard.get_required_run_rate(),
				max(0, scoreboard.target_runs - scoreboard.current_runs),
				max(0, (scoreboard.total_overs_allocated * 6) - scoreboard.total_legal_balls)
			]
		else:
			crr_label.text = "CRR: %.2f" % scoreboard.get_current_run_rate()

	# Batsmen & Bowler Stats
	if striker_label and scoreboard.striker:
		striker_label.text = "%s*  %d (%d)  [S/R: %.0f]" % [
			scoreboard.striker.name,
			scoreboard.striker.runs,
			scoreboard.striker.balls_faced,
			scoreboard.striker.get_strike_rate()
		]
		
	if non_striker_label and scoreboard.non_striker:
		non_striker_label.text = "%s  %d (%d)" % [
			scoreboard.non_striker.name,
			scoreboard.non_striker.runs,
			scoreboard.non_striker.balls_faced
		]
		
	if bowler_label and scoreboard.current_bowler:
		bowler_label.text = "Bowl: %s  %s-%d-%d-%d" % [
			scoreboard.current_bowler.name,
			scoreboard.current_bowler.get_overs_string(),
			scoreboard.current_bowler.maidens,
			scoreboard.current_bowler.runs_conceded,
			scoreboard.current_bowler.wickets
		]

	# Over Tracker Balls
	if over_tracker_container:
		for child in over_tracker_container.get_children():
			child.queue_free()
			
		for ball_str in scoreboard.current_over_balls:
			var badge := Label.new()
			badge.text = " %s " % ball_str
			badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			
			if ball_str == "W":
				badge.modulate = Color(1.0, 0.25, 0.25) # Red for wicket
			elif ball_str in ["4", "6"]:
				badge.modulate = Color(0.2, 0.95, 0.95) # Cyan for boundary
			elif ball_str in ["Wd", "Nb"]:
				badge.modulate = Color(1.0, 0.8, 0.2)  # Gold for extras
			else:
				badge.modulate = Color.WHITE
				
			over_tracker_container.add_child(badge)
