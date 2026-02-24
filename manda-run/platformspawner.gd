# platformspawner.gd (FULL - No changes, but full for completeness)
extends Node3D

const PLATFORM_COUNT := 7
const PLATFORM_LENGTH := 20.0
const DELETE_X := -12.0
const MOVE_SPEED := 10.0

@export var platform_scene: PackedScene

var platforms: Array[Node3D] = []

func _ready() -> void:
	for i in PLATFORM_COUNT:
		spawn_platform(i)

func _physics_process(delta: float) -> void:
	for platform in platforms.duplicate():
		if platform == null or not is_instance_valid(platform):
			platforms.erase(platform)
			continue
		
		platform.position.x -= MOVE_SPEED * delta
		
		if platform.position.x < DELETE_X:
			platform.queue_free()
			platforms.erase(platform)
			spawn_platform()

func spawn_platform(index: int = -1) -> void:
	var new_platform = platform_scene.instantiate() as Node3D
	if new_platform == null:
		printerr("Failed to instantiate platform_scene!")
		return
	
	var last_x := 0.0
	if platforms.size() > 0:
		last_x = platforms.back().position.x + PLATFORM_LENGTH
	elif index >= 0:
		last_x = index * PLATFORM_LENGTH
	
	new_platform.position = Vector3(last_x, 0, 0)
	add_child(new_platform)
	platforms.append(new_platform)
	
	var obs_spawner = get_parent().get_node_or_null("obstaclespawner")
	if obs_spawner:
		obs_spawner.spawn_obstacle(new_platform)
		print("Platform created at x = ", last_x, " – requested obstacle spawn")
	else:
		printerr("obstaclespawner node not found! Check scene tree naming.")
