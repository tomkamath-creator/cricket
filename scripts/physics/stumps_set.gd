# StumpsSet.gd - CricStrike 3D
# Complete physical wickets system with 3 individual stumps & 2 dislodgeable bails
class_name StumpsSet
extends Node3D

signal wickets_broken(impact_stump: Node, impact_velocity: float)

@export var is_striker_end: bool = true

# References to stump and bail RigidBodies
var stumps: Array[RigidBody3D] = []
var bails: Array[RigidBody3D] = []

# Initial transform cache for instant reset
var _stump_initial_transforms: Array[Transform3D] = []
var _bail_initial_transforms: Array[Transform3D] = []
var _is_broken: bool = false

func _ready() -> void:
	_gather_components()
	reset_wickets()

func _gather_components() -> void:
	stumps.clear()
	bails.clear()
	_stump_initial_transforms.clear()
	_bail_initial_transforms.clear()
	
	for child in get_children():
		if child is RigidBody3D:
			if child.is_in_group("stumps"):
				stumps.append(child)
				_stump_initial_transforms.append(child.transform)
				child.contact_monitor = true
				child.max_contacts_reported = 2
				child.body_entered.connect(_on_stump_hit.bind(child))
			elif child.is_in_group("bails"):
				bails.append(child)
				_bail_initial_transforms.append(child.transform)
				child.contact_monitor = true
				child.max_contacts_reported = 2
				child.body_entered.connect(_on_bail_hit.bind(child))

func reset_wickets() -> void:
	_is_broken = false
	
	for i in range(stumps.size()):
		var stump := stumps[i]
		stump.freeze = true
		stump.transform = _stump_initial_transforms[i]
		stump.linear_velocity = Vector3.ZERO
		stump.angular_velocity = Vector3.ZERO
		
	for i in range(bails.size()):
		var bail := bails[i]
		bail.freeze = true
		bail.transform = _bail_initial_transforms[i]
		bail.linear_velocity = Vector3.ZERO
		bail.angular_velocity = Vector3.ZERO

func shatter_wickets(impact_node: Node, impact_speed: float, hit_direction: Vector3 = Vector3.ZERO) -> void:
	if _is_broken:
		return
	_is_broken = true
	
	if hit_direction == Vector3.ZERO:
		hit_direction = Vector3(0.0, 0.2, 1.0 if is_striker_end else -1.0).normalized()
		
	# Dislodge bails with high explosive impulse
	for bail in bails:
		bail.freeze = false
		var random_side := randf_range(-0.5, 0.5)
		var bail_impulse := (hit_direction * 0.8 + Vector3(random_side, 1.2, 0.0)).normalized() * (impact_speed * 0.18 + 2.5)
		bail.apply_central_impulse(bail_impulse)
		bail.apply_torque_impulse(Vector3(randf_range(-2.0, 2.0), randf_range(-3.0, 3.0), randf_range(-2.0, 2.0)))
		
	# Stumps wobble and fall
	for stump in stumps:
		stump.freeze = false
		var dist_mult := 1.0
		if stump == impact_node:
			dist_mult = 1.5
		var stump_impulse := (hit_direction + Vector3(randf_range(-0.2, 0.2), 0.3, 0.0)).normalized() * (impact_speed * 0.12 * dist_mult + 1.0)
		stump.apply_central_impulse(stump_impulse)
		stump.apply_torque_impulse(Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)))

	wickets_broken.emit(impact_node, impact_speed)

func _on_stump_hit(body: Node, stump_node: RigidBody3D) -> void:
	if body is CricketBall or body.is_in_group("ball"):
		var speed: float = 12.0
		var dir := Vector3(0.0, 0.2, 1.0).normalized()
		if body is RigidBody3D:
			speed = (body as RigidBody3D).linear_velocity.length()
			dir = (body as RigidBody3D).linear_velocity.normalized()
		shatter_wickets(stump_node, speed, dir)

func _on_bail_hit(body: Node, bail_node: RigidBody3D) -> void:
	if body is CricketBall or body.is_in_group("ball"):
		var speed: float = 10.0
		var dir := Vector3(0.0, 0.2, 1.0).normalized()
		if body is RigidBody3D:
			speed = (body as RigidBody3D).linear_velocity.length()
			dir = (body as RigidBody3D).linear_velocity.normalized()
		shatter_wickets(bail_node, speed, dir)

func is_broken() -> bool:
	return _is_broken
