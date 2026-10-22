# test_broadcast_replay.gd - CricStrike 3D
# Verification of 3-second multi-angle slow-motion TV replay system and skip button
class_name TestBroadcastReplay
extends RefCounted

const BroadcastCamera = preload("res://scripts/camera/broadcast_camera.gd")
const BroadcastReplayDirector = preload("res://scripts/camera/broadcast_replay_director.gd")
const BroadcastReplayOverlay = preload("res://scripts/ui/broadcast_replay_overlay.gd")

func run_all_tests() -> bool:
	var passed: bool = true
	print("--- Running TestBroadcastReplay ---")
	
	# 1. Instantiate Camera and Replay Director
	var cam := BroadcastCamera.new()
	var director := BroadcastReplayDirector.new()
	director.camera = cam
	
	if not _assert_true(director != null, "BroadcastReplayDirector instantiated"):
		passed = false
		
	# 2. Start Broadcast Replay
	var started_signal_received: bool = false
	var received_title: String = ""
	director.replay_started.connect(func(title: String, _detail: String):
		started_signal_received = true
		received_title = title
	)
	
	director.start_broadcast_replay("BOUNDARY 4!", "CRACKING SHOT")
	
	if not _assert_true(started_signal_received, "replay_started signal emitted on replay trigger"):
		passed = false
	if not _assert_true(received_title == "BOUNDARY 4!", "Replay title matches event"):
		passed = false
	if not _assert_true(director.is_replaying, "is_replaying is true during replay"):
		passed = false
	if not _assert_true(is_equal_approx(Engine.time_scale, 0.45), "Engine.time_scale set to 0.45 for slow-motion"):
		passed = false
	if not _assert_true(director.current_angle_index == 0, "Initial angle is Angle 0 (Pitch Delivery Cam)"):
		passed = false

	# 3. Angle Transition Logic Check
	var angle_changed_received: bool = false
	var received_angle_name: String = ""
	director.replay_angle_changed.connect(func(_idx: int, a_name: String):
		angle_changed_received = true
		received_angle_name = a_name
	)
	director._apply_replay_angle(1)
	if not _assert_true(angle_changed_received and received_angle_name == "Ultra Slow-Mo Impact Cam", "Angle changed to Ultra Slow-Mo Impact Cam"):
		passed = false

	# 4. Skip Replay Functionality
	var ended_signal_received: bool = false
	director.replay_ended.connect(func():
		ended_signal_received = true
	)
	director.skip_replay()
	
	if not _assert_true(ended_signal_received, "replay_ended signal emitted on skip_replay()"):
		passed = false
	if not _assert_true(not director.is_replaying, "is_replaying reset to false on skip"):
		passed = false
	if not _assert_true(is_equal_approx(Engine.time_scale, 1.0), "Engine.time_scale cleanly restored to 1.0 on skip"):
		passed = false

	# 5. Broadcast Replay Overlay Scene Verification
	var overlay_scene: PackedScene = load("res://scenes/broadcast_replay_overlay.tscn")
	if not _assert_true(overlay_scene != null, "broadcast_replay_overlay.tscn loaded"):
		passed = false
	var overlay: BroadcastReplayOverlay = overlay_scene.instantiate() as BroadcastReplayOverlay
	if not _assert_true(overlay.has_node("TopLeft/RecIndicator"), "Overlay has REC indicator"):
		passed = false
	if not _assert_true(overlay.has_node("SkipContainer/SkipButton"), "Overlay has prominent SkipButton"):
		passed = false
	if not _assert_true(overlay.has_node("BottomCenter/Panel/VBox/TitleLabel"), "Overlay has Replay TitleLabel"):
		passed = false
	if not _assert_true(overlay.has_node("BottomCenter/Panel/VBox/AngleLabel"), "Overlay has AngleLabel"):
		passed = false

	# Test Overlay Binding & Skip Signal
	overlay.bind_replay_director(director)
	overlay.show_replay("MAXIMUM 6!", "88m MONSTER SIX")
	if not _assert_true(overlay.visible, "Overlay visible when replay starts"):
		passed = false
	overlay._on_skip_pressed()
	if not _assert_true(not overlay.visible, "Overlay hidden when skip button is pressed"):
		passed = false

	overlay.free()
	cam.free()
	director.free()
	return passed

func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		print("  [PASS] %s" % message)
		return true
	else:
		printerr("  [FAIL] %s" % message)
		return false
