# audio_manager.gd - CricStrike 3D
# Generates and plays procedural sound effects for real cricket broadcast impact:
# Bat strike crack, leather ball turf bounce, wooden stump rattle, and crowd roar/cheer
class_name AudioManager
extends Node

static var _instance: AudioManager

var sfx_bat_crack: AudioStreamWAV
var sfx_stump_rattle: AudioStreamWAV
var sfx_ball_bounce: AudioStreamWAV
var sfx_crowd_cheer: AudioStreamWAV

var _player_pool: Array[AudioStreamPlayer] = []
var _pool_size: int = 6

static func get_instance() -> AudioManager:
	return _instance

func _ready() -> void:
	_instance = self
	_generate_all_procedural_audio()
	_create_player_pool()

func _create_player_pool() -> void:
	for i in range(_pool_size):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_player_pool.append(player)

func _get_available_player() -> AudioStreamPlayer:
	for p in _player_pool:
		if not p.playing:
			return p
	return _player_pool[0]

func play_bat_crack(is_six: bool = false) -> void:
	var player := _get_available_player()
	player.stream = sfx_bat_crack
	player.pitch_scale = randf_range(0.95, 1.08)
	player.volume_db = 2.0 if is_six else 0.0
	player.play()
	if is_six:
		play_crowd_cheer(true)

func play_stump_rattle() -> void:
	var player := _get_available_player()
	player.stream = sfx_stump_rattle
	player.pitch_scale = randf_range(0.92, 1.05)
	player.volume_db = 3.0
	player.play()
	play_crowd_cheer(false)

func play_ball_bounce() -> void:
	var player := _get_available_player()
	player.stream = sfx_ball_bounce
	player.pitch_scale = randf_range(0.90, 1.10)
	player.volume_db = -2.0
	player.play()

func play_crowd_cheer(is_six: bool = false) -> void:
	var player := _get_available_player()
	player.stream = sfx_crowd_cheer
	player.pitch_scale = 1.05 if is_six else 0.95
	player.volume_db = 1.0 if is_six else -3.0
	player.play()

func _generate_all_procedural_audio() -> void:
	sfx_bat_crack = _create_bat_crack_stream()
	sfx_stump_rattle = _create_stump_rattle_stream()
	sfx_ball_bounce = _create_ball_bounce_stream()
	sfx_crowd_cheer = _create_crowd_cheer_stream()

func _create_bat_crack_stream() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.28
	var num_samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples)
	
	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		# Sharp acoustic impulse + wooden resonance (750Hz decaying rapidly)
		var env: float = exp(-t * 28.0)
		var tone: float = sin(t * 750.0 * TAU) * 0.5 + sin(t * 1450.0 * TAU) * 0.3
		var noise: float = (randf() * 2.0 - 1.0) * 0.45
		var sample_val: float = (tone + noise) * env
		var s8: int = clampi(int(sample_val * 127.0), -128, 127)
		data[i] = s8 & 0xFF
		
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _create_stump_rattle_stream() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.55
	var num_samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples)
	
	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		# Multi-wood click rattle (stumps + bails flying)
		var env: float = exp(-t * 8.5)
		var clack1: float = sin(t * 520.0 * TAU) * exp(-fposmod(t, 0.08) * 35.0)
		var clack2: float = sin(t * 880.0 * TAU) * exp(-fposmod(t + 0.03, 0.11) * 30.0)
		var sample_val: float = (clack1 * 0.6 + clack2 * 0.5) * env
		var s8: int = clampi(int(sample_val * 127.0), -128, 127)
		data[i] = s8 & 0xFF
		
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _create_ball_bounce_stream() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.14
	var num_samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples)
	
	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var env: float = exp(-t * 42.0)
		var thud: float = sin(t * 160.0 * TAU) * env
		var s8: int = clampi(int(thud * 127.0), -128, 127)
		data[i] = s8 & 0xFF
		
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _create_crowd_cheer_stream() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 1.8
	var num_samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples)
	
	var last_noise: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		# Crowd roar envelope: swell then slow fade
		var env: float = smoothstep(0.0, 0.25, t) * (1.0 - smoothstep(0.8, duration, t))
		# Lowpass pink noise for stadium crowd acoustic
		var white: float = randf() * 2.0 - 1.0
		last_noise = lerpf(last_noise, white, 0.12)
		var sample_val: float = last_noise * env * 0.75
		var s8: int = clampi(int(sample_val * 127.0), -128, 127)
		data[i] = s8 & 0xFF
		
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream
