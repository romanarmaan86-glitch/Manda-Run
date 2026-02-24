extends Node3D

# ────────────────────────────────────────────────
# CONSTANTS – smaller & better positioned
# ────────────────────────────────────────────────

const LANES: Array[float] = [-1.5, 0.0, 1.5]
const LANE_INDICES: Array[int] = [0, 1, 2]
const PLATFORM_LENGTH: float = 20.0

# Much smaller sizes + appropriate proportions
const JUMP_OVER_SIZE:   Vector3 = Vector3(1, 0.5, 0.5)   # red   – low jump obstacle
const SLIDE_UNDER_SIZE: Vector3 = Vector3(1, 0.5, 0.5)   # blue  – floating / must slide under
const EVADE_SIZE:       Vector3 = Vector3(3, 2, 0.6)  # yellow – train/wall, narrower

# ────────────────────────────────────────────────
# EXPORTED
# ────────────────────────────────────────────────

@export var obstacle_scene: PackedScene
@export var spawn_chance: float = 0.99999   # quite dense – adjust to 0.92–0.95 if you want more

# ────────────────────────────────────────────────
# PATTERNS
# ────────────────────────────────────────────────

var patterns: Array = [
	# Singles
	[[0, 0]], [[0, 1]], [[0, 2]],
	[[1, 0]], [[1, 1]], [[1, 2]],
	[[2, 0]], [[2, 1]], [[2, 2]],

	# Double combos
	[[0, 0], [1, 2]], [[0, 2], [1, 0]], [[0, 1], [1, 0]],
	[[2, 0], [2, 2]], [[2, 0], [2, 1]], [[2, 1], [2, 2]],
	[[0, 0], [0, 2]], [[1, 0], [1, 2]],

	# Triple patterns
	[[2, 0], [0, 1], [2, 2]],
	[[2, 0], [1, 1], [2, 2]],
	[[2, 1], [0, 0], [2, 2]],
	[[2, 1], [1, 0], [2, 2]],
	[[2, 0], [0, 2], [2, 1]],
	[[2, 0], [1, 2], [2, 1]],
]

var prev_safe_lanes: Array[int] = [0, 1, 2]

# ────────────────────────────────────────────────
# MAIN SPAWN FUNCTION
# ────────────────────────────────────────────────

func spawn_obstacle(platform: Node3D) -> void:
	if randf() > spawn_chance:
		print_debug("→ EMPTY (rare)")
		prev_safe_lanes = [0, 1, 2]
		return

	var valid_patterns: Array = []
	for pattern: Array in patterns:
		if is_valid_pattern(pattern):
			valid_patterns.append(pattern)

	if valid_patterns.is_empty():
		spawn_single_fallback(platform)
		return

	var chosen: Array = valid_patterns[randi() % valid_patterns.size()]
	instantiate_pattern(platform, chosen)
	print_debug("Spawned: ", str(chosen), "  |  Next safe lanes: ", prev_safe_lanes)

# ────────────────────────────────────────────────
# FALLBACK – always at least one safe path
# ────────────────────────────────────────────────

func spawn_single_fallback(platform: Node3D) -> void:
	if prev_safe_lanes.is_empty():
		return

	var safe_lane_idx: int = prev_safe_lanes[randi() % prev_safe_lanes.size()]
	var obs_type: int = randi() % 3
	spawn_helper(platform, obs_type, LANES[safe_lane_idx], 0.0)
	print_debug("Fallback → type ", obs_type, " lane ", safe_lane_idx)

# ────────────────────────────────────────────────
# CHECK IF PATTERN KEEPS AT LEAST ONE PREVIOUS SAFE LANE
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
# INSTANTIATE ALL OBSTACLES IN A PATTERN
# ────────────────────────────────────────────────

func instantiate_pattern(platform: Node3D, pattern: Array) -> void:
	for obs_data: Array in pattern:
		if obs_data.size() < 2:
			continue
		var type_idx: int = obs_data[0]
		var lane_idx: int = obs_data[1]
		var lane_z: float = LANES[lane_idx]

		var x_offset: float
		match type_idx:
			0, 1: x_offset = randf_range(3.0, PLATFORM_LENGTH - 3.0)
			2:    x_offset = randf_range(1.5, PLATFORM_LENGTH - 5.5)  # trains start earlier
			_:    x_offset = randf_range(2.0, PLATFORM_LENGTH - 2.0)

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
# CREATE ONE OBSTACLE – with custom height & position
# ────────────────────────────────────────────────

func spawn_helper(platform: Node3D, type_idx: int, lane_z: float, x_offset: float) -> void:
	var obstacle: Node3D = obstacle_scene.instantiate()
	if not obstacle:
		return

	# Set type for your obstacle script logic
	obstacle.set("obstacle_type", type_idx)

	var mesh_size: Vector3
	match type_idx:
		0: mesh_size = JUMP_OVER_SIZE
		1: mesh_size = SLIDE_UNDER_SIZE
		2: mesh_size = EVADE_SIZE
		_: mesh_size = Vector3.ONE

	# ─── Custom Y position per type ────────────────────────────────
	var y_pos: float
	match type_idx:
		0:  # RED – jump over → very low, almost touching ground
			y_pos = mesh_size.y / 2.0 - 0.12
		1:  # BLUE – slide under → raised / floating
			y_pos = 1.2           # ← tune this (1.0–1.4 range usually good)
		2:  # YELLOW – normal height train/wall
			y_pos = mesh_size.y / 2.0
		_:
			y_pos = mesh_size.y / 2.0

	obstacle.position = Vector3(x_offset, y_pos, lane_z)

	# ─── Visual (Mesh) ─────────────────────────────────────────────
	var mesh: MeshInstance3D = obstacle.get_node_or_null("MeshInstance3D")
	if mesh:
		var box_mesh = BoxMesh.new()
		box_mesh.size = mesh_size
		mesh.mesh = box_mesh

		var mat = StandardMaterial3D.new()
		match type_idx:
			0: mat.albedo_color = Color(0.98, 0.18, 0.18)   # vivid red
			1: mat.albedo_color = Color(0.18, 0.45, 0.98)   # vivid blue
			2: mat.albedo_color = Color(0.98, 0.88, 0.12)   # vivid yellow
		mesh.material_override = mat

	# ─── Collision ─────────────────────────────────────────────────
	var coll_shape: CollisionShape3D = obstacle.get_node_or_null("Area3D/CollisionShape3D")
	if coll_shape:
		var box_shape = BoxShape3D.new()
		box_shape.size = mesh_size
		coll_shape.shape = box_shape

	platform.add_child(obstacle)
