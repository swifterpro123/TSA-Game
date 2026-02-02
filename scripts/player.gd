extends CharacterBody2D

signal lives_changed(current_lives)

# =====================
# CONSTANTS
# =====================
const SPEED := 300.0
const JUMP_VELOCITY := -400.0
const DASH_COOLDOWN := 1.0
const MAX_JUMPS := 2
const DASH_SPEED := 2000.0
const DASH_TIME := 0.12
const KNOCKBACK_FORCE := 100.0

const MAX_LIVES := 5
const REGEN_INTERVAL := 20.0
const CHECKPOINT_SPAWN_OFFSET := Vector2(0, -32)

@onready var sky_bg: Node2D = $"../SkyBG"
@onready var tut_bg: Node2D = $"../TutBG"
@onready var death_screen: TextureRect = $"../CanvasLayer/DeathScreen"


# =====================
# STATE
# =====================
var lives := MAX_LIVES
var regen_timer := 0.0

var current_jumps := 0
var dash_direction := Vector2.ZERO

var is_iframe := false
var is_knockback := false
var knockback_velocity := Vector2.ZERO

var is_slashing := false
var is_rolling := false
var is_dashing := false
var can_dash := true
var dash_time_remaining := 0.0

var last_checkpoint_pos: Vector2

# =====================
# NODES
# =====================
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dash_sprite: AnimatedSprite2D = $Dash
@onready var dash_cooldown: Timer = $DashCooldown
@onready var dash_sound: AudioStreamPlayer2D = $DashSound
@onready var double_jump_sfx: AudioStreamPlayer2D = $DoubleJumpSFX
@onready var slash_hitbox: Area2D = $SlashHitbox
@onready var hit_sfx: AudioStreamPlayer2D = $HitSFX
@onready var damage_flash: ColorRect = get_tree().current_scene.get_node("CanvasLayer/DamageFlash")

# =====================
# DAMAGE FLASH
# =====================
var flash_timer := 0.0
const FLASH_DURATION := 0.2

# =====================
# READY
# =====================
func _ready() -> void:
	add_to_group("player")

	lives = MAX_LIVES
	var spawn = get_tree().current_scene.get_node("SpawnPoint")
	if spawn:
		last_checkpoint_pos = spawn.global_position + CHECKPOINT_SPAWN_OFFSET
	else:
		last_checkpoint_pos = global_position + CHECKPOINT_SPAWN_OFFSET

	dash_cooldown.wait_time = DASH_COOLDOWN
	dash_cooldown.timeout.connect(func(): can_dash = true)

	animated_sprite.animation_finished.connect(_on_main_anim_finished)
	dash_sprite.animation_finished.connect(func():
		dash_sprite.visible = false
		is_iframe = false
	)

	slash_hitbox.monitoring = false
	slash_hitbox.body_entered.connect(_on_slash_hitbox_body_entered)

	lives_changed.emit(lives)

# =====================
# DAMAGE / DEATH
# =====================
func take_damage(amount := 1) -> void:
	if is_iframe:
		return

	hit_sfx.play()
	lives -= amount
	lives = max(lives, 0)
	lives_changed.emit(lives)

	regen_timer = 0.0
	flash_timer = FLASH_DURATION
	damage_flash.modulate.a = 1.0

	if lives <= 0:
		get_tree().root.get_node("Bgmusic").play_death_music()
		death_screen.visible = true

func respawn() -> void:
	lives = MAX_LIVES
	regen_timer = 0.0
	lives_changed.emit(lives)

	call_deferred("_do_respawn")

func set_checkpoint(pos: Vector2) -> void:
	last_checkpoint_pos = pos + CHECKPOINT_SPAWN_OFFSET
	print("Player checkpoint set to:", last_checkpoint_pos)

func _do_respawn() -> void:
	print("Respawning at:", last_checkpoint_pos)
	global_position = last_checkpoint_pos
	velocity = Vector2.ZERO
	if last_checkpoint_pos == Vector2(4243.0,-42.0) or last_checkpoint_pos == Vector2(0.0,-32.0) or last_checkpoint_pos == Vector2(4243.0,-84.0):
		sky_bg.visible = false
		tut_bg.visible = true
		get_tree().root.get_node("Bgmusic").play_tutorial_music()
	elif last_checkpoint_pos == Vector2(19420.0, -281.0):
		sky_bg.visible = true
		tut_bg.visible = false
		get_tree().root.get_node("Bgmusic").play_tutorial_music()


# =====================
# SLASH
# =====================
func _on_slash_hitbox_body_entered(body) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(25)
		var dir: Vector2 = (body.global_position - global_position).normalized()
		body.apply_knockback(dir, KNOCKBACK_FORCE)

func update_slash_hitbox() -> void:
	var offset_x := 100.0
	slash_hitbox.position = Vector2(
		offset_x if animated_sprite.flip_h else -offset_x,
		0
	)

# =====================
# ANIMATION CALLBACKS
# =====================
func _on_main_anim_finished() -> void:
	if animated_sprite.animation == "slash":
		is_slashing = false
	if animated_sprite.animation == "roll":
		is_rolling = false

# =====================
# PHYSICS
# =====================
func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	update_slash_hitbox()
	slash_hitbox.monitoring = is_slashing

	# ---- Knockback ----
	if is_knockback:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, delta * 8.0)
		if knockback_velocity.length() < 40:
			is_knockback = false
	else:
		# Gravity
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Jump
		if Input.is_action_just_pressed("jump"):
			if is_on_floor():
				velocity.y = JUMP_VELOCITY
				current_jumps = 1
			elif current_jumps < MAX_JUMPS:
				velocity.y = JUMP_VELOCITY
				current_jumps += 1
				double_jump_sfx.play()
				is_rolling = true
				is_slashing = false
				animated_sprite.play("roll")

		if is_on_floor():
			current_jumps = 0

		# Slash
		if Input.is_action_just_pressed("slash") and not is_slashing and not is_rolling and not is_dashing:
			is_slashing = true
			animated_sprite.play("slash")

		# Dash
		if Input.is_action_just_pressed("dash") and can_dash and not is_dashing and not is_slashing and not is_rolling:
			can_dash = false
			is_dashing = true
			is_iframe = true
			dash_time_remaining = DASH_TIME
			dash_cooldown.start()

			dash_direction = Vector2(direction, 0) if direction != 0 else (
				Vector2(1, 0) if animated_sprite.flip_h else Vector2(-1, 0)
			)

			velocity = dash_direction * DASH_SPEED
			dash_sound.play()

			dash_sprite.global_position = global_position
			dash_sprite.visible = true
			dash_sprite.flip_h = dash_direction.x < 0
			dash_sprite.play("default")

		# Horizontal movement
		if not is_dashing:
			if direction != 0:
				velocity.x = direction * SPEED
				animated_sprite.flip_h = direction > 0
				if not is_slashing and not is_rolling:
					animated_sprite.play("run")
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				if not is_slashing and not is_rolling:
					animated_sprite.play("idle")
		else:
			dash_time_remaining -= delta
			if dash_time_remaining <= 0:
				is_dashing = false
				velocity.x = 0

	# ---- Damage Flash ----
	if flash_timer > 0:
		flash_timer -= delta
		damage_flash.modulate.a = lerp(damage_flash.modulate.a, 0.0, delta * 10)
	else:
		damage_flash.modulate.a = 0.0

	# ---- Health Regen ----
	if lives < MAX_LIVES:
		regen_timer += delta
		if regen_timer >= REGEN_INTERVAL:
			lives += 1
			lives = min(lives, MAX_LIVES)
			lives_changed.emit(lives)
			regen_timer = 0.0

	move_and_slide()
