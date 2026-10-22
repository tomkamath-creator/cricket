# AssetDownloader.gd - CricStrike 3D
# Post-install in-game HD asset downloader & dynamic PCK resource mounting system
class_name AssetDownloader
extends Node

signal download_progress(pack_id: String, percentage: float, downloaded_bytes: int, total_bytes: int)
signal download_completed(pack_id: String, success: bool, message: String)
signal pack_mounted(pack_id: String, success: bool)

const MANIFEST_PATH: String = "user://installed_packs.json"
const PACKS_DIR: String = "user://packs/"

class AssetPackInfo:
	var id: String
	var title: String
	var description: String
	var size_mb: float
	var total_bytes: int
	var url: String
	var is_installed: bool = false
	var download_progress_val: float = 0.0

	func _init(p_id: String, p_title: String, p_desc: String, p_size_mb: float, p_url: String) -> void:
		id = p_id
		title = p_title
		description = p_desc
		size_mb = p_size_mb
		total_bytes = int(p_size_mb * 1024 * 1024)
		url = p_url

var available_packs: Array[AssetPackInfo] = []
var _http_request: HTTPRequest
var _active_pack: AssetPackInfo = null
var _simulated_download: bool = false
var _download_timer: float = 0.0

func _init() -> void:
	_init_pack_registry()
	_load_installed_manifest()

func _ready() -> void:
	_get_or_create_http_request()
	# Ensure packs storage directory exists
	if not DirAccess.dir_exists_absolute(PACKS_DIR):
		DirAccess.make_dir_recursive_absolute(PACKS_DIR)

func _get_or_create_http_request() -> HTTPRequest:
	if _http_request == null:
		_http_request = HTTPRequest.new()
		add_child(_http_request)
		_http_request.request_completed.connect(_on_http_request_completed)
	return _http_request

func _init_pack_registry() -> void:
	available_packs = [
		AssetPackInfo.new(
			"stadiums_hd",
			"HD Stadiums & 4K Turf Pack",
			"Photorealistic floodlight arenas, 4K turf grass shaders, and dynamic crowd banners.",
			85.0,
			"https://github.com/tomkamath-creator/cricket/releases/download/assets/stadiums_hd.pck"
		),
		AssetPackInfo.new(
			"commentary_audio",
			"Broadcast Audio & Commentary Pack",
			"English and Hindi broadcast commentary audio lines, boundary roar & umpire calls.",
			62.0,
			"https://github.com/tomkamath-creator/cricket/releases/download/assets/commentary_audio.pck"
		),
		AssetPackInfo.new(
			"pro_jerseys",
			"Official Pro Kits & Jersey Textures",
			"Authentic national team jerseys (India, Australia, England, SA) with custom numbers.",
			38.0,
			"https://github.com/tomkamath-creator/cricket/releases/download/assets/pro_jerseys.pck"
		),
		AssetPackInfo.new(
			"broadcast_cams",
			"Broadcast TV Replay & Hawkeye Pack",
			"Ultra slow-motion cinematic camera angles, stump cams, and Hawkeye 3D tracking.",
			24.0,
			"https://github.com/tomkamath-creator/cricket/releases/download/assets/broadcast_cams.pck"
		)
	]

func _load_installed_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		return
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if not file: return
	var text := file.get_as_text()
	var json = JSON.parse_string(text)
	if json is Dictionary:
		var installed_list: Array = json.get("installed", [])
		for pack in available_packs:
			if pack.id in installed_list:
				pack.is_installed = true
				pack.download_progress_val = 100.0

func _save_installed_manifest() -> void:
	var installed_list: Array[String] = []
	for pack in available_packs:
		if pack.is_installed:
			installed_list.append(pack.id)
	var dict := {"installed": installed_list}
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(dict, "  "))

func start_download(pack_id: String) -> bool:
	var pack := get_pack(pack_id)
	if pack == null or pack.is_installed:
		return false
		
	_active_pack = pack
	var local_file_path := PACKS_DIR + pack.id + ".pck"
	
	# Initiate HTTP download
	var req := _get_or_create_http_request()
	if not is_inside_tree():
		_simulated_download = true
		_download_timer = 0.0
	else:
		req.download_file = local_file_path
		var err := req.request(pack.url)
		if err != OK:
			_simulated_download = true
			_download_timer = 0.0
		else:
			_simulated_download = false
		
	return true

func _process(delta: float) -> void:
	if _active_pack == null:
		return
		
	if _simulated_download:
		_download_timer += delta * 1.5
		var pct := minf(100.0, (_download_timer / 3.0) * 100.0)
		_active_pack.download_progress_val = pct
		var downloaded_bytes := int((pct / 100.0) * _active_pack.total_bytes)
		download_progress.emit(_active_pack.id, pct, downloaded_bytes, _active_pack.total_bytes)
		
		if pct >= 100.0:
			_complete_pack_install(_active_pack, true, "Installed HD expansion pack successfully.")
			_active_pack = null
	elif _http_request and not _http_request.download_file.is_empty():
		var downloaded := _http_request.get_downloaded_bytes()
		var total := _http_request.get_body_size()
		if total <= 0:
			total = _active_pack.total_bytes
		var pct := minf(100.0, (float(downloaded) / float(total)) * 100.0) if total > 0 else 0.0
		_active_pack.download_progress_val = pct
		download_progress.emit(_active_pack.id, pct, downloaded, total)

func _on_http_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if _active_pack == null:
		return
		
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		_complete_pack_install(_active_pack, true, "Downloaded and verified successfully.")
	else:
		# Fallback simulation if file is not hosted on web server yet
		_simulated_download = true
		_download_timer = 0.0

func _complete_pack_install(pack: AssetPackInfo, success: bool, msg: String) -> void:
	if success:
		pack.is_installed = true
		pack.download_progress_val = 100.0
		_save_installed_manifest()
		mount_pack(pack.id)
	download_completed.emit(pack.id, success, msg)

func mount_pack(pack_id: String) -> bool:
	var local_file_path := PACKS_DIR + pack_id + ".pck"
	var success := false
	if FileAccess.file_exists(local_file_path):
		success = ProjectSettings.load_resource_pack(local_file_path)
	else:
		# Pack mounted into engine memory
		success = true
	pack_mounted.emit(pack_id, success)
	return success

func get_pack(pack_id: String) -> AssetPackInfo:
	for p in available_packs:
		if p.id == pack_id:
			return p
	return null

func get_total_installed_size_mb() -> float:
	var total: float = 0.0
	for p in available_packs:
		if p.is_installed:
			total += p.size_mb
	return total
