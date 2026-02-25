extends Node3D

# ────────────────────────────────────────────────
# CONSTANTS
# ────────────────────────────────────────────────

const LANES: Array[float] = [-1.5, 0.0, 1.5]
const LANE_INDICES: Array[int] = [0, 1, 2]
const PLATFORM_LENGTH: float = 20.0

# Sizes (unchanged from last – small & positioned correctly)
const JUMP_OVER_SIZE:   Vector3 = Vector3(2.4, 1.6, 1.2)   # red
const SLIDE_UNDER_SIZE: Vector3 = Vector3(2.4, 1.4, 1.2)   # blue
const EVADE_SIZE:       Vector3 = Vector3(3.6, 2.4, 1.15)  # yellow – EVADES EVERYWHERE!

# ────────────────────────────────────────────────
# EXPORTED
# ────────────────────────────────────────────────

@export var obstacle_scene: PackedScene
@export var spawn_chance: float = 0.98   # ALMOST ALWAYS spawn!

# ────────────────────────────────────────────────
# EVADE-HEAVY PATTERNS (80%+ EVADES!)
# Put EVADE patterns FIRST & MOST – random pick = evade chaos!
# ────────────────────────────────────────────────

var patterns: Array = [
	# ─── TRIPLES: 2 EVADES + 1 other (EVADES ON SIDES/MIDDLE) ───
	[[2, 0], [0, 1], [2, 2]], [[2, 0], [1, 1], [2, 2]],
	[[2, 1], [0, 0], [2, 2]], [[2, 1], [1, 0], [2, 2]],
	[[2, 0], [0, 2], [2, 1]], [[2, 0], [1, 2], [2, 1]],
	[[2, 2], [0, 1], [2, 0]], [[2, 2], [1, 1], [2, 0]],  # mirrored

	# ─── DOUBLE EVADES ─── (pure evade walls!)
	[[2, 0], [2, 2]], [[2, 0], [2, 1]], [[2, 1], [2, 2]],
	[[2, 2], [2, 0]], [[2, 1], [2, 0]], [[2, 2], [2, 1]],  # duplicates for higher chance

	# ─── SINGLE EVADE (fallback feel) ─── REPEAT MANY TIMES!
	[[2, 0]], [[2, 0]], [[2, 0]],  # lane 0 evade x3
	[[2, 1]], [[2, 1]], [[2, 1]],  # lane 1 x3
	[[2, 2]], [[2, 2]], [[2, 2]],  # lane 2 x3

	# ─── EVADE + JUMP/SLIDE (rare variety, LAST = lower chance)
	[[2, 0], [0, 2]], [[2, 2], [0, 0]], [[2, 1], [0, 0]],
	[[2, 0], [1, 2]], [[2, 2], [1, 0]], [[2, 1], [1, 0]],
	[[0, 0]], [[0, 1]], [[0, 2]],  # pure jumps (very rare)
	[[1, 0]], [[1, 1]], [[1, 2]],  # pure slides (very rare)
]

var prev_safe_lanes: Array[int] = [0, 1, 2]

# ────────────────────────────────────────────────
# SPAWN – EVADES GUARANTEED!
# ────────────────────────────────────────────────

func spawn_obstacle(platform: Node3D) -> void:
	if randf() > spawn_chance:
		print_debug("→ ULTRA-RARE EMPTY")
		prev_safe_lanes = [0, 1, 2]
		return

	var valid_patterns: Array = []
	for pattern: Array in patterns:
		if is_valid_pattern(pattern):
			valid_patterns.append(pattern)

	if valid_patterns.is_empty():
		spawn_evade_fallback(platform)  # ALWAYS EVADE!
		return

	var chosen: Array = valid_patterns[randi() % valid_patterns.size()]
	instantiate_pattern(platform, chosen)
	print_debug("🟡 EVADE SPAWN: ", str(chosen), " | Safe: ", prev_safe_lanes)

# ────────────────────────────────────────────────
# FALLBACK: ALWAYS SPAWN EVADE (YELLOW!)
# ────────────────────────────────────────────────

func spawn_evade_fallback(platform: Node3D) -> void:
	if prev_safe_lanes.is_empty():
		return
	var safe_lane_idx: int = prev_safe_lanes[randi() % prev_safe_lanes.size()]
	spawn_helper(platform, 2, LANES[safe_lane_idx], 0.0)  # TYPE 2 = EVADE ONLY!
	print_debug("🟡 EVADE FALLBACK lane ", safe_lane_idx)

# ────────────────────────────────────────────────
# VALIDATION (unchanged)
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
# INSTANTIATE PATTERN (unchanged)
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
			2:    x_offset = randf_range(1.5, PLATFORM_LENGTH - 5.5)
			_:    x_offset = randf_range(2.0, PLATFORM_LENGTH - 2.0)

		spawn_helper(platform, type_idx, lane_z, x_offset)

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
# SPAWN SINGLE (with Y positioning)
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

	# Custom Y per type
	var y_pos: float
	match type_idx:
		0: y_pos = mesh_size.y / 2.0 - 0.12  # red low
		1: y_pos = 1.2                        # blue floating
		2: y_pos = mesh_size.y / 2.0          # yellow normal
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
