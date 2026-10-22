# TestAssetDownloader.gd - CricStrike 3D
# Verification of post-install in-game HD asset downloader & dynamic PCK resource mounting
class_name TestAssetDownloader
extends RefCounted

const AssetDownloader = preload("res://scripts/core/asset_downloader.gd")

func run_all_tests() -> bool:
	var passed: bool = true
	print("--- Running TestAssetDownloader ---")
	
	var downloader := AssetDownloader.new()
	
	# Test 1: Available Packs Registry
	if not _assert_true(downloader.available_packs.size() >= 4, "Asset downloader registry has at least 4 HD expansion packs"):
		passed = false
		
	# Test 2: Pack metadata verification
	var stadium_pack := downloader.get_pack("stadiums_hd")
	if not _assert_true(stadium_pack != null and stadium_pack.size_mb > 50.0, "HD Stadiums pack has realistic size (> 50 MB)"):
		passed = false
		
	var commentary_pack := downloader.get_pack("commentary_audio")
	if not _assert_true(commentary_pack != null and commentary_pack.size_mb > 40.0, "Commentary Audio pack present with high quality audio size"):
		passed = false
		
	# Test 3: Pack installation state & simulated download
	var jersey_pack := downloader.get_pack("pro_jerseys")
	if not _assert_true(jersey_pack != null, "Pro Jerseys pack found in registry"):
		passed = false
	else:
		jersey_pack.is_installed = false
		var start_ok := downloader.start_download("pro_jerseys")
		if not _assert_true(start_ok, "Download started successfully"):
			passed = false
			
		# Advance simulated progress
		downloader._process(3.5)
		if not _assert_true(jersey_pack.is_installed, "Pack marked as installed after download completes"):
			passed = false
			
	# Test 4: Resource mounting
	var mount_ok := downloader.mount_pack("pro_jerseys")
	if not _assert_true(mount_ok, "Asset pack successfully mounts into Godot virtual filesystem"):
		passed = false
		
	# Test 5: Installed size calculation
	var total_mb := downloader.get_total_installed_size_mb()
	if not _assert_true(total_mb >= 38.0, "Total installed HD expansion size correctly tracked (>= 38 MB)"):
		passed = false
		
	downloader.free()
	return passed

func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		print("  [PASS] %s" % message)
		return true
	else:
		printerr("  [FAIL] %s" % message)
		return false
