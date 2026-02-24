extends Node3D

const LANES = [-1.5, 0.0, 1.5]

# Smaller/quick for jump/slide, LONG for EVADE (almost full 20u platform!)
const JUMP_OVER_SIZE = Vector3(1.2, 1.1, 0.9)
const SLIDE_UNDER_SIZE = Vector3(1.2, 0.6, 0.9)
const EVADE_SIZE = Vector3(18.0, 1.65, 0.8)  # WALL spanning platform!

@export var obstacle_scene: PackedScene
@export var spawn_chance := 0.5
@export var combo_chance := 0.75  # 75% for evade next to jump/slide

func spawn_obstacle(platform):
	if randf() > spawn_chance:
		return

	# Primary obstacle
	var type = randi() % 3  # 0=jump, 1=slide, 2=evade
	var lane_index = randi() % 3
	var lane_z = LANES[lane_index]
	var x_offset = randf_range(4.0, 12.0)  # Reaction time

	spawn_helper(platform, type, lane_z, x_offset)

	# 🔥 75% COMBO: Add EVADE "next to" (different lane) for jump/slide!
	if type < 2 and randf() < combo_chance:  # Only for jump(0)/slide(1)
		var other_lanes = [0, 1, 2]
		other_lanes.erase(lane_index)
		var other_index = other_lanes[randi() % other_lanes.size()]
		var other_z = LANES[other_index]
		var other_x = x_offset + randf_range(-1.0, 3.0)  # Slightly offset "next to"
		spawn_helper(platform, 2, other_z, other_x)  # EVADE wall!

func spawn_helper(platform, type: int, lane_z: float, x_offset: float):
	var obstacle = obstacle_scene.instantiate() as Node3D

	# Set type (for obstacle.gd logic)
	obstacle.obstacle_type = type  # 0=JUMP_OVER, 1=SLIDE_UNDER, 2=EVADE

	# Size
	var mesh_size: Vector3
	match type:
		0:
			mesh_size = JUMP_OVER_SIZE
		1:
			mesh_size = SLIDE_UNDER_SIZE
		2:
			mesh_size = EVADE_SIZE

	# Local position on PLATFORM
	obstacle.position = Vector3(x_offset, mesh_size.y / 2.0 + 0.01, lane_z)

	# Mesh: Reset & size + COLOR!
	var mesh = obstacle.get_node("MeshInstance3D")
	if mesh:
		mesh.mesh = BoxMesh.new()
		mesh.mesh.size = mesh_size
		mesh.scale = Vector3.ONE
		var mat = StandardMaterial3D.new()
		match type:
			0: mat.albedo_color = Color.RED
			1: mat.albedo_color = Color.BLUE
			2: mat.albedo_color = Color.YELLOW
		mesh.material_override = mat

	# Area3D detect box (slightly larger)
	var area_coll = obstacle.get_node("Area3D/CollisionShape3D")
	if area_coll:
		var box = BoxShape3D.new()
		box.size = mesh_size * 1.05
		area_coll.shape = box

	# Reparent: MOVES with platform!
	platform.add_child(obstacle)
	print("Obs: Type", type, "at x:", x_offset, "z:", lane_z)
