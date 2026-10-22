extends SceneTree

func _init() -> void:
	print("Building cricket_animations.tres...")
	var lib = AnimationLibrary.new()
	
	var anim_sources = {
		"stance": "res://assets/animations/Baseball_Idle.fbx",
		"swing": "res://assets/animations/Baseball_Hit.fbx",
		"pull": "res://assets/animations/Baseball_Hit_2.fbx",
		"bowl": "res://assets/animations/Baseball_Pitching_2.fbx",
		"sprint": "res://assets/animations/Sprint.fbx",
		"runup": "res://assets/animations/Fast_Run.fbx",
		"keeper": "res://assets/animations/Baseball_Catcher.fbx",
		"umpire_out": "res://assets/animations/Baseball_Umpire.fbx",
	}
	
	for anim_name in anim_sources:
		var path = anim_sources[anim_name]
		var scene: PackedScene = load(path)
		if not scene:
			print("ERROR: Could not load ", path)
			continue
		var inst = scene.instantiate()
		var players = inst.find_children("", "AnimationPlayer", true, false)
		if players.size() == 0:
			print("ERROR: No AnimationPlayer in ", path)
			continue
		var player: AnimationPlayer = players[0]
		var sub_anims = player.get_animation_list()
		if sub_anims.size() == 0:
			print("ERROR: No animations in player for ", path)
			continue
		var src_anim: Animation = player.get_animation(sub_anims[0])
		var anim: Animation = src_anim.duplicate()
		if anim_name in ["stance", "sprint", "runup", "keeper"]:
			anim.loop_mode = Animation.LOOP_LINEAR
		lib.add_animation(anim_name, anim)
		print("Added animation '", anim_name, "' (length ", anim.length, "s, tracks: ", anim.get_track_count(), ", loop: ", anim.loop_mode, ")")
	
	var err = ResourceSaver.save(lib, "res://assets/animations/cricket_animations.tres")
	if err == OK:
		print("SUCCESS: Saved res://assets/animations/cricket_animations.tres")
	else:
		print("ERROR saving animation library: ", err)
	quit(0)
