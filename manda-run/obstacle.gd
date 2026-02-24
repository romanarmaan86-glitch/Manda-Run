extends Node3D

enum ObstacleType {
	JUMP_OVER,   # 0
	SLIDE_UNDER, # 1
	EVADE,       # 2
	JUMP_AND_SLIDE # 3 (rare, ignore for now)
}

@export var obstacle_type : ObstacleType = ObstacleType.JUMP_OVER

func _on_area_3d_body_entered(body):
	if body.has_method("hit_obstacle"):  # Better than name check!
		check_player_action(body)

func check_player_action(player):
	match obstacle_type:
		ObstacleType.JUMP_OVER:
			if player.is_on_floor():
				player.hit_obstacle()
		ObstacleType.SLIDE_UNDER:
			if not player.is_sliding:
				player.hit_obstacle()
		ObstacleType.EVADE:
			# Narrow Z + random lane = auto-hit only if same lane!
			player.hit_obstacle()
		ObstacleType.JUMP_AND_SLIDE:
			if not (player.is_sliding and not player.is_on_floor()):
				player.hit_obstacle()
