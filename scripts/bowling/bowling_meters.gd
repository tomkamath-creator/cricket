# BowlingMeters.gd - CricStrike 3D
# Oscillating swing/seam and speed meters with green sweetspot zones
class_name BowlingMeters
extends RefCounted

signal swing_evaluated(swing_intensity: float, is_sweetspot: bool, rating_text: String)
signal speed_evaluated(speed_kmh: float, is_sweetspot: bool, rating_text: String)

enum MeterState {
	INACTIVE,
	SWING_OSCILLATING,
	SPEED_OSCILLATING,
	COMPLETED
}

var current_state: MeterState = MeterState.INACTIVE

# Swing meter parameters (-1.0 to +1.0)
var swing_value: float = 0.0
var swing_target_sweetspot: float = 0.0 # Target sweetspot (e.g. 0.7 for heavy inswing, -0.7 for outswing)
var swing_sweetspot_width: float = 0.22
var swing_speed: float = 2.4 # Oscillations per second
var _swing_time: float = 0.0

# Speed meter parameters (110 to 152 km/h)
var min_speed_kmh: float = 110.0
var max_speed_kmh: float = 152.0
var current_speed_kmh: float = 135.0
var speed_meter_pos: float = 0.0 # 0.0 to 1.0
var speed_sweetspot_min: float = 0.78
var speed_sweetspot_max: float = 0.94
var speed_sweep_speed: float = 2.2 # Sweeps per second
var _speed_time: float = 0.0

# Final delivery results
var final_swing: float = 0.0
var final_speed_kmh: float = 135.0
var is_swing_perfect: bool = false
var is_speed_perfect: bool = false

func start_swing_meter(target_swing: float = 0.0, speed_multiplier: float = 1.0) -> void:
	current_state = MeterState.SWING_OSCILLATING
	swing_target_sweetspot = clampf(target_swing, -0.9, 0.9)
	swing_speed = 2.4 * speed_multiplier
	_swing_time = 0.0

func start_speed_meter(p_min_kmh: float = 110.0, p_max_kmh: float = 152.0, speed_multiplier: float = 1.0) -> void:
	current_state = MeterState.SPEED_OSCILLATING
	min_speed_kmh = p_min_kmh
	max_speed_kmh = p_max_kmh
	speed_sweep_speed = 2.2 * speed_multiplier
	_speed_time = 0.0

func update_process(delta: float) -> void:
	if current_state == MeterState.SWING_OSCILLATING:
		_swing_time += delta * swing_speed * TAU
		swing_value = sin(_swing_time) # Smooth oscillation between -1.0 and 1.0

	elif current_state == MeterState.SPEED_OSCILLATING:
		_speed_time += delta * speed_sweep_speed
		# Ping-pong between 0.0 and 1.0
		var cycle: float = fmod(_speed_time, 2.0)
		speed_meter_pos = cycle if cycle <= 1.0 else (2.0 - cycle)
		current_speed_kmh = lerpf(min_speed_kmh, max_speed_kmh, speed_meter_pos)

func lock_swing() -> Dictionary:
	if current_state != MeterState.SWING_OSCILLATING:
		return {"swing": 0.0, "sweetspot": false, "rating": "MISSED"}
		
	var diff: float = abs(swing_value - swing_target_sweetspot)
	var rating: String = "OK"
	
	if diff <= swing_sweetspot_width * 0.5:
		is_swing_perfect = true
		final_swing = swing_target_sweetspot
		rating = "PERFECT SWING!"
	elif diff <= swing_sweetspot_width:
		is_swing_perfect = false
		final_swing = swing_value * 0.8
		rating = "GOOD SWING"
	else:
		is_swing_perfect = false
		final_swing = swing_value * 0.4
		rating = "MISTIMED SWING"
		
	swing_evaluated.emit(final_swing, is_swing_perfect, rating)
	return {"swing": final_swing, "sweetspot": is_swing_perfect, "rating": rating}

func lock_speed() -> Dictionary:
	if current_state != MeterState.SPEED_OSCILLATING:
		return {"speed": min_speed_kmh, "sweetspot": false, "rating": "MISSED"}
		
	current_state = MeterState.COMPLETED
	current_speed_kmh = lerpf(min_speed_kmh, max_speed_kmh, speed_meter_pos)
	var rating := "OK"
	
	if speed_meter_pos >= speed_sweetspot_min and speed_meter_pos <= speed_sweetspot_max:
		is_speed_perfect = true
		final_speed_kmh = current_speed_kmh
		rating = "EXPRESS PACE!"
	elif speed_meter_pos > speed_sweetspot_max:
		# Overhit / effort ball (could result in slight line dispersion)
		is_speed_perfect = false
		final_speed_kmh = max_speed_kmh + randf_range(0.5, 2.5)
		rating = "OVERHIT PACE"
	else:
		is_speed_perfect = false
		final_speed_kmh = current_speed_kmh
		rating = "NORMAL PACE"
		
	speed_evaluated.emit(final_speed_kmh, is_speed_perfect, rating)
	return {"speed": final_speed_kmh, "sweetspot": is_speed_perfect, "rating": rating}

func reset() -> void:
	current_state = MeterState.INACTIVE
	swing_value = 0.0
	speed_meter_pos = 0.0
	_swing_time = 0.0
	_speed_time = 0.0
