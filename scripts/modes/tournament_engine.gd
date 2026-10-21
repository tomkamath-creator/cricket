# TournamentEngine.gd - CricStrike 3D
# Complete 8-team offline tournament engine: fixtures, points table, NRR, and knockout stages
class_name TournamentEngine
extends RefCounted

const SAVE_PATH: String = "user://tournament_save.json"

class TeamStats:
	var team_name: String
	var played: int = 0
	var won: int = 0
	var lost: int = 0
	var points: int = 0
	var runs_scored: int = 0
	var overs_faced: float = 0.0
	var runs_conceded: int = 0
	var overs_bowled: float = 0.0
	var nrr: float = 0.0
	
	func _init(p_name: String) -> void:
		team_name = p_name
		
	func calculate_nrr() -> void:
		var for_rate: float = (float(runs_scored) / overs_faced) if overs_faced > 0.0 else 0.0
		var against_rate: float = (float(runs_conceded) / overs_bowled) if overs_bowled > 0.0 else 0.0
		nrr = for_rate - against_rate
		
	func to_dict() -> Dictionary:
		return {
			"team_name": team_name,
			"played": played,
			"won": won,
			"lost": lost,
			"points": points,
			"runs_scored": runs_scored,
			"overs_faced": overs_faced,
			"runs_conceded": runs_conceded,
			"overs_bowled": overs_bowled,
			"nrr": nrr
		}
		
	func from_dict(d: Dictionary) -> void:
		team_name = d.get("team_name", team_name)
		played = int(d.get("played", played))
		won = int(d.get("won", won))
		lost = int(d.get("lost", lost))
		points = int(d.get("points", points))
		runs_scored = int(d.get("runs_scored", runs_scored))
		overs_faced = float(d.get("overs_faced", overs_faced))
		runs_conceded = int(d.get("runs_conceded", runs_conceded))
		overs_bowled = float(d.get("overs_bowled", overs_bowled))
		nrr = float(d.get("nrr", nrr))

class Fixture:
	var id: int
	var team_a: String
	var team_b: String
	var completed: bool = false
	var winner: String = ""
	var stage: String = "Group" # "Group", "Semi-Final 1", "Semi-Final 2", "Final"
	
	func _init(p_id: int, a: String, b: String, p_stage: String = "Group") -> void:
		id = p_id
		team_a = a
		team_b = b
		stage = p_stage

	func to_dict() -> Dictionary:
		return {
			"id": id,
			"team_a": team_a,
			"team_b": team_b,
			"completed": completed,
			"winner": winner,
			"stage": stage
		}
		
	func from_dict(d: Dictionary) -> void:
		id = int(d.get("id", id))
		team_a = d.get("team_a", team_a)
		team_b = d.get("team_b", team_b)
		completed = bool(d.get("completed", completed))
		winner = d.get("winner", winner)
		stage = d.get("stage", stage)

const DEFAULT_TEAMS: Array[String] = [
	"India", "Australia", "England", "South Africa",
	"New Zealand", "Pakistan", "West Indies", "Sri Lanka"
]

var teams: Dictionary = {} # String team_name -> TeamStats
var fixtures: Array[Fixture] = []
var current_fixture_index: int = 0
var tournament_winner: String = ""

func initialize_tournament(team_names: Array[String] = DEFAULT_TEAMS) -> void:
	teams.clear()
	fixtures.clear()
	current_fixture_index = 0
	tournament_winner = ""
	
	for t_name in team_names:
		teams[t_name] = TeamStats.new(t_name)
		
	# Generate Single Round-Robin Group Fixtures
	var f_id: int = 1
	for i in range(team_names.size()):
		for j in range(i + 1, team_names.size()):
			fixtures.append(Fixture.new(f_id, team_names[i], team_names[j], "Group"))
			f_id += 1

func record_match_result(fixture_id: int, winner: String, loser: String, runs_w: int, overs_w: float, runs_l: int, overs_l: float) -> void:
	for f in fixtures:
		if f.id == fixture_id:
			f.completed = true
			f.winner = winner
			break
			
	if teams.has(winner):
		var w_stats: TeamStats = teams[winner]
		w_stats.played += 1
		w_stats.won += 1
		w_stats.points += 2
		w_stats.runs_scored += runs_w
		w_stats.overs_faced += overs_w
		w_stats.runs_conceded += runs_l
		w_stats.overs_bowled += overs_l
		w_stats.calculate_nrr()
		
	if teams.has(loser):
		var l_stats: TeamStats = teams[loser]
		l_stats.played += 1
		l_stats.lost += 1
		l_stats.runs_scored += runs_l
		l_stats.overs_faced += overs_l
		l_stats.runs_conceded += runs_w
		l_stats.overs_bowled += overs_w
		l_stats.calculate_nrr()

func get_standings() -> Array[TeamStats]:
	var list: Array[TeamStats] = []
	for key in teams:
		list.append(teams[key])
		
	list.sort_custom(func(a: TeamStats, b: TeamStats) -> bool:
		if a.points != b.points:
			return a.points > b.points
		return a.nrr > b.nrr
	)
	return list

func are_group_matches_complete() -> bool:
	for f in fixtures:
		if f.stage == "Group" and not f.completed:
			return false
	return true

func setup_knockouts() -> void:
	var standings := get_standings()
	if standings.size() < 4:
		return
		
	# Semi-Final 1: 1st vs 4th
	fixtures.append(Fixture.new(1001, standings[0].team_name, standings[3].team_name, "Semi-Final 1"))
	# Semi-Final 2: 2nd vs 3rd
	fixtures.append(Fixture.new(1002, standings[1].team_name, standings[2].team_name, "Semi-Final 2"))

func setup_final(winner_sf1: String, winner_sf2: String) -> void:
	fixtures.append(Fixture.new(2001, winner_sf1, winner_sf2, "Final"))

func save_to_file(path: String = SAVE_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
		
	var teams_dict: Dictionary = {}
	for k in teams:
		teams_dict[k] = (teams[k] as TeamStats).to_dict()
		
	var fix_arr: Array = []
	for f in fixtures:
		fix_arr.append(f.to_dict())
		
	var data := {
		"teams": teams_dict,
		"fixtures": fix_arr,
		"current_fixture_index": current_fixture_index,
		"tournament_winner": tournament_winner
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
	fixtures.clear()
	
	if d.has("teams"):
		var t_data: Dictionary = d["teams"]
		for k in t_data:
			var ts := TeamStats.new(k)
			ts.from_dict(t_data[k])
			teams[k] = ts
			
	if d.has("fixtures"):
		var f_data: Array = d["fixtures"]
		for item in f_data:
			var fix := Fixture.new(0, "", "")
			fix.from_dict(item)
			fixtures.append(fix)
			
	current_fixture_index = int(d.get("current_fixture_index", 0))
	tournament_winner = d.get("tournament_winner", "")
	return true
