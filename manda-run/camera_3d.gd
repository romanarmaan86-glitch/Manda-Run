extends Camera3D

@onready var player: CharacterBody3D = $"../player"  # Sibling under World3D

@export var follow_speed: float = 12.0  # Tune smoothness (higher = snappier)
@export var height_offset: float = 2.5
@export var distance_behind: float = 6.0  # -X behind player
@export var look_ahead: float = 8.0  # Look forward +X for upcoming obstacles

func _process(delta: float) -> void:
	if not player:
		return
	
	# Target pos: behind (-X), up, same Z as player (centers lanes perfectly)
	var target_pos: Vector3 = player.global_position + Vector3(-distance_behind, height_offset, 0)
	
	# Smooth lerp to target (follows Y jumps, Z lanes instantly-ish)
	global_position = global_position.lerp(target_pos, follow_speed * delta)
	
	# Look at player + slight forward for dynamic view
	look_at(player.global_position + Vector3(look_ahead, 0, 0), Vector3.UP)
