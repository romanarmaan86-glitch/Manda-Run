# obstacle.gd (FULL - No changes, full for completeness)
extends Node3D

enum ObstacleType {
	JUMP_OVER,    # 0
	SLIDE_UNDER,  # 1
	EVADE,        # 2
	JUMP_AND_SLIDE # 3 (not used)
}

@export var obstacle_type: ObstacleType = ObstacleType.JUMP_OVER

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_method("hit_obstacle"):
		check_player_action(body)

func check_player_action(player) -> void:
	match obstacle_type:
		ObstacleType.JUMP_OVER:
			if player.is_on_floor():
				player.hit_obstacle()
		ObstacleType.SLIDE_UNDER:
			if not player.is_sliding:
				player.hit_obstacle()
		ObstacleType.EVADE:
			player.hit_obstacle()  # Hit if overlapped (same lane)
		ObstacleType.JUMP_AND_SLIDE:
			if not (player.is_sliding and not player.is_on_floor()):
				player.hit_obstacle()
