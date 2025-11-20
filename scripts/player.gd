extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const dashcd = 1.5
const jumps = 2
var currentjumps = 0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var is_slashing: bool = false
var can_dash: bool = true
@onready var dash_cooldown: Timer = $DashCooldown

func _ready() -> void:
	animated_sprite.animation_finished.connect(Callable(self, "_on_animation_finished"))
	dash_cooldown.wait_time = dashcd

func _on_animation_finished() -> void:
	if animated_sprite.animation == "slash":
		is_slashing = false
		animated_sprite.play('idle')

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		currentjumps += 1
	elif Input.is_action_just_pressed("jump") and not is_on_floor() and currentjumps < jumps:
		velocity.y = JUMP_VELOCITY
		currentjumps += 1
	elif is_on_floor():
		currentjumps = 0

	if Input.is_action_just_pressed("slash") and not is_slashing:
		is_slashing = true
		animated_sprite.play("slash")

	var direction := Input.get_axis("move_left", "move_right")

	if not is_slashing:
		if direction > 0:
			animated_sprite.flip_h = true
			animated_sprite.play("run")
		elif direction < 0:
			animated_sprite.flip_h = false
			animated_sprite.play("run")
		else:
			animated_sprite.play("idle")

	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
