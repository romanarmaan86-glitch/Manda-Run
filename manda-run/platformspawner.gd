extends Node3D

const PLATFORM_COUNT := 7
const PLATFORM_LENGTH := 20.0
const DELETE_X := -12.0
const MOVE_SPEED := 10.0

@export var platform_scene: PackedScene

var platforms: Array = []

func _ready():
	for i in PLATFORM_COUNT:
		spawn_platform(i)

func _physics_process(delta):
	for platform in platforms.duplicate():
		if platform:
			platform.position.x -= MOVE_SPEED * delta
			if platform.position.x < DELETE_X:
				platform.queue_free()
				platforms.erase(platform)
				spawn_platform()

func spawn_platform(index = -1):
	var new_platform = platform_scene.instantiate()
	
	var last_x = 0.0
	if platforms.size() > 0:
		last_x = platforms[-1].position.x + PLATFORM_LENGTH
	elif index >= 0:
		last_x = index * PLATFORM_LENGTH
	
	new_platform.position = Vector3(last_x, 0, 0)
	add_child(new_platform)
	platforms.append(new_platform)
	
	# 🔥 SPAWN OBSTACLE HERE (40% chance)!
	var obs_spawner = get_parent().get_node("obstaclespawner")
	if obs_spawner:
		obs_spawner.spawn_obstacle(new_platform)
		print("Platform spawned - checking obs...")  # Debug: See in Output
