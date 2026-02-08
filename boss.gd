extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var boss_bar: TextureRect = $"../../CanvasLayer/BossBar"
@onready var boss_bar_fill: ColorRect = $"../../CanvasLayer/BossBar/ColorRect"
@onready var end_screen: TextureRect = $"../../CanvasLayer/EndScreen"

const SPEED := 80.0
const SLASH_COOLDOWN := 2.0
const SLASH_DELAY := 1.0
const ORB_COOLDOWN := 3.0
const ORB_DELAY := 1.0

const SLASH_DASH_SPEED := 260.0
const SLASH_DASH_TIME := 0.15
const PLAYER_KNOCKBACK := 2500.0

var is_dashing := false
var dash_timer := 0.0
var dash_direction := 0

const MAX_HEALTH := 1500
var health := MAX_HEALTH
var dead := false
var player_is_dead := false  # New flag to track if player is dead

var detection_range := 300.0
var slash_range := 175.0
var orb_range := 300.0

var player: Node2D
var player_detected := false
var boss_music_started := false

var flash_timer := 0.0
var flash_duration := 0.5
var flashing := false
var original_modulate := Color(1, 1, 1, 1)
var smoothing := 6.0

var can_slash := true
var can_shoot_orb := true
var is_attacking := false
var is_slashing := false

var is_knockback := false
var knockback_velocity := Vector2.ZERO

@export var projectile_scene: PackedScene
@export var slash_scene: PackedScene

@onready var slash_timer: Timer = Timer.new()
@onready var slash_delay_timer: Timer = Timer.new()
@onready var orb_timer: Timer = Timer.new()
@onready var orb_delay_timer: Timer = Timer.new()

var initial_bar_width: float

func _ready():
	add_to_group("enemies")
	add_to_group("boss")
	player = get_tree().get_first_node_in_group("player")
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	
	# Disable hitbox monitoring initially
	hitbox.monitoring = false
	
	# Store initial bar width
	initial_bar_width = boss_bar_fill.size.x
	boss_bar.visible = false
	
	# Setup slash cooldown timer
	slash_timer.wait_time = SLASH_COOLDOWN
	slash_timer.one_shot = true
	slash_timer.timeout.connect(func(): can_slash = true)
	add_child(slash_timer)
	
	# Setup slash delay
	slash_delay_timer.wait_time = SLASH_DELAY
	slash_delay_timer.one_shot = true
	slash_delay_timer.timeout.connect(_enable_slash_hitbox)
	add_child(slash_delay_timer)
	
	# Setup orb cooldown timer
	orb_timer.wait_time = ORB_COOLDOWN
	orb_timer.one_shot = true
	orb_timer.timeout.connect(func(): can_shoot_orb = true)
	add_child(orb_timer)
	
	# Setup orb delay timer
	orb_delay_timer.wait_time = ORB_DELAY
	orb_delay_timer.one_shot = true
	orb_delay_timer.timeout.connect(_spawn_orb)
	add_child(orb_delay_timer)
	
	# Connect animation finished
	sprite.animation_finished.connect(_on_animation_finished)
	
	# Connect to player signals
	if player:
		player.connect("player_died", _on_player_died)
		player.connect("player_respawned", _on_player_respawned)

func _on_player_died():
	# Completely stop boss when player dies
	player_is_dead = true
	player_detected = false
	boss_music_started = false
	is_attacking = false
	is_slashing = false
	is_dashing = false
	set_deferred("monitoring", false)
	velocity.x = 0
	sprite.play("walk")
	boss_bar.visible = false
	
	# Stop all timers
	slash_timer.stop()
	slash_delay_timer.stop()
	orb_timer.stop()
	orb_delay_timer.stop()

func _on_player_respawned():
	# Allow boss to be re-engaged after respawn
	player_is_dead = false
	health = MAX_HEALTH
	update_boss_bar()

func update_boss_bar():
	var health_percent = float(health) / float(MAX_HEALTH)
	boss_bar_fill.size.x = initial_bar_width * health_percent

func take_damage(amount: int) -> void:
	if dead or player_is_dead:  # Don't take damage if player is dead
		return
	health -= amount
	health = max(health, 0)
	update_boss_bar()
	flash_red()
	if health <= 0:
		die()

func apply_knockback(_direction: Vector2, _force: float) -> void:
	# Boss ignores knockback completely
	pass

func die():
	dead = true
	boss_bar.visible = false
	end_screen.visible = true
	get_tree().root.get_node("Bgmusic").play_end_music()
	queue_free()

func flash_red():
	flash_timer = flash_duration
	flashing = true
	sprite.modulate = Color(1, 0, 0, 1)

func _on_hitbox_body_entered(body):
	if not can_slash or not is_slashing or player_is_dead:  # Don't attack if player is dead
		return
	if body.is_in_group("player"):
		body.take_damage(1)
		
		# Apply knockback to player
		var knockback_dir = (body.global_position - global_position).normalized()
		body.is_knockback = true
		body.knockback_velocity = knockback_dir * PLAYER_KNOCKBACK
		
		spawn_slash_effect()
		can_slash = false
		slash_timer.start()

func spawn_slash_effect():
	if slash_scene == null:
		return
	var slash = slash_scene.instantiate()
	get_parent().add_child(slash)
	var offset := Vector2(40, 0)
	if sprite.flip_h:
		offset.x = -offset.x
		slash.scale.x = -1
	slash.global_position = global_position + offset

func _on_animation_finished():
	if sprite.animation == "slash":
		is_slashing = false
		is_attacking = false
		is_dashing = false
		hitbox.monitoring = false
	elif sprite.animation == "orb":
		is_attacking = false

func slash_attack():
	if not can_slash or is_attacking or player_is_dead:  # Don't attack if player is dead
		return

	is_attacking = true
	is_slashing = true
	sprite.play("slash")

	# Start dash
	is_dashing = true
	dash_timer = SLASH_DASH_TIME

	dash_direction = 1
	if not sprite.flip_h:
		dash_direction = -1

	# Delay hitbox activation
	hitbox.monitoring = false
	slash_delay_timer.start()
	
func _enable_slash_hitbox():
	if dead or not is_slashing or player_is_dead:  # Don't enable if player is dead
		return
	hitbox.monitoring = true

func orb_attack():
	if not can_shoot_orb or is_attacking or projectile_scene == null or player_is_dead:  # Don't attack if player is dead
		return
	
	is_attacking = true
	can_shoot_orb = false
	orb_timer.start()
	sprite.play("orb")
	orb_delay_timer.start()

func _spawn_orb():
	if projectile_scene == null or player_is_dead:  # Don't spawn if player is dead
		return
	
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	
	# Shoot towards player
	if player:
		var direction = (player.global_position - global_position).normalized()
		projectile.set_direction(direction)

func handle_boss_behavior(delta: float):
	if player == null or player_is_dead:  # Stop behavior if player is dead
		sprite.play("walk")
		velocity.x = 0
		return
	
	var distance := global_position.distance_to(player.global_position)
	
	# Detect player
	if distance <= detection_range:
		if not player_detected:
			player_detected = true
			boss_bar.visible = true
			# Start boss music when player is first detected
			if not boss_music_started:
				boss_music_started = true
				get_tree().root.get_node("Bgmusic").play_boss_music()
	
	# Only act if player is detected
	if not player_detected:
		sprite.play("walk")
		velocity.x = 0
		return
	
	# Face the player
	if player.global_position.x < global_position.x:
		sprite.flip_h = false
	else:
		sprite.flip_h = true
	
	# Choose attack based on distance
	if not is_attacking:
		if distance <= slash_range:
			slash_attack()
			velocity.x = 0
		elif distance <= orb_range:
			orb_attack()
			velocity.x = 0
		else:
			var direction_to_player := (player.global_position - global_position).normalized()
			velocity.x = lerp(velocity.x, direction_to_player.x * SPEED, delta * smoothing)
			if not is_attacking:
				sprite.play("walk")
	else:
		velocity.x = lerp(velocity.x, 0.0, delta * smoothing)

func _physics_process(delta):
	if flashing:
		flash_timer -= delta
		if flash_timer <= 0.0:
			flashing = false
			sprite.modulate = original_modulate
		else:
			sprite.modulate = sprite.modulate.lerp(original_modulate, delta * 5.0)
	
	if dead or player_is_dead:  # Stop all movement if player is dead
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if is_dashing:
		dash_timer -= delta
		velocity.x = dash_direction * SLASH_DASH_SPEED

		if dash_timer <= 0.0:
			is_dashing = false
			velocity.x = 0

		move_and_slide()
		return
	
	if is_knockback:
		is_knockback = false
		knockback_velocity = Vector2.ZERO
	
	handle_boss_behavior(delta)
	
	move_and_slide()
