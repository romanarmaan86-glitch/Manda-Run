extends Node3D

# -----------------------
# CONFIG
# -----------------------
const PLATFORM_COUNT := 7          # How many platforms to maintain
const PLATFORM_LENGTH := 20.0      # X-size of each platform (mesh = 20)
const DELETE_X := -12.0            # Delete platform when it moves past this X
const MOVE_SPEED := 10.0           # Negative X movement speed
const LANES = [-1.5, 0.0, 1.5]

@export var platform_scene: PackedScene

# -----------------------
# STATE
# -----------------------
var platforms: Array = []

# -----------------------
# READY
# -----------------------
func _ready():
	# Spawn initial platforms
	for i in PLATFORM_COUNT:
		spawn_platform(i)

# -----------------------
# PHYSICS PROCESS
# -----------------------
func _physics_process(delta):
	for platform in platforms.duplicate():
		if platform:
			# Move platform
			platform.position.x -= MOVE_SPEED * delta

			# Delete if out of bounds
			if platform.position.x < DELETE_X:
				platform.queue_free()
				platforms.erase(platform)
				# Spawn a new one at the end
				spawn_platform()

# -----------------------
# SPAWN PLATFORM
# -----------------------
func spawn_platform(index := -1):
	var new_platform = platform_scene.instantiate()

	# Calculate X position
	var last_x = 0.0
	if platforms.size() > 0:
		last_x = platforms[-1].position.x + PLATFORM_LENGTH 
	elif index >= 0:
		last_x = index * PLATFORM_LENGTH
	else:
		last_x = 0.0

	new_platform.position = Vector3(last_x, 0, 0)
	add_child(new_platform)
	platforms.append(new_platform)

# -----------------------
# SPAWN OBSTACLE
# -----------------------
func spawn_obstacle(platform):
	# Chance to spawn an obstacle on this platform
	var chance = 0.5
	if randf() > chance:
		return

	var obstacle_scene = preload("res://Obstacle.tscn")
	var obstacle = obstacle_scene.instantiate() as Node3D

	# Random type
	obstacle.obstacle_type = randi() % 4  # 0..3

	# Random lane
	var lane_index = randi() % LANES.size()
	var lane_z = LANES[lane_index]

	# Position obstacle on top of platform
	obstacle.position = platform.position + Vector3(0, 0.5, lane_z)
	add_child(obstacle)
