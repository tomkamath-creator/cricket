# TimingEngine.gd - CricStrike 3D
# Millisecond-accurate contact detection, sweetspot physics, exit velocity and launch angles
class_name TimingEngine
extends RefCounted

class TimingResult:
	var rating: GameConstants.TimingRating
	var delta_ms: float
	var exit_velocity: Vector3
	var exit_speed_kmh: float
	var launch_angle_deg: float
	var shot_name: String
	var is_edge: bool
	var feedback_text: String
	var rating_color: Color

	func _init() -> void:
		rating = GameConstants.TimingRating.MISSED
		delta_ms = 999.0
		exit_velocity = Vector3.ZERO
		exit_speed_kmh = 0.0
		launch_angle_deg = 0.0
		shot_name = "None"
		is_edge = false
		feedback_text = "MISSED"
		rating_color = Color(0.6, 0.6, 0.6)

# Difficulty thresholds [Perfect_ms, EarlyLate_ms, TooEarlyLate_ms]
static func get_difficulty_windows(diff: GameConstants.Difficulty) -> Dictionary:
	match diff:
		GameConstants.Difficulty.EASY:
			return {"perfect": 45.0, "normal": 95.0, "max": 160.0}
		GameConstants.Difficulty.MEDIUM:
			return {"perfect": 26.0, "normal": 62.0, "max": 115.0}
		GameConstants.Difficulty.HARD:
			return {"perfect": 16.0, "normal": 38.0, "max": 75.0}
		GameConstants.Difficulty.LEGEND:
			return {"perfect": 9.0,  "normal": 22.0, "max": 48.0}
	return {"perfect": 26.0, "normal": 62.0, "max": 115.0}

# Evaluate the shot when player hits the batting button
static func evaluate_contact(
	ball_pos: Vector3,
	ball_vel: Vector3,
	contact_plane_z: float,
	shot_data: ShotLibrary.ShotData,
	difficulty: GameConstants.Difficulty = GameConstants.Difficulty.MEDIUM,
	batsman_timing_delta_ms_override: float = 0.0,
	use_override: bool = false
) -> TimingResult:
	var result := TimingResult.new()
	result.shot_name = shot_data.name
	
	# Determine delta_ms between ideal strike zone and current ball location
	var delta_ms: float = 0.0
	if use_override:
		delta_ms = batsman_timing_delta_ms_override
	else:
		# If ball has no forward velocity toward batsman, missed
		if ball_vel.z <= 0.1:
			result.rating = GameConstants.TimingRating.MISSED
			result.feedback_text = "MISSED"
			return result
			
		# Distance to ideal strike plane along Z
		var dist_to_plane := contact_plane_z - ball_pos.z
		# Time in seconds to reach ideal contact plane: t = d / v_z
		var time_to_plane_sec := dist_to_plane / ball_vel.z
		delta_ms = time_to_plane_sec * 1000.0

	result.delta_ms = delta_ms
	var windows: Dictionary = get_difficulty_windows(difficulty)
	var win_perfect: float = float(windows["perfect"])
	var win_normal: float = float(windows["normal"])
	var win_max: float = float(windows["max"])
	var abs_delta: float = abs(delta_ms)
	
	# Lateral distance check (is the ball within reach of bat arc?)
	var lateral_offset: float = abs(ball_pos.x)
	if lateral_offset > 1.35 and not use_override:
		result.rating = GameConstants.TimingRating.MISSED
		result.feedback_text = "OUT OF REACH"
		result.rating_color = Color(0.7, 0.2, 0.2)
		return result

	# Check for edge / slice when reaching far outside off stump
	var is_outside_reach: bool = (lateral_offset > 0.75)
	
	# 1. PERFECT TIMING
	if abs_delta <= win_perfect:
		result.rating = GameConstants.TimingRating.PERFECT
		result.feedback_text = "PERFECT!"
		result.rating_color = Color(0.15, 0.95, 0.35) # Bright Emerald Green
		_calculate_exit_physics(result, ball_vel, shot_data, 1.0, 1.0, 0.0)
		return result

	# 2. EARLY (Hit in front of the body)
	if delta_ms < 0 and abs_delta <= win_normal:
		result.rating = GameConstants.TimingRating.EARLY
		result.feedback_text = "EARLY"
		result.rating_color = Color(0.95, 0.85, 0.2) # Yellow
		var power_drop := lerpf(0.92, 0.72, abs_delta / win_normal)
		var angle_shift := lerpf(0.0, 12.0, abs_delta / win_normal) # Leads to more elevation
		_calculate_exit_physics(result, ball_vel, shot_data, power_drop, 0.9, angle_shift)
		return result

	# 3. LATE (Hit behind the body)
	if delta_ms > 0 and abs_delta <= win_normal:
		result.rating = GameConstants.TimingRating.LATE
		result.feedback_text = "LATE"
		result.rating_color = Color(0.95, 0.55, 0.15) # Orange
		var power_drop := lerpf(0.90, 0.70, abs_delta / win_normal)
		var angle_shift := lerpf(0.0, -4.0, abs_delta / win_normal) # Stays down or squirts fine
		_calculate_exit_physics(result, ball_vel, shot_data, power_drop, 0.88, angle_shift)
		return result

	# 4. TOO EARLY (Leading edge / Skyer / Mistimed)
	if delta_ms < 0 and abs_delta <= win_max:
		result.rating = GameConstants.TimingRating.TOO_EARLY
		result.rating_color = Color(0.9, 0.25, 0.25) # Red
		if is_outside_reach or randf() < 0.4:
			result.is_edge = true
			result.feedback_text = "LEADING EDGE!"
			_calculate_edge_physics(result, ball_vel, shot_data, true)
		else:
			result.feedback_text = "TOO EARLY"
			_calculate_exit_physics(result, ball_vel, shot_data, 0.48, 0.65, 24.0) # Slices into the air
		return result

	# 5. TOO LATE (Outside edge / Inside chop on)
	if delta_ms > 0 and abs_delta <= win_max:
		result.rating = GameConstants.TimingRating.TOO_LATE
		result.rating_color = Color(0.9, 0.25, 0.25) # Red
		result.is_edge = true
		if ball_pos.x > 0.1:
			result.feedback_text = "OUTSIDE EDGE!"
			_calculate_edge_physics(result, ball_vel, shot_data, false)
		else:
			result.feedback_text = "INSIDE EDGE!"
			_calculate_chop_on_physics(result, ball_vel)
		return result

	# 6. MISSED
	result.rating = GameConstants.TimingRating.MISSED
	result.feedback_text = "BEATEN (MISSED)"
	result.rating_color = Color(0.5, 0.5, 0.5)
	return result

# Calculate clean bat strike exit velocity
static func _calculate_exit_physics(
	result: TimingResult,
	ball_vel: Vector3,
	shot_data: ShotLibrary.ShotData,
	power_factor: float,
	sweetspot_mult: float,
	elevation_offset_deg: float
) -> void:
	var incoming_speed := ball_vel.length()
	# Bat speed generated by batsman (typically 110 - 135 km/h equivalent bat speed)
	var bat_speed_mps := 32.0 * shot_data.power_multiplier * power_factor
	
	# CoR (Coefficient of Restitution of willow bat ~ 0.55)
	var cor := 0.55 * sweetspot_mult
	var exit_speed_mps := (incoming_speed * cor) + (bat_speed_mps * (1.0 + cor) * 0.45)
	result.exit_speed_kmh = GameConstants.mps_to_kmh(exit_speed_mps)
	
	# Heading calculation: 0 = Down pitch toward bowler (Z = -1)
	var heading_rad := deg_to_rad(shot_data.target_heading_deg)
	var launch_angle_rad := deg_to_rad(clamp(shot_data.base_launch_angle_deg + elevation_offset_deg, 1.0, 52.0))
	result.launch_angle_deg = rad_to_deg(launch_angle_rad)
	
	# Compose 3D velocity vector
	var horizontal_speed := exit_speed_mps * cos(launch_angle_rad)
	var vertical_speed := exit_speed_mps * sin(launch_angle_rad)
	
	# Note coordinate system: 0 deg points down pitch (-Z), 90 deg is +X (Leg side for right hander)
	var vx := horizontal_speed * sin(heading_rad)
	var vz := -horizontal_speed * cos(heading_rad)
	var vy := vertical_speed
	
	result.exit_velocity = Vector3(vx, vy, vz)

# Calculate edge fly to slips/gully/keeper
static func _calculate_edge_physics(result: TimingResult, ball_vel: Vector3, _shot_data: ShotLibrary.ShotData, is_leading: bool) -> void:
	var incoming_speed := ball_vel.length()
	var exit_speed_mps := incoming_speed * 0.72 # Pace deflection
	result.exit_speed_kmh = GameConstants.mps_to_kmh(exit_speed_mps)
	
	# Edges fly backward and slightly elevated
	var launch_angle := randf_range(16.0, 32.0)
	result.launch_angle_deg = launch_angle
	var launch_rad := deg_to_rad(launch_angle)
	
	var heading_deg := randf_range(125.0, 160.0) if is_leading else randf_range(195.0, 235.0)
	var heading_rad := deg_to_rad(heading_deg)
	
	var horiz := exit_speed_mps * cos(launch_rad)
	var vert := exit_speed_mps * sin(launch_rad)
	
	result.exit_velocity = Vector3(horiz * sin(heading_rad), vert, -horiz * cos(heading_rad))

# Calculate inside edge squirt or chop onto stumps
static func _calculate_chop_on_physics(result: TimingResult, ball_vel: Vector3) -> void:
	var incoming_speed := ball_vel.length()
	var exit_speed_mps := incoming_speed * 0.55
	result.exit_speed_kmh = GameConstants.mps_to_kmh(exit_speed_mps)
	result.launch_angle_deg = 2.0
	
	# Deflect towards stumps (Z > 0)
	var target_dir := Vector3(randf_range(-0.15, 0.15), -0.2, 0.95).normalized()
	result.exit_velocity = target_dir * exit_speed_mps
