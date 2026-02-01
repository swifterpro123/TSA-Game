extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var direction_timer: Timer = $DirectionTimer
@onready var projectile_blast: AudioStreamPlayer2D = $ProjectileBlast

const SPEED := 120.0
const ROAM_SPEED := 60.0
const SHOOT_COOLDOWN := 3.0
const SHOOT_DELAY := 1  # Delay before actually shooting

var chase := false
var roaming := true
var dead := false
var health := 150
var chase_range := 200.0
var stop_distance := 100.0
var shoot_range := 300.0

var player: Node2D
var dir := Vector2.LEFT

var flash_timer := 0.0
var flash_duration := 0.5
var flashing := false
var original_modulate := Color(1, 1, 1, 1)
var smoothing := 6.0

var can_attack := true
var can_shoot := true
var is_attacking := false

var is_knockback := false
var knockback_velocity := Vector2.ZERO

@export var projectile_scene: PackedScene

@onready var attack_timer: Timer = Timer.new()
@onready var shoot_timer: Timer = Timer.new()
@onready var shoot_delay_timer: Timer = Timer.new()

func _ready():
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	
	# Setup shoot cooldown timer
	shoot_timer.wait_time = SHOOT_COOLDOWN
	shoot_timer.one_shot = true
	shoot_timer.timeout.connect(func(): can_shoot = true)
	add_child(shoot_timer)
	
	# Setup shoot delay timer (for animation)
	shoot_delay_timer.wait_time = SHOOT_DELAY
	shoot_delay_timer.one_shot = true
	shoot_delay_timer.timeout.connect(_spawn_projectile)
	add_child(shoot_delay_timer)
	
	# Connect to animation finished
	sprite.animation_finished.connect(_on_animation_finished)

func take_damage(amount: int) -> void:
	if dead:
		return
	health -= amount
	flash_red()
	if health <= 0:
		die()

func apply_knockback(direction: Vector2, force: float) -> void:
	is_knockback = true
	knockback_velocity = direction * force

func die():
	dead = true
	queue_free()

func flash_red():
	flash_timer = flash_duration
	flashing = true
	sprite.modulate = Color(1, 0, 0, 1)

func _on_attack_cooldown_timeout():
	can_attack = true

func _on_animation_finished():
	if sprite.animation == "attack":
		is_attacking = false

func shoot_projectile():
	if projectile_scene == null:
		return
	
	can_shoot = false
	is_attacking = true
	shoot_timer.start()
	
	# Play attack animation
	sprite.play("attack")
	projectile_blast.play()
	
	
	# Start delay timer to spawn projectile after 0.5 seconds
	shoot_delay_timer.start()

func _spawn_projectile():
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	
	# Shoot towards player
	var direction = (player.global_position - global_position).normalized()
	projectile.set_direction(direction)

func handle_chase(delta: float):
	if player == null:
		return
	var distance := global_position.distance_to(player.global_position)
	
	if distance <= chase_range:
		chase = true
		roaming = false
		
		# Shoot if in range and not currently attacking (removed stop_distance check)
		if distance <= shoot_range and can_shoot and not is_attacking:  # Removed: and distance > stop_distance
			shoot_projectile()
		
		# Don't move while attacking
		if not is_attacking:
			if distance > stop_distance:
				var direction_to_player := (player.global_position - global_position).normalized()
				var desired_velocity := Vector2(direction_to_player.x * SPEED, velocity.y)
				velocity.x = lerp(velocity.x, desired_velocity.x, delta * smoothing)
			else:
				velocity.x = lerp(velocity.x, 0.0, delta * smoothing)
		else:
			velocity.x = lerp(velocity.x, 0.0, delta * smoothing)
	else:
		chase = false
		roaming = true
		if not is_attacking:
			velocity.x = lerp(velocity.x, dir.x * ROAM_SPEED, delta * smoothing)

func _physics_process(delta):
	if flashing:
		flash_timer -= delta
		if flash_timer <= 0.0:
			flashing = false
			sprite.modulate = original_modulate
		else:
			sprite.modulate = sprite.modulate.lerp(original_modulate, delta * 5.0)
	
	if dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle knockback
	if is_knockback:
		velocity.x = knockback_velocity.x
		velocity.y = knockback_velocity.y
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, delta * 8.0)
		if knockback_velocity.length() < 50:
			is_knockback = false
			knockback_velocity = Vector2.ZERO
	else:
		handle_chase(delta)
	
	# Flip sprite based on movement direction (only when not attacking)
	if not is_attacking:
		if velocity.x < 0:
			sprite.flip_h = false
		elif velocity.x > 0:
			sprite.flip_h = true
	
	move_and_slide()

func _on_direction_timer_timeout():
	if roaming and not chase:
		dir = -dir
