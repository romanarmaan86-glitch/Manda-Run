extends Node3D

# ────────────────────────────────────────────────
# CONSTANTS
# ────────────────────────────────────────────────
const LANES: Array[float] = [-1.5, 0.0, 1.5]
const LANE_INDICES: Array[int] = [0, 1, 2]
const PLATFORM_LENGTH: float = 20.0

# Obstacle sizes
const JUMP_OVER_SIZE: Vector3   = Vector3(1.0, 0.5,  0.5)   # 0 = red / jump
const SLIDE_UNDER_SIZE: Vector3 = Vector3(1.0, 0.5,  0.5)   # 1 = blue / slide
const EVADE_SIZE: Vector3       = Vector3(3.0, 2.0,  0.6)   # 2 = yellow / evade

# ────────────────────────────────────────────────
# EXPORTED
# ────────────────────────────────────────────────
@export var obstacle_scene: PackedScene
@export var spawn_chance: float = 0.94     # slightly less dense than before

# ────────────────────────────────────────────────
# PATTERNS — now with many simultaneous (same-x) groups
# Format: [type, lane, rel_x (0–1)]   — same rel_x = appear at same time
# ────────────────────────────────────────────────
var patterns: Array = [
	# ─── Classic singles ───────────────────────────────────────
	[[0, 0]], [[0, 1]], [[0, 2]],
	[[1, 0]], [[1, 1]], [[1, 2]],
	[[2, 0]], [[2, 1]], [[2, 2]],

	# ─── NEW: Many same-time combinations (most requested style) ───
	# evade + jump
	[[2, 0, 0.5], [0, 1, 0.5]],
	[[2, 0, 0.5], [0, 2, 0.5]],
	[[2, 1, 0.5], [0, 0, 0.5]],
	[[2, 1, 0.5], [0, 2, 0.5]],
	[[2, 2, 0.5], [0, 0, 0.5]],
	[[2, 2, 0.5], [0, 1, 0.5]],

	# evade + slide
	[[2, 0, 0.5], [1, 1, 0.5]],
	[[2, 0, 0.5], [1, 2, 0.5]],
	[[2, 1, 0.5], [1, 0, 0.5]],
	[[2, 1, 0.5], [1, 2, 0.5]],
	[[2, 2, 0.5], [1, 0, 0.5]],
	[[2, 2, 0.5], [1, 1, 0.5]],

	# evade + evade (two lanes blocked, one free)
	[[2, 0, 0.45], [2, 1, 0.45]],
	[[2, 1, 0.45], [2, 2, 0.45]],
	[[2, 0, 0.45], [2, 2, 0.45]],

	# triple group — full wall feel but still one way out
	[[2, 0, 0.5], [2, 1, 0.5], [0, 2, 0.5]],
	[[2, 0, 0.5], [2, 2, 0.5], [0, 1, 0.5]],
	[[2, 1, 0.5], [2, 2, 0.5], [0, 0, 0.5]],
	[[2, 0, 0.5], [2, 1, 0.5], [1, 2, 0.5]],
	[[2, 0, 0.5], [2, 2, 0.5], [1, 1, 0.5]],
	[[2, 1, 0.5], [2, 2, 0.5], [1, 0, 0.5]],

	# ─── Sequences (different x) ─────────────────────────────────
	# jump chains
	[[0, 0, 0.25], [0, 0, 0.55], [0, 0, 0.85]],
	[[0, 1, 0.25], [0, 1, 0.55], [0, 1, 0.85]],
	[[0, 2, 0.25], [0, 2, 0.55], [0, 2, 0.85]],

	# slide chains
	[[1, 0, 0.3], [1, 0, 0.65]],
	[[1, 1, 0.3], [1, 1, 0.65]],
	[[1, 2, 0.3], [1, 2, 0.65]],

	# mixed chain same lane
	[[0, 1, 0.3], [1, 1, 0.7]],
	[[1, 2, 0.35], [0, 2, 0.75]],

	# staggered mixed groups
	[[2, 0, 0.4], [0, 2, 0.65]],
	[[2, 1, 0.42], [1, 0, 0.68]],
	[[0, 1, 0.38], [2, 2, 0.62]],
]

var prev_safe_lanes: Array[int] = [0, 1, 2]

# ────────────────────────────────────────────────
func spawn_obstacle(platform: Node3D) -> void:
	if randf() > spawn_chance:
		print_debug("→ EMPTY")
		prev_safe_lanes = [0, 1, 2]
		return

	var valid_patterns: Array = []
	for pattern in patterns:
		if is_valid_pattern(pattern):
			valid_patterns.append(pattern)

	if valid_patterns.is_empty():
		spawn_single_fallback(platform)
		return

	var chosen = valid_patterns[randi() % valid_patterns.size()]
	instantiate_pattern(platform, chosen)
	print_debug("Spawned: ", str(chosen), " | Next safe: ", prev_safe_lanes)

# ────────────────────────────────────────────────
func spawn_single_fallback(platform: Node3D) -> void:
	if prev_safe_lanes.is_empty():
		return
	var idx = prev_safe_lanes[randi() % prev_safe_lanes.size()]
	var typ = randi() % 3
	spawn_helper(platform, typ, LANES[idx], 0.0)
	print_debug("Fallback → type ", typ, " lane ", idx)

# ────────────────────────────────────────────────
func is_valid_pattern(pattern: Array) -> bool:
	var this_safe: Array[int] = []
	for i in LANE_INDICES:
		var blocked = false
		for obs in pattern:
			if obs.size() >= 2 and obs[1] == i:
				blocked = true
				break
		if not blocked:
			this_safe.append(i)

	for prev in prev_safe_lanes:
		if this_safe.has(prev):
			return true
	return false

# ────────────────────────────────────────────────
func instantiate_pattern(platform: Node3D, pattern: Array) -> void:
	for obs_data in pattern:
		if obs_data.size() < 2: continue

		var typ  = obs_data[0]
		var lane = obs_data[1]
		var z    = LANES[lane]

		var x: float
		if obs_data.size() > 2:
			# fixed relative position → same-time groups
			var rel = obs_data[2]
			x = 2.0 + rel * (PLATFORM_LENGTH - 4.0)
		else:
			match typ:
				0,1: x = randf_range(3.0,  PLATFORM_LENGTH - 3.0)
				2:   x = randf_range(1.5,  PLATFORM_LENGTH - 5.0)
				_:   x = randf_range(2.0,  PLATFORM_LENGTH - 2.0)

		spawn_helper(platform, typ, z, x)

	# Update safe lanes for next section
	prev_safe_lanes.clear()
	for i in LANE_INDICES:
		var blocked = false
		for obs in pattern:
			if obs.size() >= 2 and obs[1] == i:
				blocked = true
				break
		if not blocked:
			prev_safe_lanes.append(i)

# ────────────────────────────────────────────────
func spawn_helper(platform: Node3D, type_idx: int, lane_z: float, x_offset: float) -> void:
	var obs = obstacle_scene.instantiate()
	if not obs: return

	obs.set("obstacle_type", type_idx)

	var size: Vector3
	match type_idx:
		0: size = JUMP_OVER_SIZE
		1: size = SLIDE_UNDER_SIZE
		2: size = EVADE_SIZE
		_: size = Vector3.ONE

	var y: float
	match type_idx:
		0: y = size.y / 2.0 - 0.12   # low jump
		1: y = 1.2                   # floating slide
		2: y = size.y / 2.0
		_: y = size.y / 2.0

	obs.position = Vector3(x_offset, y, lane_z)

	# Debug visuals
	var mesh = obs.get_node_or_null("MeshInstance3D")
	if mesh:
		var box = BoxMesh.new()
		box.size = size
		mesh.mesh = box
		var mat = StandardMaterial3D.new()
		match type_idx:
			0: mat.albedo_color = Color(0.98, 0.18, 0.18)
			1: mat.albedo_color = Color(0.18, 0.45, 0.98)
			2: mat.albedo_color = Color(0.98, 0.88, 0.12)
		mesh.material_override = mat

	# Collision
	var col = obs.get_node_or_null("Area3D/CollisionShape3D")
	if col:
		var shape = BoxShape3D.new()
		shape.size = size
		col.shape = shape

	platform.add_child(obs)
