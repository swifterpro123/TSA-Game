extends CharacterBody2D

signal lives_changed(current_lives)

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const dashcd = 1
const jumps = 2
const DASH_SPEED = 2000.0
const DASH_TIME = 0.12

const MAX_LIVES := 5
var regen_timer := 0.0
const REGEN_INTERVAL := 20.0
var lives := MAX_LIVES
var currentjumps = 0
var dashDirection = Vector2.ZERO

var is_iframe = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dash_cooldown: Timer = $DashCooldown
@onready var dash: AnimatedSprite2D = $Dash
@onready var dash_sound: AudioStreamPlayer2D = $DashSound
@onready var double_jump_sfx: AudioStreamPlayer2D = $DoubleJumpSFX
@onready var slash_hitbox: Area2D = $SlashHitbox
@onready var damage_flash: ColorRect = get_tree().current_scene.get_node("CanvasLayer/DamageFlash")
var flash_timer := 0.0
var flash_duration := 0.2

var is_slashing := false
var can_dash := true
var is_rolling := false
var is_dashing := false
var dash_time_remaining := 0.0

func _ready() -> void:
	add_to_group("player")
	
	if dash.get_parent() != self:
		remove_child(dash)
		add_child(dash)

	lives = MAX_LIVES
	
	animated_sprite.animation_finished.connect(_on_main_sprite_finished)
	dash.animation_finished.connect(_on_dash_sprite_finished)
	dash_cooldown.wait_time = dashcd
	dash_cooldown.timeout.connect(_on_dash_cooldown_timeout)
	
	slash_hitbox.body_entered.connect(_on_slash_hitbox_body_entered)

	slash_hitbox.monitoring = false
	lives_changed.emit(lives)

func take_damage(amount := 1) -> void:
	if is_iframe == false:
		lives -= amount
		lives = max(lives, 0)
		lives_changed.emit(lives)

		regen_timer = 0.0

		flash_timer = flash_duration
		damage_flash.modulate.a = 1.0

	if lives <= 0:
		reset_player()

func reset_player() -> void:
	lives = MAX_LIVES
	regen_timer = 0.0
	lives_changed.emit(lives)
	global_position = get_tree().current_scene.get_node("SpawnPoint").global_position
	velocity = Vector2.ZERO

func _on_main_sprite_finished() -> void:
	if animated_sprite.animation == "slash":
		is_slashing = false
	if animated_sprite.animation == "roll":
		is_rolling = false

func update_slash_hitbox():
	var offset_x := 100.0
	slash_hitbox.position = Vector2(
		offset_x if animated_sprite.flip_h else -offset_x,
		0
	)

func _on_dash_sprite_finished() -> void:
	dash.visible = false
	is_iframe = false
	
func _on_slash_hitbox_body_entered(body):
	print("HIT:", body.name)
	if body is DroneEnemy:
		body.take_damage(25)

func _on_dash_cooldown_timeout() -> void:
	can_dash = true

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	update_slash_hitbox()

	slash_hitbox.monitoring = is_slashing

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		currentjumps = 1
	elif Input.is_action_just_pressed("jump") and not is_on_floor() and currentjumps < jumps:
		velocity.y = JUMP_VELOCITY
		double_jump_sfx.play()
		currentjumps += 1
		is_rolling = true
		is_slashing = false
		animated_sprite.play("roll")
	elif is_on_floor():
		currentjumps = 0

	if Input.is_action_just_pressed("slash") and not is_slashing and not is_rolling and not is_dashing:
		is_slashing = true
		animated_sprite.play("slash")

	if Input.is_action_just_pressed("dash") and not is_slashing and not is_rolling and not is_dashing and can_dash:
		can_dash = false
		is_iframe = true
		dash_cooldown.start()
		is_dashing = true
		dash_time_remaining = DASH_TIME

		if direction != 0:
			dashDirection = Vector2(direction, 0)
		else:
			dashDirection = Vector2(1, 0) if animated_sprite.flip_h else Vector2(-1, 0)

		dash_sound.play()
		velocity = dashDirection * DASH_SPEED
		
		dash.global_position = global_position
		dash.visible = true
		dash.flip_h = dashDirection.x < 0
		dash.play("default")

	if not is_dashing:
		if direction != 0:
			velocity.x = direction * SPEED
			animated_sprite.flip_h = direction > 0
			if not is_rolling and not is_slashing:
				animated_sprite.play("run")
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			if not is_rolling and not is_slashing:
				animated_sprite.play("idle")
	else:
		dash_time_remaining -= delta
		if dash_time_remaining <= 0:
			is_dashing = false
			velocity.x = 0
			
	if flash_timer > 0:
		flash_timer -= delta
		damage_flash.modulate.a = lerp(damage_flash.modulate.a, 0.0, float(delta) * 10)
	else:
		damage_flash.modulate.a = 0
		
	if lives < MAX_LIVES:
		regen_timer += delta
		if regen_timer >= REGEN_INTERVAL:
			lives += 1
			lives = min(lives, MAX_LIVES)
			lives_changed.emit(lives)
			regen_timer = 0.0

	move_and_slide()
