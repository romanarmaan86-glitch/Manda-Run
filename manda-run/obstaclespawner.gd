extends Node3D

const LANES := [-1.5, 0.0, 1.5]
const LANE_INDICES := [0, 1, 2]

const JUMP_OVER_SIZE   := Vector3(1.2, 1.1, 0.9)
const SLIDE_UNDER_SIZE := Vector3(1.2, 0.6, 0.9)
const EVADE_SIZE       := Vector3(17.0, 1.65, 0.8)

@export var obstacle_scene: PackedScene
@export var spawn_chance: float = 0.6

# Patterns: Array of arrays → use plain Array to avoid strict subtype issues
var patterns: Array = [
# Empty (breathing room)
	[],

	# Single barriers (jump/slide/evade)
	[[0, 0]], [[0, 1]], [[0, 2]],  # Jump barriers (tall)
	[[1, 0]], [[1, 1]], [[1, 2]],  # Slide barriers (low)
	[[2, 0]], [[2, 1]], [[2, 2]],  # Trains/evade blockers

	# Double trains (evades) - MOST COMMON IN SUBWAY (sides safe middle, or side+middle safe opposite)
	[[2, 0], [2, 2]],  # Trains left+right (safe middle) - CLASSIC
	[[2, 0], [2, 1]],  # Trains left+middle (safe right)
	[[2, 1], [2, 2]],  # Trains middle+right (safe left)



	# === NEW: TRAIN + JUMP/SLIDE + TRAIN (TRIPLE PATTERNS) ===
	# Safe middle: trains sides + jump/slide middle
	[[2, 0], [0, 1], [2, 2]],  # train left + JUMP middle + train right
	[[2, 0], [1, 1], [2, 2]],  # train left + SLIDE middle + train right

	# Safe left: trains middle/right + jump/slide left
	[[2, 1], [0, 0], [2, 2]],  # train middle + JUMP left + train right
	[[2, 1], [1, 0], [2, 2]],  # train middle + SLIDE left + train right

	# Safe right: trains left/middle + jump/slide right
	[[2, 0], [0, 2], [2, 1]],  # train left + JUMP right + train middle
	[[2, 0], [1, 2], [2, 1]],  # train left + SLIDE right + train middle

	# Extra variants (shuffled order for variety, validation handles)
	[[2, 2], [0, 1], [2, 0]],  # train right + JUMP middle + train left (same as first, reversed)
	[[2, 2], [1, 1], [2, 0]],  # train right + SLIDE middle + train left
]

var prev_safe_lanes: Array = LANE_INDICES.duplicate()

func spawn_obstacle(platform: Node3D) -> void:
	if randf() > spawn_chance:
		prev_safe_lanes = LANE_INDICES.duplicate()
		return
	
	var valid_patterns: Array = []
	for pattern in patterns:
		if is_valid_pattern(pattern):
			valid_patterns.append(pattern)
	
	if valid_patterns.is_empty():
		printerr("No valid patterns found – using empty")
		prev_safe_lanes = LANE_INDICES.duplicate()
		return
	
	var chosen: Array = valid_patterns[randi() % valid_patterns.size()]
	instantiate_pattern(platform, chosen)
	
	# Update safe lanes for next validation
	prev_safe_lanes.clear()
	for i in LANE_INDICES:
		var blocked := false
		for obs in chosen:
			if obs[1] == i:
				blocked = true
				break
		if not blocked:
			prev_safe_lanes.append(i)

func is_valid_pattern(pattern: Array) -> bool:
	var this_safe: Array = []
	for i in LANE_INDICES:
		var blocked := false
		for obs in pattern:
			if obs[1] == i:
				blocked = true
				break
		if not blocked:
			this_safe.append(i)
	
	for safe_prev in prev_safe_lanes:
		if this_safe.has(safe_prev):
			return true
	return false

func instantiate_pattern(platform: Node3D, pattern: Array) -> void:
	for obs_data in pattern:
		var type_idx: int = obs_data[0]
		var lane_idx: int = obs_data[1]
		var lane_z: float = LANES[lane_idx]
		var x_offset: float = 1.0 + randf_range(0.0, 2.0) if type_idx == 2 else randf_range(4.0, 12.0)
		spawn_helper(platform, type_idx, lane_z, x_offset)
	
	print("Pattern: ", pattern, " | Next safe lanes: ", prev_safe_lanes)

func spawn_helper(platform: Node3D, type_idx: int, lane_z: float, x_offset: float) -> void:
	var obstacle := obstacle_scene.instantiate() as Node3D
	if obstacle == null:
		return
	
	obstacle.obstacle_type = type_idx
	
	var mesh_size: Vector3
	match type_idx:
		0: mesh_size = JUMP_OVER_SIZE
		1: mesh_size = SLIDE_UNDER_SIZE
		2: mesh_size = EVADE_SIZE
		_: mesh_size = Vector3.ONE
	
	obstacle.position = Vector3(x_offset, mesh_size.y / 2.0 + 0.01, lane_z)
	
	var mesh := obstacle.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh:
		mesh.mesh = BoxMesh.new()
		mesh.mesh.size = mesh_size
		mesh.scale = Vector3.ONE
		var mat := StandardMaterial3D.new()
		match type_idx:
			0: mat.albedo_color = Color.RED
			1: mat.albedo_color = Color.BLUE
			2: mat.albedo_color = Color.YELLOW
		mesh.material_override = mat
	
	var area_coll := obstacle.get_node_or_null("Area3D/CollisionShape3D") as CollisionShape3D
	if area_coll:
		var box := BoxShape3D.new()
		box.size = mesh_size
		area_coll.shape = box
		area_coll.scale = Vector3.ONE
	
	platform.add_child(obstacle)
