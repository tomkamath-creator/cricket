# StadiumBuilder.gd - CricStrike 3D
# Procedural / Modular 3D International Cricket Arena Builder
# Constructs 20.12m pitch, white crease lines, boundary rope, sight screens, stadium stands & floodlights
class_name StadiumBuilder
extends Node3D

@export var build_on_ready: bool = true

func _ready() -> void:
	if build_on_ready:
		build_stadium()

func build_stadium() -> void:
	# 1. Pitch Turf Ground
	_build_pitch_strip()
	
	# 2. Crease Markings (Popping, Bowling, Return creases)
	_build_crease_markings()
	
	# 3. Outfield Oval
	_build_outfield()
	
	# 4. Boundary Foam Rope / Cushions
	_build_boundary_rope()
	
	# 5. Sight Screens (Both ends)
	_build_sight_screens()
	
	# 6. Stadium Stands Ring & Floodlight Towers
	_build_stadium_stands()
	_build_floodlight_towers()

func _build_pitch_strip() -> void:
	var pitch_body := StaticBody3D.new()
	pitch_body.name = "PitchSurface"
	pitch_body.add_to_group("pitch_surface")
	
	# Pitch dimensions: 3.05m width, 0.05m depth, 20.12m + 2.44m run-up buffer = 22.56m length
	var pitch_mesh := BoxMesh.new()
	pitch_mesh.size = Vector3(GameConstants.PITCH_WIDTH, 0.08, GameConstants.PITCH_LENGTH + 2.5)
	
	var pitch_mat := StandardMaterial3D.new()
	pitch_mat.albedo_color = Color(0.72, 0.65, 0.46) # Clay/soil turf
	pitch_mat.roughness = 0.75
	pitch_mesh.material = pitch_mat
	
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = pitch_mesh
	mesh_inst.position = Vector3(0.0, -0.04, 0.0)
	
	var col_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = pitch_mesh.size
	col_shape.shape = box_shape
	col_shape.position = mesh_inst.position
	
	pitch_body.add_child(mesh_inst)
	pitch_body.add_child(col_shape)
	add_child(pitch_body)

func _build_crease_markings() -> void:
	var lines_node := Node3D.new()
	lines_node.name = "CreaseMarkings"
	
	var white_mat := StandardMaterial3D.new()
	white_mat.albedo_color = Color(0.96, 0.96, 0.96)
	white_mat.roughness = 0.4
	
	# Both ends: Striker (Z = +10.06) and Bowler (Z = -10.06)
	var ends: Array[float] = [GameConstants.PITCH_LENGTH * 0.5, -GameConstants.PITCH_LENGTH * 0.5]
	for z_end: float in ends:
		var sign_dir: float = -1.0 if z_end > 0 else 1.0
		
		# 1. Bowling Crease (through the stumps, width 2.64m)
		var bowl_crease := _create_line_mesh(Vector3(GameConstants.RETURN_CREASE_WIDTH, 0.005, 0.05), white_mat)
		bowl_crease.position = Vector3(0.0, 0.003, z_end)
		lines_node.add_child(bowl_crease)
		
		# 2. Popping Crease (1.22m in front of bowling crease, width 3.66m)
		var popping_z: float = z_end + (sign_dir * GameConstants.POPPING_CREASE_OFFSET)
		var pop_crease := _create_line_mesh(Vector3(3.66, 0.005, 0.06), white_mat)
		pop_crease.position = Vector3(0.0, 0.003, popping_z)
		lines_node.add_child(pop_crease)
		
		# 3. Return Creases (perpendicular to bowling crease, 2.44m long)
		var sides: Array[float] = [-1.32, 1.32]
		for side: float in sides:
			var ret_crease := _create_line_mesh(Vector3(0.05, 0.005, 2.44), white_mat)
			ret_crease.position = Vector3(side, 0.003, z_end + (sign_dir * 0.61))
			lines_node.add_child(ret_crease)
			
	add_child(lines_node)

func _create_line_mesh(size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = mat
	mi.mesh = bm
	return mi

func _build_outfield() -> void:
	var outfield_body := StaticBody3D.new()
	outfield_body.name = "OutfieldTurf"
	outfield_body.add_to_group("outfield")
	
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 80.0
	cylinder.bottom_radius = 80.0
	cylinder.height = 0.1
	cylinder.radial_segments = 64
	
	var grass_mat := StandardMaterial3D.new()
	grass_mat.albedo_color = Color(0.18, 0.45, 0.15)
	grass_mat.roughness = 0.8
	cylinder.material = grass_mat
	
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = cylinder
	mesh_inst.position = Vector3(0.0, -0.05, 0.0)
	
	var col := CollisionShape3D.new()
	var cyl_shape := CylinderShape3D.new()
	cyl_shape.radius = 80.0
	cyl_shape.height = 0.1
	col.shape = cyl_shape
	col.position = mesh_inst.position
	
	outfield_body.add_child(mesh_inst)
	outfield_body.add_child(col)
	add_child(outfield_body)

func _build_boundary_rope() -> void:
	var rope_node := Node3D.new()
	rope_node.name = "BoundaryRope"
	
	var segments := 72
	var rope_mat := StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.95, 0.45, 0.1) # Bright boundary foam orange
	
	var prev_point := Vector3(GameConstants.BOUNDARY_RADIUS_X, 0.1, 0.0)
	for i in range(1, segments + 1):
		var angle := (i / float(segments)) * TAU
		var cur_point := Vector3(
			cos(angle) * GameConstants.BOUNDARY_RADIUS_X,
			0.1,
			sin(angle) * GameConstants.BOUNDARY_RADIUS_Z
		)
		
		# Place cushion segment
		var cushion := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var seg_len := prev_point.distance_to(cur_point)
		bm.size = Vector3(0.35, 0.22, seg_len + 0.1)
		bm.material = rope_mat
		cushion.mesh = bm
		
		cushion.position = (prev_point + cur_point) * 0.5
		cushion.look_at(cur_point, Vector3.UP)
		rope_node.add_child(cushion)
		
		prev_point = cur_point
		
	add_child(rope_node)

func _build_sight_screens() -> void:
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.98, 0.98, 0.98) # Pristine white contrast screen
	screen_mat.roughness = 0.25
	
	for z_pos in [-70.0, 70.0]:
		var screen_mesh := BoxMesh.new()
		screen_mesh.size = Vector3(14.0, 6.5, 0.6)
		screen_mesh.material = screen_mat
		
		var mi := MeshInstance3D.new()
		mi.mesh = screen_mesh
		mi.position = Vector3(0.0, 3.25, z_pos)
		add_child(mi)

func _build_stadium_stands() -> void:
	var stands_node := Node3D.new()
	stands_node.name = "GrandstandTiers"
	
	var concrete_mat := StandardMaterial3D.new()
	concrete_mat.albedo_color = Color(0.32, 0.35, 0.42)
	concrete_mat.roughness = 0.9
	
	var seats_mat := StandardMaterial3D.new()
	seats_mat.albedo_color = Color(0.12, 0.38, 0.68) # Stadium blue seats
	
	# 3 Stepped spectator tiers around the circumference
	for tier in range(3):
		var tier_radius: float = 82.0 + (tier * 6.5)
		var tier_height: float = 3.0 + (tier * 4.2)
		
		var tube := TorusMesh.new()
		tube.inner_radius = tier_radius - 1.5
		tube.outer_radius = tier_radius + 4.5
		tube.rings = 36
		tube.ring_segments = 8
		tube.material = seats_mat if tier % 2 == 0 else concrete_mat
		
		var mi := MeshInstance3D.new()
		mi.mesh = tube
		mi.position = Vector3(0.0, tier_height, 0.0)
		stands_node.add_child(mi)
		
	add_child(stands_node)

func _build_floodlight_towers() -> void:
	var light_tower_node := Node3D.new()
	light_tower_node.name = "Floodlights"
	
	var tower_mat := StandardMaterial3D.new()
	tower_mat.albedo_color = Color(0.7, 0.72, 0.75)
	
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = Color(1.0, 0.98, 0.9)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(1.0, 0.98, 0.85)
	glow_mat.emission_energy_multiplier = 2.5
	
	var corner_positions := [
		Vector3(-55.0, 0.0, -55.0),
		Vector3(55.0, 0.0, -55.0),
		Vector3(-55.0, 0.0, 55.0),
		Vector3(55.0, 0.0, 55.0)
	]
	
	for pos in corner_positions:
		# Pylon column
		var pylon := MeshInstance3D.new()
		var pylon_mesh := CylinderMesh.new()
		pylon_mesh.top_radius = 0.6
		pylon_mesh.bottom_radius = 1.6
		pylon_mesh.height = 34.0
		pylon_mesh.material = tower_mat
		pylon.mesh = pylon_mesh
		pylon.position = pos + Vector3(0.0, 17.0, 0.0)
		light_tower_node.add_child(pylon)
		
		# Floodlight head panel
		var head := MeshInstance3D.new()
		var head_mesh := BoxMesh.new()
		head_mesh.size = Vector3(7.5, 4.5, 1.2)
		head_mesh.material = glow_mat
		head.mesh = head_mesh
		head.position = pos + Vector3(0.0, 34.0, 0.0)
		head.look_at(Vector3(0.0, 2.0, 0.0), Vector3.UP)
		light_tower_node.add_child(head)
		
	add_child(light_tower_node)
