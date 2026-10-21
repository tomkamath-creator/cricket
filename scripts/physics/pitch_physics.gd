# PitchPhysics.gd - CricStrike 3D
# Pitch surface physics and bounce restitution engine
class_name PitchPhysics
extends PitchConditions

func _init(type: GameConstants.PitchType = GameConstants.PitchType.FLAT) -> void:
	super._init(type)
