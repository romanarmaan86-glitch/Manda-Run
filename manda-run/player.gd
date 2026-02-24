extends CharacterBody3D

const LANES = [-1.5, 0.0, 1.5]

const JUMP_VELOCITY = 6.0
const GRAVITY = 20.0
const AIR_SLIDE_FALL_SPEED = 12.0

const SLIDE_TIME = 0.6
const NORMAL_HEIGHT = 1.6
const SLIDE_HEIGHT = 0.8

var current_lane := 1
var is_sliding := false
var slide_timer := 0.0

@onready var collider := $CollisionShape3D

func _ready():
	position.z = LANES[current_lane]

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# Jump
	if Input.is_action_just_pressed("ui_up") and is_on_floor() and not is_sliding:
		velocity.y = JUMP_VELOCITY

	# Slide logic
	if is_sliding:
		slide_timer -= delta

		# Faster fall when sliding in air
		if not is_on_floor():
			velocity.y = -AIR_SLIDE_FALL_SPEED

		if slide_timer <= 0.0:
			end_slide()

	move_and_slide()

func _input(event):
	if event.is_action_pressed("ui_left"):
		move_left()
	elif event.is_action_pressed("ui_right"):
		move_right()
	elif event.is_action_pressed("ui_down"):
		start_slide()

func move_left():
	# Cancel slide if switching lanes
	if is_sliding:
		end_slide()

	current_lane = max(current_lane - 1, 0)
	position.z = LANES[current_lane]

func move_right():
	# Cancel slide if switching lanes
	if is_sliding:
		end_slide()

	current_lane = min(current_lane + 1, LANES.size() - 1)
	position.z = LANES[current_lane]

func start_slide():
	if is_sliding:
		return

	is_sliding = true
	slide_timer = SLIDE_TIME

	var shape := collider.shape as CapsuleShape3D
	shape.height = SLIDE_HEIGHT

func end_slide():
	is_sliding = false

	var shape := collider.shape as CapsuleShape3D
	shape.height = NORMAL_HEIGHT
