extends Node3D

# ────────────────────────────────────────────────
# CONSTANTS
# ────────────────────────────────────────────────

const LANES: Array[float] = [-1.5, 0.0, 1.5]
const LANE_INDICES: Array[int] = [0, 1, 2]
const PLATFORM_LENGTH: float = 20.0

const JUMP_OVER_SIZE:   Vector3 = Vector3(0.5, 0.5, 0.5)
const SLIDE_UNDER_SIZE: Vector3 = Vector3(0.5, 0.5, 0.5)
const EVADE_SIZE:       Vector3 = Vector3(3, 2, 0.6)

# ────────────────────────────────────────────────
# EXPORTED
# ────────────────────────────────────────────────

@export var obstacle_scene: PackedScene
@export var spawn_chance: float = 0.97

# ────────────────────────────────────────────────
# PATTERNS — focused on grouped evades
# ────────────────────────────────────────────────

var patterns: Array = [
	# Most wanted: evades on sides + middle jump or slide
	[[2, 0], [0, 1], [2, 2]],   # left evade + middle jump + right evade
	[[2, 0], [1, 1], [2, 2]],   # left evade + middle slide + right evade
	[[2, 2], [0, 1], [2, 0]],   # mirrored
	[[2, 2], [1, 1], [2, 0]],
	

	# Tight evade groups / walls

	[[2, 0], [2, 1]],           # left + middle
	[[2, 1], [2, 2]],           # middle + right
	[[2, 0], [2, 2]],           # left + right only


	# Single evades (still frequent)
	[[2, 0]], [[2, 0]], [[2, 0]],
	[[2, 1]], [[2, 1]], [[2, 1]],
	[[2, 2]], [[2, 2]], [[2, 2]],

	# Rare non-evade patterns (at the end = low chance)
	[[0, 0]], [[0, 1]], [[0, 2]],
	[[1, 0]], [[1, 1]], [[1, 2]],
]

var prev_safe_lanes: Array[int] = [0, 1, 2]

# ────────────────────────────────────────────────
# MAIN SPAWN
# ────────────────────────────────────────────────

func spawn_obstacle(platform: Node3D) -> void:
	if randf() > spawn_chance:
		print_debug("→ rare empty")
		prev_safe_lanes = [0, 1, 2]
		return

	var valid_patterns: Array = []
	for pattern: Array in patterns:
		if is_valid_pattern(pattern):
			valid_patterns.append(pattern)

	if valid_patterns.is_empty():
		spawn_evade_fallback(platform)
		return

	var chosen: Array = valid_patterns[randi() % valid_patterns.size()]
	instantiate_pattern(platform, chosen)
	print_debug("Spawned pattern: ", str(chosen), " | Safe next: ", prev_safe_lanes)

# ────────────────────────────────────────────────
# FALLBACK = always an evade
# ────────────────────────────────────────────────

func spawn_evade_fallback(platform: Node3D) -> void:
	if prev_safe_lanes.is_empty():
		return
	var safe_lane_idx: int = prev_safe_lanes[randi() % prev_safe_lanes.size()]
	spawn_helper(platform, 2, LANES[safe_lane_idx], 0.0)
	print_debug("Fallback evade → lane ", safe_lane_idx)

# ────────────────────────────────────────────────
# PATTERN VALIDATION
# ────────────────────────────────────────────────

func is_valid_pattern(pattern: Array) -> bool:
	var this_safe: Array[int] = []
	for i: int in LANE_INDICES:
		var blocked := false
		for obs: Array in pattern:
			if obs.size() >= 2 and obs[1] == i:
				blocked = true
				break
		if not blocked:
			this_safe.append(i)

	for safe_prev: int in prev_safe_lanes:
		if this_safe.has(safe_prev):
			return true
	return false

# ────────────────────────────────────────────────
# PLACE ALL OBSTACLES IN THE PATTERN AT ~THE SAME POSITION
# ────────────────────────────────────────────────

func instantiate_pattern(platform: Node3D, pattern: Array) -> void:
	# One base x-position for the whole group → makes them appear together
	var base_x: float = randf_range(4.0, PLATFORM_LENGTH - 6.0)

	for obs_data: Array in pattern:
		if obs_data.size() < 2:
			continue
		var type_idx: int = obs_data[0]
		var lane_idx: int = obs_data[1]
		var lane_z: float = LANES[lane_idx]

		# Small random variation so it doesn't look too robotic
		var x_offset: float = base_x + randf_range(-0.9, 0.9)

		spawn_helper(platform, type_idx, lane_z, x_offset)

	# Update safe lanes for next platform
	prev_safe_lanes.clear()
	for i: int in LANE_INDICES:
		var blocked := false
		for obs: Array in pattern:
			if obs.size() >= 2 and obs[1] == i:
				blocked = true
				break
		if not blocked:
			prev_safe_lanes.append(i)

# ────────────────────────────────────────────────
# CREATE SINGLE OBSTACLE
# ────────────────────────────────────────────────

func spawn_helper(platform: Node3D, type_idx: int, lane_z: float, x_offset: float) -> void:
	var obstacle: Node3D = obstacle_scene.instantiate()
	if not obstacle:
		return

	obstacle.set("obstacle_type", type_idx)

	var mesh_size: Vector3
	match type_idx:
		0: mesh_size = JUMP_OVER_SIZE
		1: mesh_size = SLIDE_UNDER_SIZE
		2: mesh_size = EVADE_SIZE
		_: mesh_size = Vector3.ONE

	var y_pos: float
	match type_idx:
		0: y_pos = mesh_size.y / 2.0 - 0.12   # red low
		1: y_pos = 1.2                         # blue floating
		2: y_pos = mesh_size.y / 2.0           # yellow normal
		_: y_pos = mesh_size.y / 2.0

	obstacle.position = Vector3(x_offset, y_pos, lane_z)

	# Mesh
	var mesh: MeshInstance3D = obstacle.get_node_or_null("MeshInstance3D")
	if mesh:
		var box_mesh = BoxMesh.new()
		box_mesh.size = mesh_size
		mesh.mesh = box_mesh

		var mat = StandardMaterial3D.new()
		match type_idx:
			0: mat.albedo_color = Color(0.98, 0.18, 0.18)
			1: mat.albedo_color = Color(0.18, 0.45, 0.98)
			2: mat.albedo_color = Color(0.98, 0.88, 0.12)
		mesh.material_override = mat

	# Collision
	var coll_shape: CollisionShape3D = obstacle.get_node_or_null("Area3D/CollisionShape3D")
	if coll_shape:
		var box_shape = BoxShape3D.new()
		box_shape.size = mesh_size
		coll_shape.shape = box_shape

	platform.add_child(obstacle)
