# ShotLibrary.gd - CricStrike 3D
# Complete database of 8-way cricket shots, elevation profiles, launch angles and trajectories
class_name ShotLibrary

class ShotData:
	var name: String
	var direction_enum: GameConstants.ShotDirection
	var elevation: GameConstants.ShotElevation
	var target_heading_deg: float # Heading in degrees (0 = Straight toward bowler, 180 = Behind batsman)
	var base_launch_angle_deg: float # Elevation angle above turf
	var power_multiplier: float
	var sweetspot_window_ms: float # Tolerance window around perfect timing
	var bat_arc_angle_deg: float # Bat blade rotation angle during strike
	var description: String

	func _init(p_name: String, p_dir: GameConstants.ShotDirection, p_elev: GameConstants.ShotElevation, p_heading: float, p_launch: float, p_power: float, p_sweetspot: float, p_bat_arc: float, p_desc: String) -> void:
		name = p_name
		direction_enum = p_dir
		elevation = p_elev
		target_heading_deg = p_heading
		base_launch_angle_deg = p_launch
		power_multiplier = p_power
		sweetspot_window_ms = p_sweetspot
		bat_arc_angle_deg = p_bat_arc
		description = p_desc

static var _shots: Dictionary = {}

static func _initialize_shots() -> void:
	if not _shots.is_empty():
		return
		
	# Grounded Shots (0 - 8 degrees launch angle)
	_add(ShotData.new("Straight Drive", GameConstants.ShotDirection.STRAIGHT, GameConstants.ShotElevation.GROUNDED, 180.0, 4.0, 1.25, 30.0, 0.0, "Classic high-elbow textbook drive down the ground."))
	_add(ShotData.new("Cover Drive", GameConstants.ShotDirection.COVER, GameConstants.ShotElevation.GROUNDED, 225.0, 5.0, 1.20, 28.0, 45.0, "Elegant drive through the covers."))
	_add(ShotData.new("Square Cut", GameConstants.ShotDirection.POINT, GameConstants.ShotElevation.GROUNDED, 270.0, 4.0, 1.15, 25.0, 90.0, "Sharp slash piercing backward point and cover point."))
	_add(ShotData.new("Late Cut", GameConstants.ShotDirection.THIRD_MAN, GameConstants.ShotElevation.GROUNDED, 315.0, 3.0, 1.05, 22.0, 135.0, "Delicate guide using pace towards third man."))
	_add(ShotData.new("Backfoot Defense", GameConstants.ShotDirection.BACKFOOT_DEF, GameConstants.ShotElevation.GROUNDED, 0.0, 1.0, 0.40, 35.0, 180.0, "Solid dead-bat block dropping right at the feet."))
	_add(ShotData.new("Leg Glance", GameConstants.ShotDirection.FINE_LEG, GameConstants.ShotElevation.GROUNDED, 45.0, 4.0, 1.10, 24.0, 225.0, "Wristy deflection off the pads fine down the leg side."))
	_add(ShotData.new("Square Leg Glance", GameConstants.ShotDirection.SQUARE_LEG, GameConstants.ShotElevation.GROUNDED, 90.0, 6.0, 1.20, 26.0, 270.0, "Turned firmly off the hips towards backward square."))
	_add(ShotData.new("On Drive", GameConstants.ShotDirection.MID_WICKET, GameConstants.ShotElevation.GROUNDED, 135.0, 5.0, 1.25, 28.0, 315.0, "Crisp punch straight past mid-on."))

	# Lofted Shots (22 - 34 degrees launch angle for maximum power and distance)
	_add(ShotData.new("Lofted Straight Drive", GameConstants.ShotDirection.STRAIGHT, GameConstants.ShotElevation.LOFTED, 180.0, 28.0, 1.55, 24.0, 0.0, "Towering hit high over the sight screen."))
	_add(ShotData.new("Inside-Out Lofted Cover", GameConstants.ShotDirection.COVER, GameConstants.ShotElevation.LOFTED, 225.0, 29.0, 1.50, 22.0, 45.0, "Spectacular aerial chip over extra cover."))
	_add(ShotData.new("Upper Cut", GameConstants.ShotDirection.POINT, GameConstants.ShotElevation.LOFTED, 270.0, 32.0, 1.45, 20.0, 90.0, "High slash sailing over the point boundary."))
	_add(ShotData.new("Ramp / Scoop", GameConstants.ShotDirection.THIRD_MAN, GameConstants.ShotElevation.LOFTED, 325.0, 35.0, 1.35, 18.0, 140.0, "Cheeky paddle scoop soaring over keeper's head."))
	_add(ShotData.new("Helicopter Shot", GameConstants.ShotDirection.BACKFOOT_DEF, GameConstants.ShotElevation.LOFTED, 170.0, 30.0, 1.60, 22.0, 175.0, "High-torque wrist snap launching the yorker into the stands."))
	_add(ShotData.new("Hook Shot", GameConstants.ShotDirection.FINE_LEG, GameConstants.ShotElevation.LOFTED, 40.0, 33.0, 1.50, 20.0, 230.0, "Aggressive top-edge hook over fine leg rope."))
	_add(ShotData.new("Pull Shot", GameConstants.ShotDirection.SQUARE_LEG, GameConstants.ShotElevation.LOFTED, 85.0, 26.0, 1.58, 24.0, 270.0, "Massive swat dispatching the short ball over mid-wicket."))
	_add(ShotData.new("Slog Sweep", GameConstants.ShotDirection.MID_WICKET, GameConstants.ShotElevation.LOFTED, 130.0, 31.0, 1.55, 22.0, 315.0, "Brutal kneeling slog sending the ball deep into the tiers."))

static func _add(shot: ShotData) -> void:
	var key := _get_key(shot.direction_enum, shot.elevation)
	_shots[key] = shot

static func _get_key(dir: GameConstants.ShotDirection, elev: GameConstants.ShotElevation) -> String:
	return "%d_%d" % [dir, elev]

static func get_shot(dir: GameConstants.ShotDirection, elev: GameConstants.ShotElevation) -> ShotData:
	_initialize_shots()
	var key := _get_key(dir, elev)
	if _shots.has(key):
		return _shots[key]
	# Fallback to straight drive
	return _shots[_get_key(GameConstants.ShotDirection.STRAIGHT, elev)]

static func vector_to_direction(joystick_vector: Vector2) -> GameConstants.ShotDirection:
	if joystick_vector.length() < 0.2:
		return GameConstants.ShotDirection.STRAIGHT # Default forward
		
	# Joystick: Y is typically negative for Up, positive for Down
	# Screen space: Up = (0, -1), Right = (1, 0), Down = (0, 1), Left = (-1, 0)
	var angle_rad := atan2(joystick_vector.y, joystick_vector.x)
	var angle_deg := rad_to_deg(angle_rad)
	if angle_deg < 0:
		angle_deg += 360.0
		
	# Sector mapping:
	# -90 deg / 270 deg is UP
	# Rotate so UP is 0 deg
	var normalized_angle := fposmod(angle_deg + 90.0, 360.0)
	var sector := int(round(normalized_angle / 45.0)) % 8
	
	match sector:
		0: return GameConstants.ShotDirection.STRAIGHT       # Up (Straight Drive)
		1: return GameConstants.ShotDirection.MID_WICKET     # Up-Right (On-drive)
		2: return GameConstants.ShotDirection.SQUARE_LEG     # Right (Pull / Square Leg)
		3: return GameConstants.ShotDirection.FINE_LEG       # Down-Right (Fine Leg)
		4: return GameConstants.ShotDirection.BACKFOOT_DEF   # Down (Backfoot Defense)
		5: return GameConstants.ShotDirection.THIRD_MAN      # Down-Left (Late cut / Third man)
		6: return GameConstants.ShotDirection.POINT          # Left (Cut / Point)
		7: return GameConstants.ShotDirection.COVER          # Up-Left (Cover Drive)
	return GameConstants.ShotDirection.STRAIGHT
