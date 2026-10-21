# GameConstants.gd - CricStrike 3D
# Centralized physical, gameplay and dimensional specifications for 3D Cricket
class_name GameConstants

# Pitch & Arena Dimensions (Meters)
const PITCH_LENGTH: float = 20.12 # 22 yards between bowling creases
const PITCH_WIDTH: float = 3.05
const POPPING_CREASE_OFFSET: float = 1.22 # Distance in front of bowling crease
const RETURN_CREASE_WIDTH: float = 2.64 # Total width of return crease box
const BOUNDARY_RADIUS_X: float = 68.0 # Standard stadium boundary oval radius X
const BOUNDARY_RADIUS_Z: float = 72.0 # Standard stadium boundary oval radius Z

# Stumps & Bails Dimensions (Meters)
const STUMP_HEIGHT: float = 0.711 # 28 inches
const STUMP_RADIUS: float = 0.017 # Approx 3.5 cm diameter
const STUMP_SPACING: float = 0.098 # Spacing between off-middle and middle-leg
const BAIL_LENGTH: float = 0.111 # Approx 4.375 inches
const BAIL_RADIUS: float = 0.007

# Ball Constants
const BALL_MASS_KG: float = 0.160 # Regulation 160g
const BALL_RADIUS_M: float = 0.036 # 7.2 cm diameter regulation ball
const AIR_DENSITY: float = 1.225 # kg / m^3
const DRAG_COEFFICIENT: float = 0.32 # Polished seam cricket ball drag
const GRAVITY: float = 9.81

# Ball Speeds (km/h converted to m/s: km/h / 3.6)
const SPEED_SPIN_MIN_KMH: float = 80.0
const SPEED_SPIN_MAX_KMH: float = 98.0
const SPEED_MEDIUM_KMH: float = 115.0
const SPEED_FAST_MAX_KMH: float = 152.0

# 8 Directional Sectors (in degrees, 0 = Straight down the pitch towards bowler Z < 0)
enum ShotDirection {
	STRAIGHT = 0,       # 0° (Up) - Straight Drive
	COVER = 1,          # 45° (Up-Left) - Cover Drive / Extra Cover
	POINT = 2,          # 90° (Left) - Square Cut / Point
	THIRD_MAN = 3,      # 135° (Down-Left) - Late Cut / Third Man
	BACKFOOT_DEF = 4,   # 180° (Down) - Backfoot Defense / Glance behind
	FINE_LEG = 5,       # 225° (Down-Right) - Hook / Leg Glance / Fine Leg
	SQUARE_LEG = 6,     # 270° (Right) - Pull Shot / Square Leg
	MID_WICKET = 7      # 315° (Up-Right) - On Drive / Cow Corner
}

# Elevation
enum ShotElevation {
	GROUNDED = 0,
	LOFTED = 1
}

# Timing Categories
enum TimingRating {
	PERFECT,
	EARLY,
	LATE,
	TOO_EARLY,
	TOO_LATE,
	MISSED,
	EDGE_OUTSIDE,
	EDGE_INSIDE
}

# Pitch Condition Types
enum PitchType {
	GREEN,
	DUSTY,
	FLAT,
	WET
}

# Difficulty Levels
enum Difficulty {
	EASY,
	MEDIUM,
	HARD,
	LEGEND
}

# Helper: Convert km/h to m/s
static func kmh_to_mps(kmh: float) -> float:
	return kmh / 3.6

# Helper: Convert m/s to km/h
static func mps_to_kmh(mps: float) -> float:
	return mps * 3.6
