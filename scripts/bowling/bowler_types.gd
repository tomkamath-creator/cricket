# BowlerTypes.gd - CricStrike 3D
# Enumerations and data models for bowling styles, delivery types, and delivery parameters
class_name BowlerTypes

enum BowlingStyle {
	RIGHT_ARM_FAST,
	LEFT_ARM_FAST,
	RIGHT_ARM_MEDIUM,
	RIGHT_ARM_OFF_SPIN,
	RIGHT_ARM_LEG_SPIN,
	LEFT_ARM_ORTHODOX
}

enum DeliveryType {
	STANDARD_SEAM,
	OUTSWINGER,
	INSWINGER,
	REVERSE_SWING,
	SLOWER_BALL,
	OFF_CUTTER,
	LEG_CUTTER,
	YORKER,
	BOUNCER,
	OFF_BREAK,
	DOOSRA,
	LEG_BREAK,
	GOOGLY,
	FLIPPER
}

enum PitchLengthZone {
	YORKER,     # 8.0m to 9.5m (right at the popping crease / batsman's toes)
	FULL,       # 6.5m to 8.0m (driving length)
	GOOD_LENGTH,# 4.5m to 6.5m (indecision zone, edges and seams)
	SHORT       # 1.5m to 4.5m (pulls, hooks, bouncers)
}

class DeliveryConfig:
	var delivery_type: DeliveryType
	var speed_kmh: float
	var swing_intensity: float # -1.0 to 1.0 (negative = away/outswing, positive = into batsman)
	var seam_deviation_deg: float # Lateral cut upon pitching
	var spin_vector: Vector3 # For spin bowlers
	var target_pitch_pos: Vector3
	var marker_fade_time_sec: float # How quickly the target marker fades based on difficulty
	var name: String

	func _init(p_type: DeliveryType = DeliveryType.STANDARD_SEAM, p_speed: float = 135.0, p_swing: float = 0.0, p_seam: float = 0.0, p_target: Vector3 = Vector3.ZERO) -> void:
		delivery_type = p_type
		speed_kmh = p_speed
		swing_intensity = p_swing
		seam_deviation_deg = p_seam
		spin_vector = Vector3.ZERO
		target_pitch_pos = p_target
		marker_fade_time_sec = 1.5
		name = BowlerTypes.get_delivery_name(p_type)

static func get_delivery_name(type: DeliveryType) -> String:
	match type:
		DeliveryType.STANDARD_SEAM: return "Straight Seam"
		DeliveryType.OUTSWINGER:    return "Outswinger"
		DeliveryType.INSWINGER:     return "Inswinger"
		DeliveryType.REVERSE_SWING: return "Reverse Swing"
		DeliveryType.SLOWER_BALL:   return "Deceptive Slower Ball"
		DeliveryType.OFF_CUTTER:    return "Off-Cutter"
		DeliveryType.LEG_CUTTER:    return "Leg-Cutter"
		DeliveryType.YORKER:        return "Toe-Crusher Yorker"
		DeliveryType.BOUNCER:       return "Sharp Bouncer"
		DeliveryType.OFF_BREAK:     return "Off-Break"
		DeliveryType.DOOSRA:        return "Doosra"
		DeliveryType.LEG_BREAK:     return "Leg-Break"
		DeliveryType.GOOGLY:        return "Googly"
		DeliveryType.FLIPPER:       return "Flipper"
	return "Standard"

static func categorize_length(pitch_z: float) -> PitchLengthZone:
	if pitch_z >= 8.2:
		return PitchLengthZone.YORKER
	elif pitch_z >= 6.5:
		return PitchLengthZone.FULL
	elif pitch_z >= 4.5:
		return PitchLengthZone.GOOD_LENGTH
	else:
		return PitchLengthZone.SHORT

static func get_length_name(zone: PitchLengthZone) -> String:
	match zone:
		PitchLengthZone.YORKER:      return "Yorker"
		PitchLengthZone.FULL:        return "Full Length"
		PitchLengthZone.GOOD_LENGTH: return "Good Length"
		PitchLengthZone.SHORT:       return "Short / Bouncer"
	return "Length"
