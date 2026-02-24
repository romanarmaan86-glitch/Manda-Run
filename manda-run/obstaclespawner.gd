extends Node3D

const LANES = [-1.5, 0.0, 1.5]
@export var obstacle_scene: PackedScene
@export var spawn_chance := 0.4  # 40% platforms get obs

# SMALLER sizes: X=1.4 (quick pass), Z=0.9 (lane-perfect, no overlap), Y tuned for actions
const JUMP_OVER_SIZE = Vector3(1.4, 1.1, 0.9)     # Jump: low enough (1.1 < 1.7 apex)
const SLIDE_UNDER_SIZE = Vector3(1.4, 0.65, 0.9)  # Slide: under 0.8 player
const EVADE_SIZE = Vector3(1.4, 1.65, 0.9)        # Evade: tall narrow (must lane switch)

func spawn_obstacle(platform):
	if randf() > spawn_chance: return

	var obstacle = obstacle_scene.instantiate() as Node3D

	# Random lane & type
	var lane_index = randi() % 3
	var lane_z = LANES[lane_index]
	var type = randi() % 3  # 0=jump,1=slide,2=evade

	var mesh_size: Vector3
	match type:
		0:
			obstacle.obstacle_type = obstacle.ObstacleType.JUMP_OVER
			mesh_size = JUMP_OVER_SIZE
		1:
			obstacle.obstacle_type = obstacle.ObstacleType.SLIDE_UNDER
			mesh_size = SLIDE_UNDER_SIZE
		2:
			obstacle.obstacle_type = obstacle.ObstacleType.EVADE
			mesh_size = EVADE_SIZE

	# LOCAL position: closer for reaction (3-10u ahead), center Y, lane Z
	var x_offset = randf_range(3.0, 10.0)
	obstacle.position = Vector3(x_offset, mesh_size.y / 2 + 0.01, lane_z)

	# 🔥 MESH: Create + size + COLOR (distinguish types!)
	var mesh_node = obstacle.get_node("MeshInstance3D")
	if mesh_node:
		mesh_node.mesh = BoxMesh.new()
		mesh_node.mesh.size = mesh_size  # Direct size!
		var mat = StandardMaterial3D.new()
		match type:
			0: mat.albedo_color = Color.RED      # Jump over
			1: mat.albedo_color = Color.BLUE     # Slide under
			2: mat.albedo_color = Color.YELLOW   # Evade (lane switch)
		mesh_node.material_override = mat

	# 🔥 AREA DETECT: Area3D/CollisionShape3D (not root!)
	var area_coll = obstacle.get_node("Area3D/CollisionShape3D")
	if area_coll:
		var box = BoxShape3D.new()
		box.size = mesh_size * 1.02  # Slight overlap for forgiving detect
		area_coll.shape = box

	# 🚀 REPARENT to PLATFORM: auto-move + delete!
	platform.add_child(obstacle)
	print("Obs spawned! Type: ", type, " Lane: ", lane_z, " Size: ", mesh_size)
