# broadcast_replay_overlay.gd - CricStrike 3D
# TV broadcast replay graphics overlay with REC indicator, angle counter, and Skip button
class_name BroadcastReplayOverlay
extends Control

signal skip_pressed()

@onready var rec_indicator: Label = $TopLeft/RecIndicator
@onready var title_label: Label = $BottomCenter/Panel/VBox/TitleLabel
@onready var detail_label: Label = $BottomCenter/Panel/VBox/DetailLabel
@onready var angle_label: Label = $BottomCenter/Panel/VBox/AngleLabel
@onready var skip_btn: Button = $SkipContainer/SkipButton

var _blink_time: float = 0.0

func _ready() -> void:
	visible = false
	if skip_btn:
		skip_btn.pressed.connect(_on_skip_pressed)

func bind_replay_director(director: Node) -> void:
	if director == null:
		return
	if director.has_signal("replay_started"):
		director.replay_started.connect(show_replay)
	if director.has_signal("replay_angle_changed"):
		director.replay_angle_changed.connect(update_angle)
	if director.has_signal("replay_ended"):
		director.replay_ended.connect(hide_replay)
	skip_pressed.connect(func():
		if director.has_method("skip_replay"):
			director.skip_replay()
	)

func show_replay(title: String, detail: String = "") -> void:
	visible = true
	if title_label:
		title_label.text = "⚡ TV BROADCAST REPLAY - ULTRA SLOW-MO"
	if detail_label:
		detail_label.text = "%s %s" % [title, detail]
	if angle_label:
		angle_label.text = "ANGLE 1 / 3 [PITCH DELIVERY CAM]"
	set_process(true)

func update_angle(angle_num: int, angle_name: String) -> void:
	if angle_label:
		angle_label.text = "ANGLE %d / 3 [%s]" % [angle_num, angle_name.to_upper()]

func hide_replay() -> void:
	visible = false
	set_process(false)

func _on_skip_pressed() -> void:
	skip_pressed.emit()
	hide_replay()

func _process(delta: float) -> void:
	if not visible:
		return
	_blink_time += delta * 4.0
	if rec_indicator:
		# Blinking red dot recording effect
		rec_indicator.modulate.a = 0.3 + 0.7 * absf(sin(_blink_time))
