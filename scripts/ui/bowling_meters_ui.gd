# BowlingMetersUI.gd - CricStrike 3D
# User Interface for Oscillating Swing/Seam and Pace Meters in Player Bowler Mode
class_name BowlingMetersUI
extends Control

signal confirm_spot_pressed()
signal lock_swing_pressed()
signal lock_speed_pressed()

const BowlingMeters = preload("res://scripts/bowling/bowling_meters.gd")

var meters_ref: BowlingMeters

# UI References
@onready var container: VBoxContainer = $Container
@onready var action_btn: Button = $Container/ActionButton
@onready var status_label: Label = $Container/StatusLabel
@onready var swing_bar: ProgressBar = $Container/SwingMeter/ProgressBar
@onready var speed_bar: ProgressBar = $Container/SpeedMeter/ProgressBar
@onready var swing_box: Control = $Container/SwingMeter
@onready var speed_box: Control = $Container/SpeedMeter

func _ready() -> void:
	if action_btn:
		action_btn.pressed.connect(_on_action_button_pressed)
	hide_meters()

func bind_meters(p_meters: BowlingMeters) -> void:
	meters_ref = p_meters

func show_aiming_step() -> void:
	visible = true
	if swing_box: swing_box.visible = false
	if speed_box: speed_box.visible = false
	if status_label: status_label.text = "Step 1: Drag marker to set Line & Length"
	if action_btn:
		action_btn.text = "CONFIRM SPOT"
		action_btn.visible = true

func show_swing_step() -> void:
	visible = true
	if swing_box: swing_box.visible = true
	if speed_box: speed_box.visible = false
	if status_label: status_label.text = "Step 2: Stop needle in GREEN zone for Maximum Swing"
	if action_btn:
		action_btn.text = "LOCK SWING"
		action_btn.visible = true

func show_speed_step() -> void:
	visible = true
	if swing_box: swing_box.visible = false
	if speed_box: speed_box.visible = true
	if status_label: status_label.text = "Step 3: Tap near PEAK for Express Pace!"
	if action_btn:
		action_btn.text = "RELEASE DELIVERY"
		action_btn.visible = true

func hide_meters() -> void:
	visible = false

func _process(_delta: float) -> void:
	if not visible or not meters_ref:
		return
		
	if meters_ref.current_state == BowlingMeters.MeterState.SWING_OSCILLATING and swing_bar:
		# Map swing from [-1.0, 1.0] to [0.0, 100.0]
		swing_bar.value = (meters_ref.swing_value + 1.0) * 50.0

	elif meters_ref.current_state == BowlingMeters.MeterState.SPEED_OSCILLATING and speed_bar:
		# Map speed position from [0.0, 1.0] to [0.0, 100.0]
		speed_bar.value = meters_ref.speed_meter_pos * 100.0
		if status_label:
			status_label.text = "Pace: %.1f km/h" % meters_ref.current_speed_kmh

func _on_action_button_pressed() -> void:
	if not meters_ref:
		return
		
	match meters_ref.current_state:
		BowlingMeters.MeterState.INACTIVE:
			confirm_spot_pressed.emit()
		BowlingMeters.MeterState.SWING_OSCILLATING:
			lock_swing_pressed.emit()
		BowlingMeters.MeterState.SPEED_OSCILLATING:
			lock_speed_pressed.emit()
