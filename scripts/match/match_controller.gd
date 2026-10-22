# MatchController.gd - CricStrike 3D
# Complete Over & Innings Match Loop coordinating Umpire, Scoreboard, Fielders, and Ball Events
class_name MatchController
extends Node

signal match_state_updated(status_message: String)
signal innings_won(winner_team: String, margin_message: String)

const GameConstants = preload("res://scripts/core/game_constants.gd")
const UmpireRules = preload("res://scripts/umpire/umpire_rules.gd")
const ScoreboardData = preload("res://scripts/match/scoreboard_data.gd")
const FieldingManager = preload("res://scripts/fielding/fielding_manager.gd")
const BowlingController = preload("res://scripts/bowling/bowling_controller.gd")
const BattingController = preload("res://scripts/batting/batting_controller.gd")
const CricketBall = preload("res://scripts/physics/cricket_ball.gd")
const AudioManager = preload("res://scripts/audio/audio_manager.gd")
const ScoreboardUI = preload("res://scripts/ui/scoreboard_ui.gd")
const WagonWheelView = preload("res://scripts/ui/wagon_wheel_view.gd")

@export var ball_ref: CricketBall
@export var batsman_ref: BattingController
@export var bowling_controller: BowlingController
@export var fielding_manager: FieldingManager
@export var scoreboard_ui: ScoreboardUI
@export var wagon_wheel_view: WagonWheelView

var scoreboard: ScoreboardData

# Per-ball tracking
var _current_ball_has_bat_hit: bool = false
var _current_ball_exit_vel: Vector3 = Vector3.ZERO
var _current_shot_heading: float = 0.0
var _current_ball_resolved: bool = false

func _ready() -> void:
	var mode_mgr := GameModeManager.get_instance()
	var overs := mode_mgr.selected_overs if mode_mgr else 5
	var target := mode_mgr.super_over_target if (mode_mgr and mode_mgr.current_mode == GameModeManager.Mode.SUPER_OVER and mode_mgr.player_is_chasing) else -1
	scoreboard = ScoreboardData.new(overs, target)
	if scoreboard_ui:
		scoreboard_ui.bind_scoreboard(scoreboard)
		scoreboard_ui.wagon_wheel_toggled.connect(_on_wagon_wheel_toggled)
		
	# Connect Ball signals
	if ball_ref:
		ball_ref.ball_delivered.connect(_on_ball_delivered)
		ball_ref.ball_hit.connect(_on_ball_hit)
		ball_ref.ball_boundary.connect(_on_ball_boundary)
		ball_ref.ball_stump_collision.connect(_on_stump_collision)
		ball_ref.ball_stopped.connect(_on_ball_stopped)
		
	# Connect Fielding signals
	if fielding_manager:
		fielding_manager.ball_caught.connect(_on_ball_caught)
		fielding_manager.ball_stopped_by_field.connect(_on_ball_fielded)

func _on_wagon_wheel_toggled() -> void:
	if wagon_wheel_view:
		if wagon_wheel_view.visible:
			wagon_wheel_view.visible = false
		else:
			wagon_wheel_view.open_wagon_wheel(scoreboard)

func _on_ball_delivered(_speed_kmh: float, _target_pos: Vector3) -> void:
	_current_ball_has_bat_hit = false
	_current_ball_exit_vel = Vector3.ZERO
	_current_shot_heading = 0.0
	_current_ball_resolved = false

func _on_ball_hit(exit_speed_kmh: float, launch_angle_deg: float, direction_vec: Vector3) -> void:
	_current_ball_has_bat_hit = true
	_current_ball_exit_vel = direction_vec * GameConstants.kmh_to_mps(exit_speed_kmh)
	
	var audio := AudioManager.get_instance()
	if audio:
		audio.play_bat_crack(exit_speed_kmh > 120.0 and launch_angle_deg > 20.0)
	
	# Calculate 0-360 deg heading in stadium ground plane
	var heading_rad := atan2(direction_vec.x, -direction_vec.z)
	_current_shot_heading = fposmod(rad_to_deg(heading_rad), 360.0)
	
	if fielding_manager:
		fielding_manager.on_ball_hit(ball_ref, _current_ball_exit_vel)

func _on_ball_boundary(runs: int) -> void:
	if _current_ball_resolved:
		return
	_current_ball_resolved = true
	
	var call := UmpireRules.evaluate_boundary(runs == 4)
	var shot_dist := GameConstants.BOUNDARY_RADIUS_Z
	scoreboard.record_delivery(call, _current_shot_heading, shot_dist, runs == 6)
	match_state_updated.emit(call.call_text)
	_reset_for_next_ball()

func _on_stump_collision(_stump: Node, _speed: float) -> void:
	var audio := AudioManager.get_instance()
	if audio:
		audio.play_stump_rattle()
		
	if _current_ball_resolved:
		return
	_current_ball_resolved = true
	
	var call := UmpireRules.evaluate_bowled(true)
	scoreboard.record_delivery(call, _current_shot_heading, 0.0, false)
	match_state_updated.emit(call.call_text)
	_reset_for_next_ball()

func _on_ball_caught(f_name: String) -> void:
	if _current_ball_resolved:
		return
	_current_ball_resolved = true
	
	var call := UmpireRules.evaluate_caught(_current_ball_has_bat_hit, true)
	if call:
		call.call_text = "OUT! CAUGHT by %s!" % f_name
		scoreboard.record_delivery(call, _current_shot_heading, 25.0, true)
		match_state_updated.emit(call.call_text)
	_reset_for_next_ball()

func _on_ball_fielded(f_name: String) -> void:
	if _current_ball_resolved:
		return
	_current_ball_resolved = true
	
	# Evaluate 1, 2, or 3 runs completed based on distance from pitch
	var runs_run: int = 1
	var field_pos := ball_ref.global_position if ball_ref else Vector3.ZERO
	var dist_from_stumps := Vector2(field_pos.x, field_pos.z).length()
	
	if dist_from_stumps > 42.0:
		runs_run = 2
	elif dist_from_stumps > 25.0:
		runs_run = 1
	else:
		runs_run = 0 # Dot ball / fielded in inner ring
		
	var call := UmpireRules.UmpireCall.new(
		UmpireRules.DecisionType.RUNS_SCORED if runs_run > 0 else UmpireRules.DecisionType.DOT_BALL,
		runs_run,
		false,
		false,
		true,
		("%d Run(s) - Fielded by %s" % [runs_run, f_name]) if runs_run > 0 else ("Dot Ball - Fielded by %s" % f_name)
	)
	scoreboard.record_delivery(call, _current_shot_heading, dist_from_stumps, false)
	match_state_updated.emit(call.call_text)
	_reset_for_next_ball()

func _on_ball_stopped() -> void:
	if _current_ball_resolved:
		return
	_current_ball_resolved = true
	
	# If ball stopped with no bat contact and no wickets, evaluate Wide / Legality or Dot ball
	if ball_ref:
		var legality := UmpireRules.evaluate_delivery_legality(
			-GameConstants.PITCH_LENGTH * 0.5 - 0.2, # legal foot landing
			ball_ref.pitch_point,
			batsman_ref.is_right_handed if batsman_ref else true
		)
		if legality:
			scoreboard.record_delivery(legality, 0.0, 0.0, false)
			match_state_updated.emit(legality.call_text)
			_reset_for_next_ball()
			return
			
	var dot_call := UmpireRules.UmpireCall.new(
		UmpireRules.DecisionType.DOT_BALL,
		0,
		false,
		false,
		true,
		"Dot Ball"
	)
	scoreboard.record_delivery(dot_call, 0.0, 0.0, false)
	match_state_updated.emit("Dot Ball")
	_reset_for_next_ball()

func _reset_for_next_ball() -> void:
	if fielding_manager:
		fielding_manager.reset_all_fielders()
	if bowling_controller:
		bowling_controller.complete_delivery()
