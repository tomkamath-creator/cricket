# MainMenuUI.gd - CricStrike 3D
# Complete offline main menu hub: Quick Match, Tournament, Super Over, Auction, Locker Room
class_name MainMenuUI
extends Control

const GameConstants = preload("res://scripts/core/game_constants.gd")
const GameModeManager = preload("res://scripts/modes/game_mode_manager.gd")
const TournamentEngine = preload("res://scripts/modes/tournament_engine.gd")
const AuctionEngine = preload("res://scripts/modes/auction_engine.gd")

# Hub Containers
@onready var main_hub: VBoxContainer = $CenterContainer/MainHub
@onready var quick_match_panel: Panel = $ModalContainer/QuickMatchPanel
@onready var tournament_panel: Panel = $ModalContainer/TournamentPanel
@onready var super_over_panel: Panel = $ModalContainer/SuperOverPanel
@onready var auction_panel: Panel = $ModalContainer/AuctionPanel

# Quick Match inputs
@onready var qm_team_a: OptionButton = $ModalContainer/QuickMatchPanel/VBox/TeamAOption
@onready var qm_team_b: OptionButton = $ModalContainer/QuickMatchPanel/VBox/TeamBOption
@onready var qm_overs: OptionButton = $ModalContainer/QuickMatchPanel/VBox/OversOption
@onready var qm_pitch: OptionButton = $ModalContainer/QuickMatchPanel/VBox/PitchOption
@onready var qm_diff: OptionButton = $ModalContainer/QuickMatchPanel/VBox/DiffOption

# Tournament Elements
@onready var tour_tree_label: Label = $ModalContainer/TournamentPanel/VBox/StandingsLabel
@onready var tour_status_label: Label = $ModalContainer/TournamentPanel/VBox/StatusLabel

# Super Over inputs
@onready var so_target_spin: SpinBox = $ModalContainer/SuperOverPanel/VBox/TargetSpin
@onready var so_role_check: CheckBox = $ModalContainer/SuperOverPanel/VBox/ChasingCheck

# Auction Elements
@onready var auc_player_name: Label = $ModalContainer/AuctionPanel/VBox/PlayerCard/PlayerName
@onready var auc_player_role: Label = $ModalContainer/AuctionPanel/VBox/PlayerCard/PlayerRole
@onready var auc_bid_label: Label = $ModalContainer/AuctionPanel/VBox/BidLabel
@onready var auc_purse_label: Label = $ModalContainer/AuctionPanel/VBox/PurseLabel
@onready var auc_log_label: Label = $ModalContainer/AuctionPanel/VBox/LogLabel

var tournament_engine: TournamentEngine
var auction_engine: AuctionEngine

func _ready() -> void:
	tournament_engine = TournamentEngine.new()
	if not tournament_engine.load_from_file():
		tournament_engine.initialize_tournament()
		
	auction_engine = AuctionEngine.new()
	if not auction_engine.load_from_file():
		auction_engine.initialize_auction()
		
	_hide_all_modals()
	_populate_dropdowns()

func _hide_all_modals() -> void:
	if quick_match_panel: quick_match_panel.visible = false
	if tournament_panel: tournament_panel.visible = false
	if super_over_panel: super_over_panel.visible = false
	if auction_panel: auction_panel.visible = false
	if main_hub: main_hub.visible = true

func _populate_dropdowns() -> void:
	var teams: Array[String] = ["India", "Australia", "England", "South Africa", "New Zealand", "Pakistan"]
	if qm_team_a:
		qm_team_a.clear()
		for t in teams: qm_team_a.add_item(t)
	if qm_team_b:
		qm_team_b.clear()
		for t in teams: qm_team_b.add_item(t)
		qm_team_b.select(1)
	if qm_overs:
		qm_overs.clear()
		qm_overs.add_item("2 Overs", 2)
		qm_overs.add_item("5 Overs", 5)
		qm_overs.add_item("10 Overs", 10)
		qm_overs.add_item("20 Overs", 20)
		qm_overs.select(1) # Default 5 overs
	if qm_pitch:
		qm_pitch.clear()
		qm_pitch.add_item("Flat Track", 0)
		qm_pitch.add_item("Green Seamer", 1)
		qm_pitch.add_item("Dusty Spinner", 2)
		qm_pitch.add_item("Wet Pitch", 3)
	if qm_diff:
		qm_diff.clear()
		qm_diff.add_item("Easy", 0)
		qm_diff.add_item("Medium", 1)
		qm_diff.add_item("Hard", 2)
		qm_diff.add_item("Legend", 3)
		qm_diff.select(1)

# --- Button Handlers from Main Hub ---

func _on_quick_match_pressed() -> void:
	main_hub.visible = false
	quick_match_panel.visible = true

func _on_tournament_pressed() -> void:
	main_hub.visible = false
	tournament_panel.visible = true
	_refresh_tournament_view()

func _on_super_over_pressed() -> void:
	main_hub.visible = false
	super_over_panel.visible = true

func _on_auction_pressed() -> void:
	main_hub.visible = false
	auction_panel.visible = true
	_refresh_auction_view()

func _on_locker_room_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/locker_room.tscn")

# --- Quick Match Launch ---

func _on_start_quick_match_pressed() -> void:
	var mgr := GameModeManager.get_instance()
	var team_a := qm_team_a.get_item_text(qm_team_a.selected)
	var team_b := qm_team_b.get_item_text(qm_team_b.selected)
	var overs := qm_overs.get_item_id(qm_overs.selected)
	var pitch := qm_pitch.get_item_id(qm_pitch.selected) as GameConstants.PitchType
	var diff := qm_diff.get_item_id(qm_diff.selected) as GameConstants.Difficulty
	
	mgr.setup_quick_match(team_a, team_b, overs, pitch, diff)
	get_tree().change_scene_to_file("res://scenes/main_arena.tscn")

# --- Super Over Launch ---

func _on_start_super_over_pressed() -> void:
	var mgr := GameModeManager.get_instance()
	var is_chasing := so_role_check.button_pressed if so_role_check else true
	var target := int(so_target_spin.value) if so_target_spin else 16
	mgr.setup_super_over("India", "Australia", is_chasing, target, GameConstants.Difficulty.HARD)
	get_tree().change_scene_to_file("res://scenes/main_arena.tscn")

# --- Tournament Logic ---

func _refresh_tournament_view() -> void:
	if tour_tree_label == null: return
	var standings := tournament_engine.get_standings()
	var txt := "POS  TEAM            P   W   L   PTS    NRR\n"
	txt += "------------------------------------------------\n"
	for i in range(standings.size()):
		var s := standings[i]
		txt += "%-4d %-15s %-3d %-3d %-3d %-6d %+.2f\n" % [
			i + 1, s.team_name, s.played, s.won, s.lost, s.points, s.nrr
		]
	tour_tree_label.text = txt
	if tour_status_label:
		tour_status_label.text = "All tournament progress saved automatically to local storage."

func _on_simulate_tour_round_pressed() -> void:
	# Simulate next pending group match
	for f in tournament_engine.fixtures:
		if not f.completed:
			var runs_a := randi_range(140, 190)
			var runs_b := randi_range(130, 185)
			var winner := f.team_a if runs_a > runs_b else f.team_b
			var loser := f.team_b if runs_a > runs_b else f.team_a
			var w_runs := maxi(runs_a, runs_b)
			var l_runs := mini(runs_a, runs_b)
			tournament_engine.record_match_result(f.id, winner, loser, w_runs, 20.0, l_runs, 20.0)
			break
	tournament_engine.save_to_file()
	_refresh_tournament_view()

# --- Auction Logic ---

func _refresh_auction_view() -> void:
	var p := auction_engine.get_current_player()
	var u := auction_engine.get_user_team()
	if auc_purse_label and u:
		auc_purse_label.text = "%s Purse: ₹%.2f Cr | Squad: %d/%d" % [u.name, u.purse_cr, u.squad.size(), u.max_squad]
	if p == null or auction_engine.is_auction_complete():
		if auc_player_name: auc_player_name.text = "AUCTION COMPLETED!"
		if auc_player_role: auc_player_role.text = "All players have been auctioned."
		if auc_bid_label: auc_bid_label.text = ""
		return
		
	if auc_player_name: auc_player_name.text = p.name
	if auc_player_role: auc_player_role.text = "%s | Rating: %d | Base: ₹%.2f Cr" % [p.role, p.rating, p.base_price_cr]
	if auc_bid_label:
		var leader := p.highest_bidder if not p.highest_bidder.is_empty() else "None (Opening Bid)"
		auc_bid_label.text = "Current Bid: ₹%.2f Cr (%s)" % [p.current_bid_cr, leader]

func _on_auction_bid_pressed() -> void:
	var ok := auction_engine.place_user_bid()
	if ok:
		if auc_log_label: auc_log_label.text = "You placed bid at ₹%.2f Cr!" % auction_engine.get_current_player().current_bid_cr
		# Trigger CPU Bot Counter-Bids
		var cpu_bidder := auction_engine.evaluate_cpu_bids()
		if not cpu_bidder.is_empty():
			if auc_log_label:
				auc_log_label.text += " -> %s countered at ₹%.2f Cr!" % [cpu_bidder, auction_engine.get_current_player().current_bid_cr]
	else:
		if auc_log_label: auc_log_label.text = "Bid failed! Insufficient budget purse."
	_refresh_auction_view()

func _on_auction_pass_hammer_pressed() -> void:
	var p := auction_engine.get_current_player()
	if p:
		var was_sold := auction_engine.hammer_down_sold()
		if auc_log_label:
			if was_sold:
				auc_log_label.text = "SOLD to %s for ₹%.2f Cr!" % [p.highest_bidder, p.current_bid_cr]
			else:
				auc_log_label.text = "%s went UNSOLD!" % p.name
		auction_engine.save_to_file()
		_refresh_auction_view()

func _on_modal_close_pressed() -> void:
	_hide_all_modals()
