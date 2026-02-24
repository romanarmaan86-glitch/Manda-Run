extends Node3D

enum ObstacleType {
	JUMP_OVER,
	SLIDE_UNDER,
	EVADE,
	JUMP_AND_SLIDE
}

@export var obstacle_type: ObstacleType = ObstacleType.JUMP_OVER

func _on_area_3d_body_entered(body):
	if body.has_method("hit_obstacle"):  # Works for any player
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
			# SMALL Z → Area only triggers if SAME LANE! Auto-perfect dodge.
			player.hit_obstacle()  # Hit if overlapped (failed switch)
		ObstacleType.JUMP_AND_SLIDE:
			if not (player.is_sliding and not player.is_on_floor()):
				player.hit_obstacle()
