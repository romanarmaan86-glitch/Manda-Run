# ObstacleSpawner.gd
extends Node3D

@export var train_scene: PackedScene
@export var jump_obstacle_scene: PackedScene
@export var slide_obstacle_scene: PackedScene

@export var lanes: Array[Vector3] = [
	Vector3(-4.8, 0.4, 0.0),
	Vector3( 0.0, 0.4, 0.0),
	Vector3( 4.8, 0.4, 0.0),
]

@export var train_scale := Vector3(0.65, 1.0, 0.85)

@export_range(0.0, 1.0) var chance_of_two_trains: float = 0.70
@export var safe_every_nth: int = 5

func place_obstacles_on(platform: Node3D, platform_index: int) -> void:
	if platform_index % safe_every_nth == 0:
		return
	
	var r: float = randf()
	
	if r < chance_of_two_trains:
		var lane_order: Array[int] = [0, 1, 2]
		lane_order.shuffle()
		
		var train_lanes: Array[int] = lane_order.slice(0, 2)
		var free_lane: int = lane_order[2]
		
		for lane_idx: int in train_lanes:
			_spawn_train(platform, lane_idx)
		
		var obs_scene: PackedScene = \
			jump_obstacle_scene if randf() < 0.5 else slide_obstacle_scene
		_spawn_obstacle(platform, free_lane, obs_scene)
	
	elif r < 0.87:
		var train_lane: int = randi() % 3
		_spawn_train(platform, train_lane)
		
		var other_lane: int = randi() % 3
		while other_lane == train_lane:
			other_lane = randi() % 3
		
		var obs_scene: PackedScene = \
			jump_obstacle_scene if randf() < 0.55 else slide_obstacle_scene
		_spawn_obstacle(platform, other_lane, obs_scene)


func _spawn_train(platform: Node3D, lane_idx: int) -> void:
	if train_scene == null:
		return
	var train: Node3D = train_scene.instantiate()
	train.position = lanes[lane_idx]
	train.scale = train_scale
	platform.add_child(train)


func _spawn_obstacle(platform: Node3D, lane_idx: int, scene: PackedScene) -> void:
	if scene == null:
		return
	var obs: Node3D = scene.instantiate()
	obs.position = lanes[lane_idx]
	platform.add_child(obs)
