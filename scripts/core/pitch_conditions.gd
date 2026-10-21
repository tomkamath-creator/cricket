# PitchConditions.gd - CricStrike 3D
# Handles surface friction, bounce restitution, seam deviation and spin bite
class_name PitchConditions

var pitch_type: GameConstants.PitchType = GameConstants.PitchType.FLAT

# Physics parameters influenced by pitch condition
var restitution: float = 0.78       # Bounce coefficient (e)
var friction: float = 0.40          # Tangential friction on pitch impact
var seam_factor: float = 1.0        # Multiplier for lateral deviation off seam
var spin_grip: float = 1.0          # Angular velocity transfer to linear grip
var skid_factor: float = 1.0        # Tendency to skid through lower and quicker
var swing_multiplier: float = 1.0   # Atmospheric interaction modifier

# Visual attributes
var surface_color: Color = Color(0.72, 0.65, 0.45) # Natural clay/grass mix
var roughness: float = 0.7

func _init(type: GameConstants.PitchType = GameConstants.PitchType.FLAT) -> void:
	apply_pitch_type(type)

func apply_pitch_type(type: GameConstants.PitchType) -> void:
	pitch_type = type
	match type:
		GameConstants.PitchType.GREEN:
			# High bounce, heavy seam movement, extra swing in damp air
			restitution = 0.82
			friction = 0.48
			seam_factor = 1.45
			spin_grip = 0.85
			skid_factor = 0.95
			swing_multiplier = 1.35
			surface_color = Color(0.38, 0.55, 0.28)
			roughness = 0.55

		GameConstants.PitchType.DUSTY:
			# Lower bounce, heavy friction, huge spin grip and abrasive break
			restitution = 0.64
			friction = 0.65
			seam_factor = 0.85
			spin_grip = 1.55
			skid_factor = 0.80
			swing_multiplier = 0.90
			surface_color = Color(0.76, 0.68, 0.48)
			roughness = 0.85

		GameConstants.PitchType.FLAT:
			# Batting paradise: true bounce, consistent pace, low lateral deviation
			restitution = 0.80
			friction = 0.35
			seam_factor = 0.80
			spin_grip = 0.90
			skid_factor = 1.05
			swing_multiplier = 1.00
			surface_color = Color(0.78, 0.72, 0.54)
			roughness = 0.45

		GameConstants.PitchType.WET:
			# Skidding through, low unpredictable bounce, low spin bite
			restitution = 0.58
			friction = 0.25
			seam_factor = 1.10
			spin_grip = 0.60
			skid_factor = 1.40
			swing_multiplier = 1.15
			surface_color = Color(0.48, 0.42, 0.32)
			roughness = 0.30

# Calculate post-pitch velocity vector given incoming velocity, spin, and seam angle
func calculate_pitch_bounce(incoming_velocity: Vector3, spin: Vector3, seam_angle_rad: float) -> Vector3:
	var out_vel := incoming_velocity
	
	# Normal bounce (Y-axis) scaled by restitution
	out_vel.y = abs(incoming_velocity.y) * restitution
	
	# Tangential forward deceleration (Z-axis)
	var forward_retention := (1.0 - friction * 0.15) * skid_factor
	out_vel.z *= clamp(forward_retention, 0.65, 0.96)
	
	# Lateral seam deviation (X-axis)
	var seam_kick := sin(seam_angle_rad) * seam_factor * 1.8
	out_vel.x += seam_kick
	
	# Spin grip effect (X-axis kick from spin vector Y)
	var spin_kick := spin.y * spin_grip * 0.08
	out_vel.x += spin_kick
	
	return out_vel

func get_pitch_name() -> String:
	match pitch_type:
		GameConstants.PitchType.GREEN: return "Green Top (Fast & Seamy)"
		GameConstants.PitchType.DUSTY: return "Dusty / Cracking (Turn & Grip)"
		GameConstants.PitchType.FLAT: return "Flat Road (Batters Paradise)"
		GameConstants.PitchType.WET: return "Damp / Wet (Skiddy & Low)"
	return "Standard"
