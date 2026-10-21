# AIBowler.gd - CricStrike 3D
# Advanced Offline AI Bowling Engine with 4 Difficulty Levels and Pitch Condition Adaptation
class_name AIBowler
extends RefCounted

const GameConstants = preload("res://scripts/core/game_constants.gd")
const BowlerTypes = preload("res://scripts/bowling/bowler_types.gd")
const PitchConditions = preload("res://scripts/core/pitch_conditions.gd")

var difficulty: GameConstants.Difficulty = GameConstants.Difficulty.MEDIUM
var bowling_style: BowlerTypes.BowlingStyle = BowlerTypes.BowlingStyle.RIGHT_ARM_FAST
var balls_bowled_in_spell: int = 0

# History tracking to avoid repetitive bowling and set up batsman traps
var _last_delivery_type: BowlerTypes.DeliveryType = BowlerTypes.DeliveryType.STANDARD_SEAM
var _last_pitch_zone: BowlerTypes.PitchLengthZone = BowlerTypes.PitchLengthZone.GOOD_LENGTH

func _init(diff: GameConstants.Difficulty = GameConstants.Difficulty.MEDIUM, style: BowlerTypes.BowlingStyle = BowlerTypes.BowlingStyle.RIGHT_ARM_FAST) -> void:
	difficulty = diff
	bowling_style = style

# Main AI Decision: Choose complete delivery configuration
func plan_next_delivery(pitch_cond: PitchConditions, batsman_is_rhb: bool = true) -> BowlerTypes.DeliveryConfig:
	balls_bowled_in_spell += 1
	var delivery := BowlerTypes.DeliveryConfig.new()
	
	match difficulty:
		GameConstants.Difficulty.EASY:
			_plan_easy_delivery(delivery, batsman_is_rhb)
		GameConstants.Difficulty.MEDIUM:
			_plan_medium_delivery(delivery, pitch_cond, batsman_is_rhb)
		GameConstants.Difficulty.HARD:
			_plan_hard_delivery(delivery, pitch_cond, batsman_is_rhb)
		GameConstants.Difficulty.LEGEND:
			_plan_legend_delivery(delivery, pitch_cond, batsman_is_rhb)
			
	_last_delivery_type = delivery.delivery_type
	_last_pitch_zone = BowlerTypes.categorize_length(delivery.target_pitch_pos.z)
	return delivery

# 1. EASY MODE: Predictable, gentle pace, marker visible throughout
func _plan_easy_delivery(del: BowlerTypes.DeliveryConfig, _is_rhb: bool) -> void:
	del.speed_kmh = randf_range(118.0, 126.0)
	del.swing_intensity = randf_range(-0.15, 0.15) # Barely any swing
	del.seam_deviation_deg = 0.0
	del.marker_fade_time_sec = 99.0 # Marker never fades
	
	# Friendly middle stump good length / full
	var length_z := randf_range(5.5, 7.2)
	var line_x := randf_range(-0.10, 0.10)
	del.target_pitch_pos = Vector3(line_x, 0.02, length_z)
	del.delivery_type = BowlerTypes.DeliveryType.STANDARD_SEAM

# 2. MEDIUM MODE: Balanced pace, authentic swing, marker visible until pitch
func _plan_medium_delivery(del: BowlerTypes.DeliveryConfig, pitch_cond: PitchConditions, is_rhb: bool) -> void:
	del.speed_kmh = randf_range(130.0, 138.0)
	del.marker_fade_time_sec = 1.6 # Stays visible until roughly pitch contact
	
	var roll := randf()
	if roll < 0.45:
		# Standard outswinger to 4th stump
		del.delivery_type = BowlerTypes.DeliveryType.OUTSWINGER
		del.swing_intensity = -0.55 if is_rhb else 0.55
		del.seam_deviation_deg = 1.2
		del.target_pitch_pos = Vector3(0.22 if is_rhb else -0.22, 0.02, randf_range(5.2, 6.4))
	elif roll < 0.80:
		# Inswinger attacking stumps
		del.delivery_type = BowlerTypes.DeliveryType.INSWINGER
		del.swing_intensity = 0.50 if is_rhb else -0.50
		del.seam_deviation_deg = -1.0
		del.target_pitch_pos = Vector3(-0.05 if is_rhb else 0.05, 0.02, randf_range(6.2, 7.5))
	else:
		# Occasional yorker or short ball
		if randf() < 0.5:
			del.delivery_type = BowlerTypes.DeliveryType.YORKER
			del.speed_kmh = 139.0
			del.swing_intensity = 0.2
			del.target_pitch_pos = Vector3(0.0, 0.02, 8.6)
		else:
			del.delivery_type = BowlerTypes.DeliveryType.BOUNCER
			del.speed_kmh = 135.0
			del.target_pitch_pos = Vector3(0.15, 0.02, 3.2)

# 3. HARD MODE: Strict timing, delayed fade, deceptive variations, pitch exploitation
func _plan_hard_delivery(del: BowlerTypes.DeliveryConfig, pitch_cond: PitchConditions, is_rhb: bool) -> void:
	del.marker_fade_time_sec = 0.65 # Fades midway through bowler approach
	
	# Exploit pitch conditions
	if pitch_cond.pitch_type == GameConstants.PitchType.GREEN:
		# Green top: Heavy seam on corridor of uncertainty (good length outside off)
		del.delivery_type = BowlerTypes.DeliveryType.OUTSWINGER
		del.speed_kmh = randf_range(138.0, 145.0)
		del.swing_intensity = -0.75 if is_rhb else 0.75
		del.seam_deviation_deg = randf_range(2.0, 3.2)
		del.target_pitch_pos = Vector3(0.28 if is_rhb else -0.28, 0.02, randf_range(4.8, 5.8))
		return
		
	elif pitch_cond.pitch_type == GameConstants.PitchType.DUSTY:
		# Dusty pitch: Sharp cutters / spin break
		del.delivery_type = BowlerTypes.DeliveryType.OFF_CUTTER
		del.speed_kmh = randf_range(118.0, 128.0)
		del.swing_intensity = 0.0
		del.seam_deviation_deg = -3.5 if is_rhb else 3.5
		del.target_pitch_pos = Vector3(0.18 if is_rhb else -0.18, 0.02, randf_range(5.2, 6.2))
		return

	# Standard Hard: Mix up variations to break batsman rhythm
	var roll := randf()
	if roll < 0.35:
		# Corridor of uncertainty outswinger (inducing edge)
		del.delivery_type = BowlerTypes.DeliveryType.OUTSWINGER
		del.speed_kmh = randf_range(140.0, 146.0)
		del.swing_intensity = -0.80 if is_rhb else 0.80
		del.seam_deviation_deg = 2.0
		del.target_pitch_pos = Vector3(0.32 if is_rhb else -0.32, 0.02, 5.2)
	elif roll < 0.65:
		# Fast Yorker at base of off stump
		del.delivery_type = BowlerTypes.DeliveryType.YORKER
		del.speed_kmh = randf_range(144.0, 149.0)
		del.swing_intensity = 0.30 if is_rhb else -0.30
		del.target_pitch_pos = Vector3(0.08 if is_rhb else -0.08, 0.02, 8.85)
	elif roll < 0.85:
		# Slower ball off-cutter (pace drop from 145 -> 114 km/h)
		del.delivery_type = BowlerTypes.DeliveryType.SLOWER_BALL
		del.speed_kmh = randf_range(112.0, 118.0)
		del.swing_intensity = 0.0
		del.seam_deviation_deg = 2.5
		del.target_pitch_pos = Vector3(0.20, 0.02, 6.5)
	else:
		# Rib-cage sharp bouncer
		del.delivery_type = BowlerTypes.DeliveryType.BOUNCER
		del.speed_kmh = randf_range(142.0, 147.0)
		del.target_pitch_pos = Vector3(-0.08 if is_rhb else 0.08, 0.02, 2.8)

# 4. LEGEND / PRO MODE: Ultra-fast marker fade, peak pace (148-152 km/h), lethal traps
func _plan_legend_delivery(del: BowlerTypes.DeliveryConfig, pitch_cond: PitchConditions, is_rhb: bool) -> void:
	del.marker_fade_time_sec = 0.18 # Fades almost instantly upon bowler release
	
	# If last ball was a bouncer, follow up with lethal toe-crusher yorker
	if _last_pitch_zone == BowlerTypes.PitchLengthZone.SHORT:
		del.delivery_type = BowlerTypes.DeliveryType.YORKER
		del.speed_kmh = randf_range(148.0, 152.0)
		del.swing_intensity = 0.40 if is_rhb else -0.40
		del.target_pitch_pos = Vector3(0.02 if is_rhb else -0.02, 0.02, 8.95)
		return

	# If last ball was a yorker, follow up with throat-clearing bouncer
	if _last_pitch_zone == BowlerTypes.PitchLengthZone.YORKER:
		del.delivery_type = BowlerTypes.DeliveryType.BOUNCER
		del.speed_kmh = randf_range(147.0, 151.0)
		del.target_pitch_pos = Vector3(0.12 if is_rhb else -0.12, 0.02, 2.4)
		return

	# Lethal setups: Reverse swing or off-stump snick
	var roll := randf()
	if roll < 0.40:
		# Reverse swing yorker / late inswinger at express pace
		del.delivery_type = BowlerTypes.DeliveryType.REVERSE_SWING
		del.speed_kmh = randf_range(148.0, 152.0)
		del.swing_intensity = 0.90 if is_rhb else -0.90
		del.seam_deviation_deg = -1.8
		del.target_pitch_pos = Vector3(0.05 if is_rhb else -0.05, 0.02, 8.8)
	elif roll < 0.75:
		# Unplayable outswinger pitching on middle and clipping top of off stump
		del.delivery_type = BowlerTypes.DeliveryType.OUTSWINGER
		del.speed_kmh = randf_range(146.0, 150.0)
		del.swing_intensity = -0.85 if is_rhb else 0.85
		del.seam_deviation_deg = 2.4
		del.target_pitch_pos = Vector3(0.10 if is_rhb else -0.10, 0.02, 5.4)
	else:
		# Deceptive knuckle ball slower yorker
		del.delivery_type = BowlerTypes.DeliveryType.SLOWER_BALL
		del.speed_kmh = randf_range(115.0, 120.0)
		del.swing_intensity = 0.10
		del.target_pitch_pos = Vector3(0.15, 0.02, 7.8)
