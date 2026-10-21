# WagonWheelView.gd - CricStrike 3D
# 360-Degree Radial Wagon Wheel Chart Visualizing All Scored Shots
class_name WagonWheelView
extends Control

const ScoreboardData = preload("res://scripts/match/scoreboard_data.gd")

var scoreboard_ref: ScoreboardData

@onready var close_btn: Button = $Panel/CloseButton
@onready var title_label: Label = $Panel/TitleLabel
@onready var stats_summary: Label = $Panel/StatsSummary
@onready var wheel_area: Control = $Panel/WheelArea

func _ready() -> void:
	if close_btn:
		close_btn.pressed.connect(func(): visible = false)
	if wheel_area:
		wheel_area.draw.connect(_on_wheel_draw)
	visible = false

func open_wagon_wheel(scoreboard: ScoreboardData) -> void:
	scoreboard_ref = scoreboard
	visible = true
	_update_summary()
	if wheel_area:
		wheel_area.queue_redraw()

func _update_summary() -> void:
	if not scoreboard_ref:
		return
	var off_runs: int = 0
	var leg_runs: int = 0
	var boundary_runs: int = 0
	
	for entry in scoreboard_ref.wagon_wheel_records:
		# Heading 0 to 180 is Off Side for RHB, 180 to 360 is Leg Side
		if entry.heading_deg <= 180.0:
			off_runs += entry.runs
		else:
			leg_runs += entry.runs
			
		if entry.runs in [4, 6]:
			boundary_runs += entry.runs
			
	if stats_summary:
		stats_summary.text = "Off Side: %d Runs | Leg Side: %d Runs | Boundaries: %d Runs" % [off_runs, leg_runs, boundary_runs]

func _on_wheel_draw() -> void:
	if not wheel_area or not scoreboard_ref:
		return
		
	var center := wheel_area.size * 0.5
	var radius := minf(center.x, center.y) - 15.0
	
	# Outfield grass circle
	wheel_area.draw_circle(center, radius, Color(0.12, 0.35, 0.15, 0.85))
	wheel_area.draw_arc(center, radius, 0, TAU, 64, Color(0.9, 0.6, 0.2), 3.0) # Boundary rope
	wheel_area.draw_arc(center, radius * 0.45, 0, TAU, 48, Color(1, 1, 1, 0.3), 1.5) # 30-yard circle
	
	# Pitch strip in center
	wheel_area.draw_rect(Rect2(center.x - 4, center.y - 18, 8, 36), Color(0.72, 0.65, 0.46))
	
	# Draw shot rays from striker crease
	var strike_origin := center + Vector2(0, 10)
	
	for entry in scoreboard_ref.wagon_wheel_records:
		var heading_rad := deg_to_rad(entry.heading_deg - 90.0) # Rotate so 0 deg is straight down
		var ray_len := clampf((entry.distance_m / 75.0) * radius, 15.0, radius)
		var end_point := strike_origin + Vector2(cos(heading_rad), sin(heading_rad)) * ray_len
		
		var line_color: Color
		var line_width: float = 2.0
		
		match entry.runs:
			1, 2, 3:
				line_color = Color(0.2, 0.6, 1.0, 0.85) # Blue for running runs
				line_width = 1.8
			4:
				line_color = Color(0.15, 0.95, 0.85, 0.95) # Cyan for 4s
				line_width = 2.6
			6:
				line_color = Color(1.0, 0.85, 0.15, 1.0) # Gold for 6s
				line_width = 3.4
			_:
				line_color = Color(0.7, 0.7, 0.7, 0.5)
				line_width = 1.2
				
		wheel_area.draw_line(strike_origin, end_point, line_color, line_width)
		wheel_area.draw_circle(end_point, line_width + 1.0, line_color)
