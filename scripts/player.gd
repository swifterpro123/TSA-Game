extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const dashcd = 1
const jumps = 2
const DASH_SPEED = 2000.0
const DASH_TIME = 0.12

var currentjumps = 0
var dashDirection = Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var is_slashing: bool = false
var can_dash: bool = true
var is_rolling: bool = false
var is_dashing: bool = false
var dash_time_remaining: float = 0.0
@onready var dash_cooldown: Timer = $DashCooldown

func _ready() -> void:
	animated_sprite.animation_finished.connect(Callable(self, "_on_animation_finished"))
	dash_cooldown.wait_time = dashcd
	dash_cooldown.timeout.connect(Callable(self, "_on_dash_cooldown_timeout"))

func _on_animation_finished() -> void:
	if animated_sprite.animation == "slash":
		is_slashing = false
		animated_sprite.play('idle')
	if animated_sprite.animation == "roll":
		is_rolling = false
		animated_sprite.play("idle")

func _on_dash_cooldown_timeout() -> void:
	can_dash = true

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		currentjumps += 1
	elif Input.is_action_just_pressed("jump") and not is_on_floor() and currentjumps < jumps:
		velocity.y = JUMP_VELOCITY
		currentjumps += 1
		is_rolling = true
		animated_sprite.play("roll")
	elif is_on_floor():
		currentjumps = 0

	if Input.is_action_just_pressed("slash") and not is_slashing and not is_rolling and not is_dashing:
		is_slashing = true
		animated_sprite.play("slash")
		
	if Input.is_action_just_pressed("dash") and not is_slashing and not is_rolling and not is_dashing and can_dash:
		can_dash = false
		dash_cooldown.start()
		is_dashing = true
		dash_time_remaining = DASH_TIME
		if direction != 0:
			dashDirection = Vector2(direction, 0)
		else:
			dashDirection = Vector2(1, 0) if animated_sprite.flip_h else Vector2(-1, 0)
		velocity = dashDirection.normalized() * DASH_SPEED

	if not is_slashing and not is_dashing:
		if direction > 0:
			animated_sprite.flip_h = true
			if not is_rolling:
				dashDirection = Vector2(1,0)
				animated_sprite.play("run")
		elif direction < 0:
			dashDirection = Vector2(-1,0)
			animated_sprite.flip_h = false
			if not is_rolling:
				animated_sprite.play("run")
		else:
			if not is_rolling:
				animated_sprite.play("idle")

	if not is_dashing:
		if direction != 0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		dash_time_remaining -= delta
		if dash_time_remaining <= 0.0:
			is_dashing = false
			velocity.x = 0
			if not is_slashing and not is_rolling:
				animated_sprite.play("idle")

	move_and_slide()
