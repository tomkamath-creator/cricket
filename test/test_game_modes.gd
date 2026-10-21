# TestGameModes.gd - CricStrike 3D
# Headless unit test suite for Offline Game Modes: Tournament Points Table / NRR, and Offline Auction Engine
class_name TestGameModes
extends RefCounted

const TournamentEngine = preload("res://scripts/modes/tournament_engine.gd")
const AuctionEngine = preload("res://scripts/modes/auction_engine.gd")
const GameModeManager = preload("res://scripts/modes/game_mode_manager.gd")
const GameConstants = preload("res://scripts/core/game_constants.gd")

const TEST_TOURNAMENT_SAVE: String = "user://test_tournament_save.json"
const TEST_AUCTION_SAVE: String = "user://test_auction_save.json"

func run_all_tests() -> bool:
	var passed: bool = true
	print("--- Running TestGameModes ---")

	# Test 1: GameModeManager Configuration
	var mgr := GameModeManager.get_instance()
	mgr.setup_quick_match("India", "Australia", 5, GameConstants.PitchType.GREEN, GameConstants.Difficulty.HARD)
	if not _assert_true(mgr.current_mode == GameModeManager.Mode.QUICK_MATCH, "Manager sets QUICK_MATCH mode"):
		passed = false
	if not _assert_true(mgr.selected_overs == 5 and mgr.team_player == "India", "Quick match config sets overs & teams"):
		passed = false

	# Test 2: Super Over Setup
	mgr.setup_super_over("India", "England", true, 18)
	if not _assert_true(mgr.current_mode == GameModeManager.Mode.SUPER_OVER, "Manager sets SUPER_OVER mode"):
		passed = false
	if not _assert_true(mgr.super_over_target == 18 and mgr.selected_overs == 1, "Super over sets 1 over and 18 run target"):
		passed = false

	# Test 3: Tournament Initialization & Fixture Schedule
	var tour := TournamentEngine.new()
	tour.initialize_tournament(["India", "Australia", "England", "South Africa"])
	if not _assert_true(tour.teams.size() == 4, "Tournament initializes with 4 teams"):
		passed = false
	# For 4 teams, 4 * 3 / 2 = 6 group fixtures
	if not _assert_true(tour.fixtures.size() == 6, "Single round-robin creates exactly 6 fixtures"):
		passed = false

	# Test 4: Match Outcome, Points Table & Net Run Rate (NRR)
	# Match 1: India 180 (20 ov) def Australia 140 (20 ov)
	# India NRR: 180/20 - 140/20 = 9.0 - 7.0 = +2.00
	# Australia NRR: 140/20 - 180/20 = 7.0 - 9.0 = -2.00
	tour.record_match_result(1, "India", "Australia", 180, 20.0, 140, 20.0)
	var standings := tour.get_standings()
	if not _assert_true(standings[0].team_name == "India", "India tops standings with 2 points"):
		passed = false
	if not _assert_true(is_equal_approx(standings[0].nrr, 2.0), "India NRR correctly computed as +2.00"):
		passed = false
	if not _assert_true(is_equal_approx(standings[standings.size() - 1].nrr, -2.0), "Australia NRR correctly computed as -2.00"):
		passed = false

	# Test 5: Tournament Local Persistence
	var save_tour_ok := tour.save_to_file(TEST_TOURNAMENT_SAVE)
	if not _assert_true(save_tour_ok, "Tournament state saved to user:// directory"):
		passed = false
	var loaded_tour := TournamentEngine.new()
	var load_tour_ok := loaded_tour.load_from_file(TEST_TOURNAMENT_SAVE)
	if not _assert_true(load_tour_ok, "Tournament state loaded from user:// directory"):
		passed = false
	if not _assert_true(loaded_tour.teams.has("India") and loaded_tour.teams["India"].points == 2, "Loaded tournament retains points"):
		passed = false
	if FileAccess.file_exists(TEST_TOURNAMENT_SAVE):
		DirAccess.remove_absolute(TEST_TOURNAMENT_SAVE)

	# Test 6: Offline Auction Initialization & Bidding Mechanics
	var auction := AuctionEngine.new()
	auction.initialize_auction("Delhi Titans")
	if not _assert_true(auction.teams.size() == 8, "Auction initializes with 8 franchise teams"):
		passed = false
	if not _assert_true(auction.player_pool.size() > 0, "Auction pool contains marquee players"):
		passed = false

	var first_p := auction.get_current_player()
	var user_team := auction.get_user_team()
	if not _assert_true(first_p != null and user_team != null, "Auction returns current player & user team"):
		passed = false

	# Test 7: User Bids & Purse Management
	var initial_purse := user_team.purse_cr
	var bid_placed := auction.place_user_bid()
	if not _assert_true(bid_placed, "User placed opening bid successfully"):
		passed = false
	if not _assert_true(first_p.highest_bidder == user_team.name, "User is now highest bidder"):
		passed = false

	# Test 8: CPU Counter-Bids & Sold Hammer Logic
	var cpu_bidder := auction.evaluate_cpu_bids()
	# CPU with 90+ rating will counter-bid
	if not _assert_true(not cpu_bidder.is_empty(), "CPU bot evaluated value and countered with higher bid"):
		passed = false
	if not _assert_true(first_p.current_bid_cr > first_p.base_price_cr, "Bid amount increased with competition"):
		passed = false

	var sold_ok := auction.hammer_down_sold()
	if not _assert_true(sold_ok, "Player sold under hammer"):
		passed = false
	if not _assert_true(auction.current_player_index == 1, "Auction progressed to next player"):
		passed = false

	# Test 9: Auction Local Persistence
	var save_auc_ok := auction.save_to_file(TEST_AUCTION_SAVE)
	if not _assert_true(save_auc_ok, "Auction state saved to user:// directory"):
		passed = false
	var loaded_auc := AuctionEngine.new()
	var load_auc_ok := loaded_auc.load_from_file(TEST_AUCTION_SAVE)
	if not _assert_true(load_auc_ok, "Auction state loaded from user:// directory"):
		passed = false
	if not _assert_true(loaded_auc.current_player_index == 1, "Loaded auction retains progression"):
		passed = false
	if FileAccess.file_exists(TEST_AUCTION_SAVE):
		DirAccess.remove_absolute(TEST_AUCTION_SAVE)

	return passed

func _assert_true(condition: bool, description: String) -> bool:
	if condition:
		print("  [PASS] %s" % description)
		return true
	else:
		printerr("  [FAIL] %s: Assertion failed" % description)
		return false
