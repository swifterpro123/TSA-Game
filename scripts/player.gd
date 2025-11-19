extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var is_slashing: bool = false

func _ready() -> void:
	animated_sprite.animation_finished.connect(Callable(self, "_on_animation_finished"))

func _on_animation_finished() -> void:
	if animated_sprite.animation == "slash":
		is_slashing = false
		animated_sprite.play('idle')

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("slash") and not is_slashing:
		is_slashing = true
		animated_sprite.play("slash")

	# movement input
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
