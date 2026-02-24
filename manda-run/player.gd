extends CharacterBody3D

signal died

# ────────────────────────────────────────
# CONFIGURATION
# ────────────────────────────────────────
const LANES = [-1.5, 0.0, 1.5]

const JUMP_VELOCITY     = 6.0
const GRAVITY           = 20.0
const AIR_SLIDE_FALL_SPEED = 12.0

const SLIDE_TIME        = 0.6
const NORMAL_HEIGHT     = 1.6
const SLIDE_HEIGHT      = 0.8

const LANE_LERP_SPEED   = 12.0      # how fast we slide between lanes

const DEATH_Y           = -10.0

# ────────────────────────────────────────
# STATE
# ────────────────────────────────────────
var current_lane : int = 1          # 0 = left, 1 = center, 2 = right
var is_sliding   : bool = false
var slide_timer  : float = 0.0
var dead         : bool = false

@onready var collider : CollisionShape3D = $CollisionShape3D

# ────────────────────────────────────────
func _ready() -> void:
	position.z = LANES[current_lane]

# ────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector3.ZERO
		return

	# ─── Gravity ────────────────────────────────────────
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# ─── Faster fall when sliding in air ────────────────
	if is_sliding and not is_on_floor() and velocity.y < 0:
		velocity.y = -AIR_SLIDE_FALL_SPEED

	# ─── Smooth lane movement ───────────────────────────
	var target_z = LANES[current_lane]
	position.z = lerp(position.z, target_z, LANE_LERP_SPEED * delta)

	# ─── Jump ───────────────────────────────────────────
	if Input.is_action_just_pressed("ui_up") and is_on_floor() and not is_sliding:
		velocity.y = JUMP_VELOCITY

	# ─── Slide timer & end condition ────────────────────
	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			end_slide()

	# ─── Apply movement ─────────────────────────────────
	move_and_slide()

	# ─── Fall death ─────────────────────────────────────
	if global_position.y < DEATH_Y:
		hit_obstacle()

# ────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if dead:
		return

	if event.is_action_pressed("ui_left"):
		move_left()
	elif event.is_action_pressed("ui_right"):
		move_right()
	elif event.is_action_pressed("ui_down"):
		start_slide()

# ────────────────────────────────────────
func move_left() -> void:
	if is_sliding:
		end_slide()
	current_lane = max(current_lane - 1, 0)

func move_right() -> void:
	if is_sliding:
		end_slide()
	current_lane = min(current_lane + 1, LANES.size() - 1)

# ────────────────────────────────────────
func start_slide() -> void:
	if is_sliding or not is_on_floor() or dead:
		return

	is_sliding = true
	slide_timer = SLIDE_TIME

	var shape = collider.shape as CapsuleShape3D
	if shape:
		var tween = create_tween().set_trans(Tween.TRANS_SINE)
		tween.tween_property(shape, "height", SLIDE_HEIGHT, 0.15)

func end_slide() -> void:
	is_sliding = false

	var shape = collider.shape as CapsuleShape3D
	if shape:
		var tween = create_tween().set_trans(Tween.TRANS_SINE)
		tween.tween_property(shape, "height", NORMAL_HEIGHT, 0.15)

# ────────────────────────────────────────
func hit_obstacle() -> void:
	if dead:
		return

	dead = true
	died.emit()
	print("Player died! (obstacle / fall)")
	# You can also add particles, sound, animation freeze, etc. here
