# AuctionEngine.gd - CricStrike 3D
# Complete 100% offline player auction with budget management and competitive CPU bidding bots
class_name AuctionEngine
extends RefCounted

const SAVE_PATH: String = "user://auction_save.json"

class AuctionPlayer:
	var id: int
	var name: String
	var role: String # "Batsman", "Bowler", "All-Rounder", "Wicket-Keeper"
	var base_price_cr: float
	var rating: int # 70 - 99
	var current_bid_cr: float
	var highest_bidder: String = ""
	var is_sold: bool = false
	
	func _init(p_id: int, p_name: String, p_role: String, p_base: float, p_rating: int) -> void:
		id = p_id
		name = p_name
		role = p_role
		base_price_cr = p_base
		rating = p_rating
		current_bid_cr = p_base

	func to_dict() -> Dictionary:
		return {
			"id": id,
			"name": name,
			"role": role,
			"base_price_cr": base_price_cr,
			"rating": rating,
			"current_bid_cr": current_bid_cr,
			"highest_bidder": highest_bidder,
			"is_sold": is_sold
		}
		
	func from_dict(d: Dictionary) -> void:
		id = int(d.get("id", id))
		name = d.get("name", name)
		role = d.get("role", role)
		base_price_cr = float(d.get("base_price_cr", base_price_cr))
		rating = int(d.get("rating", rating))
		current_bid_cr = float(d.get("current_bid_cr", current_bid_cr))
		highest_bidder = d.get("highest_bidder", highest_bidder)
		is_sold = bool(d.get("is_sold", is_sold))

class FranchiseTeam:
	var name: String
	var purse_cr: float = 100.0 # 100 Crore starting purse
	var max_squad: int = 15
	var squad: Array[AuctionPlayer] = []
	var is_user: bool = false
	
	func _init(p_name: String, p_is_user: bool = false) -> void:
		name = p_name
		is_user = p_is_user

	func can_bid(amount_cr: float) -> bool:
		# Must retain enough purse to fill minimum remaining squad slots (base ~0.5 Cr each)
		var remaining_slots: int = max_squad - squad.size()
		if remaining_slots <= 0:
			return false
		var reserved: float = float(remaining_slots - 1) * 0.5
		return (purse_cr - amount_cr) >= reserved

	func to_dict() -> Dictionary:
		var sq_arr: Array = []
		for p in squad:
			sq_arr.append(p.to_dict())
		return {
			"name": name,
			"purse_cr": purse_cr,
			"is_user": is_user,
			"squad": sq_arr
		}
		
	func from_dict(d: Dictionary) -> void:
		name = d.get("name", name)
		purse_cr = float(d.get("purse_cr", purse_cr))
		is_user = bool(d.get("is_user", is_user))
		squad.clear()
		if d.has("squad"):
			for p_d in d["squad"]:
				var p := AuctionPlayer.new(0, "", "", 0.0, 0)
				p.from_dict(p_d)
				squad.append(p)

var teams: Array[FranchiseTeam] = []
var player_pool: Array[AuctionPlayer] = []
var current_player_index: int = 0

func initialize_auction(user_team_name: String = "Mumbai Titans") -> void:
	teams.clear()
	player_pool.clear()
	current_player_index = 0
	
	# 1. User Franchise
	teams.append(FranchiseTeam.new(user_team_name, true))
	
	# 2. CPU Franchises
	var cpu_names: Array[String] = [
		"Chennai Kings", "Bangalore Challengers", "Kolkata Knights",
		"Delhi Capitals", "Gujarat Lions", "Rajasthan Royals", "Hyderabad Hawks"
	]
	for c_name in cpu_names:
		teams.append(FranchiseTeam.new(c_name, false))
		
	# 3. Populate Star Auction Player Pool
	_populate_player_pool()

func _populate_player_pool() -> void:
	player_pool.append(AuctionPlayer.new(1, "Rohit Sharma", "Batsman", 2.0, 94))
	player_pool.append(AuctionPlayer.new(2, "Virat Kohli", "Batsman", 2.0, 96))
	player_pool.append(AuctionPlayer.new(3, "Jasprit Bumrah", "Bowler", 2.0, 97))
	player_pool.append(AuctionPlayer.new(4, "Hardik Pandya", "All-Rounder", 2.0, 91))
	player_pool.append(AuctionPlayer.new(5, "Heinrich Klaasen", "Wicket-Keeper", 1.5, 92))
	player_pool.append(AuctionPlayer.new(6, "Pat Cummins", "Bowler", 2.0, 93))
	player_pool.append(AuctionPlayer.new(7, "Travis Head", "Batsman", 2.0, 92))
	player_pool.append(AuctionPlayer.new(8, "Rashid Khan", "Bowler", 2.0, 95))
	player_pool.append(AuctionPlayer.new(9, "Nicholas Pooran", "Wicket-Keeper", 1.5, 89))
	player_pool.append(AuctionPlayer.new(10, "Mitchell Starc", "Bowler", 2.0, 92))
	player_pool.append(AuctionPlayer.new(11, "Jos Buttler", "Wicket-Keeper", 2.0, 93))
	player_pool.append(AuctionPlayer.new(12, "Andre Russell", "All-Rounder", 1.5, 90))

func get_current_player() -> AuctionPlayer:
	if current_player_index >= 0 and current_player_index < player_pool.size():
		return player_pool[current_player_index]
	return null

func get_user_team() -> FranchiseTeam:
	for t in teams:
		if t.is_user:
			return t
	return null

func place_user_bid() -> bool:
	var p := get_current_player()
	var u := get_user_team()
	if p == null or u == null or p.is_sold:
		return false
		
	var next_bid := calculate_next_bid_amount(p.current_bid_cr)
	if not u.can_bid(next_bid):
		return false
		
	p.current_bid_cr = next_bid
	p.highest_bidder = u.name
	return true

func calculate_next_bid_amount(current_bid: float) -> float:
	if current_bid < 2.0:
		return current_bid + 0.10
	elif current_bid < 5.0:
		return current_bid + 0.25
	elif current_bid < 10.0:
		return current_bid + 0.50
	else:
		return current_bid + 1.00

# CPU Bots AI: Each CPU bot evaluates value based on rating and willingness to spend
func evaluate_cpu_bids() -> String:
	var p := get_current_player()
	if p == null or p.is_sold:
		return ""
		
	var next_bid := calculate_next_bid_amount(p.current_bid_cr)
	var max_willingness: float = float(p.rating - 68) * 0.75 # e.g. 96 rating -> (28 * 0.75) = 21.0 Cr max
	
	# Filter CPU teams capable and interested
	var interested_teams: Array[FranchiseTeam] = []
	for t in teams:
		if not t.is_user and t.name != p.highest_bidder and t.can_bid(next_bid):
			if next_bid <= max_willingness:
				interested_teams.append(t)
				
	if interested_teams.is_empty():
		return "" # No CPU bids; ready to hammer down
		
	# Select one CPU bot at random among interested
	var bidder: FranchiseTeam = interested_teams.pick_random()
	p.current_bid_cr = next_bid
	p.highest_bidder = bidder.name
	return bidder.name

func hammer_down_sold() -> bool:
	var p := get_current_player()
	if p == null or p.is_sold:
		return false
		
	if p.highest_bidder.is_empty():
		# Unsold
		p.is_sold = true
		current_player_index += 1
		return false
		
	# Find winning franchise
	for t in teams:
		if t.name == p.highest_bidder:
			t.purse_cr -= p.current_bid_cr
			t.squad.append(p)
			p.is_sold = true
			break
			
	current_player_index += 1
	return true

func is_auction_complete() -> bool:
	return current_player_index >= player_pool.size()

func save_to_file(path: String = SAVE_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	var t_arr: Array = []
	for t in teams:
		t_arr.append(t.to_dict())
	var p_arr: Array = []
	for p in player_pool:
		p_arr.append(p.to_dict())
	var data := {
		"teams": t_arr,
		"player_pool": p_arr,
		"current_player_index": current_player_index
	}
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true

func load_from_file(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var content := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(content)
	if not (parsed is Dictionary):
		return false
	var d: Dictionary = parsed as Dictionary
	teams.clear()
	player_pool.clear()
	if d.has("teams"):
		for t_d in d["teams"]:
			var t := FranchiseTeam.new("")
			t.from_dict(t_d)
			teams.append(t)
	if d.has("player_pool"):
		for p_d in d["player_pool"]:
			var p := AuctionPlayer.new(0, "", "", 0.0, 0)
			p.from_dict(p_d)
			player_pool.append(p)
	current_player_index = int(d.get("current_player_index", 0))
	return true
