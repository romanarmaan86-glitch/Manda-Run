extends Node3D

# Number of platforms to maintain
const PLATFORM_COUNT := 7
const PLATFORM_LENGTH := 20.0 # x-size of platform
const DELETE_X := -12.0 # when platform goes past this x, delete it
const MOVE_SPEED := 10.0 # negative x movement speed

@export var platform_scene: PackedScene

var platforms: Array = []

func _ready():
	# Spawn initial platforms
	for i in PLATFORM_COUNT:
		spawn_platform(i)

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

func spawn_platform(index = -1):
	var new_platform = platform_scene.instantiate()
	
	# Calculate x position
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
