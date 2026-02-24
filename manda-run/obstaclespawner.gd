extends Node3D

# -----------------------
# CONFIG
# -----------------------
const LANES = [-1.5, 0.0, 1.5]  # Z positions
const PLAYER_NORMAL_HEIGHT = 1.6
const PLAYER_SLIDE_HEIGHT = 0.8
const PLATFORM_HEIGHT = 0.0      # Y of platforms

# Obstacle sizes
const JUMP_OVER_SIZE = Vector3(2, 1.5, 1.5)      # X,Y,Z
const SLIDE_UNDER_SIZE = Vector3(2, 0.8, 1.5)
const EVADE_SIZE = Vector3(2, 2.0, 1.5)

@export var obstacle_scene: PackedScene

# Chance to spawn an obstacle per platform
@export var spawn_chance := 0.5

# -----------------------
# SPAWN OBSTACLE
# -----------------------
func spawn_obstacle(platform):
	if randf() > spawn_chance:
		return

	var obstacle = obstacle_scene.instantiate() as Node3D

	# Random lane
	var lane_index = randi() % LANES.size()
	var lane_z = LANES[lane_index]

	# Random type
	var type = randi() % 3
	var mesh_size = Vector3.ZERO
	match type:
		0:
			obstacle.name = "JumpOver"
			mesh_size = JUMP_OVER_SIZE
		1:
			obstacle.name = "SlideUnder"
			mesh_size = SLIDE_UNDER_SIZE
		2:
			obstacle.name = "Evade"
			mesh_size = EVADE_SIZE

	# Set position on platform
	obstacle.position = platform.position + Vector3(PLATFORM_HEIGHT + mesh_size.y/2, 0, lane_z)

	# Adjust MeshInstance3D scale
	var mesh = obstacle.get_node("MeshInstance3D")
	if mesh:
		mesh.scale = mesh_size

	# Adjust CollisionShape3D
	var coll = obstacle.get_node("CollisionShape3D")
	if coll:
		var box = BoxShape3D.new()
		box.size = mesh_size
		coll.shape = box

	# Add to scene
	add_child(obstacle)
