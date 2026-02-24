extends CharacterBody3D

# -----------------------
# CONFIG
# -----------------------
const LANES = [-1.5, 0.0, 1.5]  # Z positions of lanes
const JUMP_VELOCITY = 6.0
const GRAVITY = 20.0
const AIR_SLIDE_FALL_SPEED = 12.0
const SLIDE_TIME = 0.6
const NORMAL_HEIGHT = 1.6
const SLIDE_HEIGHT = 0.8
const LANE_LERP_SPEED = 10.0  # smooth lane movement

# -----------------------
# STATE
# -----------------------
var current_lane := 1
var is_sliding := false
var slide_timer := 0.0

@onready var collider := $CollisionShape3D

# -----------------------
# READY
# -----------------------
func _ready():
	position.z = LANES[current_lane]

# -----------------------
# PHYSICS PROCESS
# -----------------------
func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# Lane smoothing
	var target_z = LANES[current_lane]
	position.z = lerp(position.z, target_z, LANE_LERP_SPEED * delta)

	# Jump input
	if Input.is_action_just_pressed("ui_up") and is_on_floor() and not is_sliding:
		velocity.y = JUMP_VELOCITY

	# Slide timer logic
	if is_sliding:
		slide_timer -= delta

		# Faster fall when sliding in air
		if not is_on_floor() and velocity.y < 0:
			velocity.y = -AIR_SLIDE_FALL_SPEED

		# End slide
		if slide_timer <= 0.0:
			end_slide()

	# Move the player
	move_and_slide()

# -----------------------
# INPUT
# -----------------------
func _input(event):
	if event.is_action_pressed("ui_left"):
		move_left()
	elif event.is_action_pressed("ui_right"):
		move_right()
	elif event.is_action_pressed("ui_down"):
		start_slide()

# -----------------------
# LANE MOVEMENT
# -----------------------
func move_left():
	if is_sliding:
		end_slide()
	current_lane = max(current_lane - 1, 0)

func move_right():
	if is_sliding:
		end_slide()
	current_lane = min(current_lane + 1, LANES.size() - 1)

# -----------------------
# SLIDE MECHANIC
# -----------------------
func start_slide():
	if is_sliding or not is_on_floor():
		return

	is_sliding = true
	slide_timer = SLIDE_TIME

	var shape := collider.shape as CapsuleShape3D
	var tween = create_tween()
	tween.tween_property(shape, "height", SLIDE_HEIGHT, 0.1).set_trans(Tween.TRANS_SINE)

func end_slide():
	is_sliding = false

	var shape := collider.shape as CapsuleShape3D
	var tween = create_tween()
	tween.tween_property(shape, "height", NORMAL_HEIGHT, 0.1).set_trans(Tween.TRANS_SINE)

# -----------------------
# HELPER: Check lane (for obstacles)
# -----------------------
func is_in_center_lane():
	return current_lane == 1

# -----------------------
# OBSTACLE HIT
# -----------------------
func hit_obstacle():
	print("Hit obstacle!")  # replace with lose life / animation
