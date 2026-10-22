# UmpireController.gd - CricStrike 3D
# 3D Umpire character controller with stance and out decision animations
class_name UmpireController
extends Node3D

var anim_player: AnimationPlayer

func _ready() -> void:
	_setup_anim_player()

func _setup_anim_player() -> void:
	var players := find_children("", "AnimationPlayer", true, false)
	if players.size() > 0:
		anim_player = players[0] as AnimationPlayer
	else:
		var skels := find_children("", "Skeleton3D", true, false)
		if skels.size() > 0:
			var parent_node := skels[0].get_parent()
			anim_player = AnimationPlayer.new()
			anim_player.name = "AnimationPlayer"
			parent_node.add_child(anim_player)
	if anim_player:
		var lib: AnimationLibrary = load("res://assets/animations/cricket_animations.tres")
		if lib:
			if anim_player.has_animation_library(""):
				anim_player.remove_animation_library("")
			anim_player.add_animation_library("", lib)
		if anim_player.has_animation("stance"):
			anim_player.play("stance")

func signal_out() -> void:
	if anim_player and anim_player.has_animation("umpire_out"):
		anim_player.play("umpire_out")
		anim_player.speed_scale = 1.0
		# Return to stance after signal completes
		var timer := get_tree().create_timer(3.0)
		timer.timeout.connect(func():
			if anim_player and anim_player.has_animation("stance"):
				anim_player.play("stance")
		)
