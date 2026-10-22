# test_ui_and_cinematics.gd - CricStrike 3D
# Verification of pause menu, locker room navigation, camera modes, and broadcast cinematics
class_name TestUIAndCinematics
extends RefCounted

func run_all_tests() -> bool:
	var passed: bool = true
	print("--- Running TestUIAndCinematics ---")
	
	# 1. Main Menu Scene
	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn")
	if not _assert_true(menu_scene != null, "main_menu.tscn loaded"):
		passed = false
	var menu_inst: Control = menu_scene.instantiate() as Control
	if not _assert_true(menu_inst.has_node("CenterContainer/MainHub/LockerRoomBtn"), "Main Menu has Locker Room button"):
		passed = false
	if not _assert_true(menu_inst.has_node("CenterContainer/MainHub/AssetDownloaderBtn"), "Main Menu has Asset Downloader button"):
		passed = false
	menu_inst.free()

	# 2. Locker Room Scene & Pedestal Athlete
	var locker_scene: PackedScene = load("res://scenes/locker_room.tscn")
	if not _assert_true(locker_scene != null, "locker_room.tscn loaded"):
		passed = false
	var locker_inst: Node3D = locker_scene.instantiate() as Node3D
	var athlete := locker_inst.get_node_or_null("CharacterModel")
	if not _assert_true(athlete != null and athlete.has_method("apply_profile"), "Locker Room has 3D athlete supporting profile updates"):
		passed = false
	var ui_node := locker_inst.get_node_or_null("CustomizationStudioUI")
	if not _assert_true(ui_node != null and ui_node.has_method("_on_back_pressed") and ui_node.has_method("_on_save_pressed"), "Customization Studio UI has back and save handlers"):
		passed = false
	locker_inst.free()

	# 3. Main Arena & In-Match Pause Menu
	var hud_scene: PackedScene = load("res://scenes/ui_hud.tscn")
	if not _assert_true(hud_scene != null, "ui_hud.tscn loaded"):
		passed = false
	var hud_inst: CanvasLayer = hud_scene.instantiate() as CanvasLayer
	var pause_btn := hud_inst.get_node_or_null("TopRightControls/PauseButton")
	var pause_menu := hud_inst.get_node_or_null("PauseMenu")
	if not _assert_true(pause_btn != null, "TopRightControls has PauseButton"):
		passed = false
	if not _assert_true(pause_menu != null and pause_menu.has_node("Center/Panel/Margin/VBox/ResumeBtn"), "PauseMenu has ResumeBtn"):
		passed = false
	if not _assert_true(pause_menu != null and pause_menu.has_node("Center/Panel/Margin/VBox/ExitMenuBtn"), "PauseMenu has ExitMenuBtn"):
		passed = false
	hud_inst.free()

	# 4. Broadcast Camera Modes
	var cam := BroadcastCamera.new()
	if not _assert_true(cam != null, "BroadcastCamera instantiated"):
		passed = false
	var modes := [
		BroadcastCamera.CameraMode.BEHIND_BATSMAN,
		BroadcastCamera.CameraMode.BROADCAST_SIDE,
		BroadcastCamera.CameraMode.BALL_TRACKING,
		BroadcastCamera.CameraMode.BOWLER_END,
		BroadcastCamera.CameraMode.UMPIRE_POV,
		BroadcastCamera.CameraMode.BATSMAN_HELMET_POV
	]
	var all_modes_ok := true
	for m in modes:
		cam.set_camera_mode(m)
		if cam.get_mode_name().is_empty():
			all_modes_ok = false
			break
	if not _assert_true(all_modes_ok, "All 6 Broadcast Camera modes (POV, Broadcast TV, Helmet, Ball Tracking) configured"):
		passed = false
	cam.free()

	return passed

func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		print("  [PASS] %s" % message)
		return true
	else:
		printerr("  [FAIL] %s" % message)
		return false
