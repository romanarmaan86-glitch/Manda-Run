extends Node3D

enum ObstacleType {
	JUMP_OVER,
	SLIDE_UNDER,
	EVADE,
	JUMP_AND_SLIDE
}

@export var obstacle_type : ObstacleType

# Connect this to Area3D → body_entered
func _on_area_3d_body_entered(body):
	if body.name == "Player":
		check_player_action(body)

func check_player_action(player):
	match obstacle_type:
		ObstacleType.JUMP_OVER:
			# Player must be in air (jumping) to avoid
			if player.is_on_floor():
				player.hit_obstacle()
		ObstacleType.SLIDE_UNDER:
			# Player must be sliding
			if not player.is_sliding:
				player.hit_obstacle()
		ObstacleType.EVADE:
			# Player must not be in center lane
			if player.is_in_center_lane():
				player.hit_obstacle()
		ObstacleType.JUMP_AND_SLIDE:
			# Player must be jumping AND sliding (combo)
			if not (player.is_sliding and not player.is_on_floor()):
				player.hit_obstacle()
