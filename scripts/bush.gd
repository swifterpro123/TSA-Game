extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var direction_timer: Timer = $DirectionTimer

const SPEED := 120.0
const ROAM_SPEED := 60.0
const WAKEUP_RANGE := 150.0  # Range to detect player and wake up
const DEACTIVATE_RANGE := 250.0  # Range to go back to dormant
const ATTACK_DELAY := 0.5  # Delay before attack hitbox activates

var chase := false
var roaming := false
var dead := false
var awake := false  # New: track if bush has woken up
var is_waking := false  # New: track if currently playing wakeup animation
var is_attacking := false  # Track if currently attacking

var health := 80
var chase_range := 200.0
var stop_distance := 30.0

var player: Node2D
var dir := Vector2.LEFT

var flash_timer := 0.0
var flash_duration := 0.5
var flashing := false
var original_modulate := Color(1, 1, 1, 1)
var smoothing := 6.0

var can_attack := true
const ATTACK_COOLDOWN := 1.0

var is_knockback := false
var knockback_velocity := Vector2.ZERO

@export var slash_scene: PackedScene

@onready var attack_timer: Timer = Timer.new()
@onready var attack_delay_timer: Timer = Timer.new()

func _ready():
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	
	# Setup attack cooldown timer
	attack_timer.wait_time = ATTACK_COOLDOWN
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_timeout)
	add_child(attack_timer)
	
	# Setup attack delay timer
	attack_delay_timer.wait_time = ATTACK_DELAY
	attack_delay_timer.one_shot = true
	attack_delay_timer.timeout.connect(_activate_attack_hitbox)
	add_child(attack_delay_timer)
	
	# Connect animation finished
	sprite.animation_finished.connect(_on_animation_finished)
	
	# Disable hitbox initially
	hitbox.monitoring = false
	
	# Start as dormant bush
	sprite.play("idle")  # Assuming "idle" is the dormant bush animation

func _on_animation_finished():
	if sprite.animation == "wakeup":
		is_waking = false
		awake = true
		roaming = true
	elif sprite.animation == "attack":
		is_attacking = false
		hitbox.monitoring = false

func take_damage(amount: int) -> void:
	if dead:
		return
	
	# Wake up if hit while dormant
	if not awake and not is_waking:
		wake_up()
	
	health -= amount
	flash_red()
	if health <= 0:
		die()

func wake_up():
	is_waking = true
	awake = false
	sprite.play("wakeup")

func go_dormant():
	awake = false
	is_waking = false
	roaming = false
	chase = false
	is_attacking = false
	hitbox.monitoring = false
	velocity.x = 0
	sprite.play("idle")
	attack_timer.stop()
	attack_delay_timer.stop()

func apply_knockback(direction: Vector2, force: float) -> void:
	if not awake:  # Don't knockback if not awake yet
		return
	is_knockback = true
	knockback_velocity = direction * force

func die():
	dead = true
	queue_free()

func flash_red():
	flash_timer = flash_duration
	flashing = true
	sprite.modulate = Color(1, 0, 0, 1)

func _on_hitbox_body_entered(body):
	if not can_attack or not awake or not is_attacking:  # Only attack if awake and attacking
		return
	if body.is_in_group("player"):
		body.take_damage(1)
		spawn_slash_effect()
		can_attack = false
		attack_timer.start()

func spawn_slash_effect():
	if slash_scene == null:
		return
	var slash = slash_scene.instantiate()
	get_parent().add_child(slash)
	var offset := Vector2(20, 0)
	if sprite.flip_h:
		offset.x = -offset.x
		slash.scale.x = -1
	slash.global_position = global_position + offset

func _on_attack_cooldown_timeout():
	can_attack = true

func _activate_attack_hitbox():
	if dead or not is_attacking:
		return
	hitbox.monitoring = true

func start_attack():
	if not can_attack or is_attacking or not awake:
		return
	
	is_attacking = true
	sprite.play("attack")
	
	# Disable hitbox initially, enable after delay
	hitbox.monitoring = false
	attack_delay_timer.start()

func check_for_player():
	if player == null:
		return
	
	var distance := global_position.distance_to(player.global_position)
	
	# Wake up if player is close
	if not awake and not is_waking and distance <= WAKEUP_RANGE:
		wake_up()
	
	# Go dormant if player is far away
	if awake and distance > DEACTIVATE_RANGE:
		go_dormant()

func handle_chase(delta: float):
	if player == null or not awake:  # Only chase if awake
		return
	
	var distance := global_position.distance_to(player.global_position)
	if distance <= chase_range:
		chase = true
		roaming = false
		if distance > stop_distance:
			var direction_to_player := (player.global_position - global_position).normalized()
			var desired_velocity := Vector2(direction_to_player.x * SPEED, velocity.y)
			velocity.x = lerp(velocity.x, desired_velocity.x, delta * smoothing)
		else:
			velocity.x = lerp(velocity.x, 0.0, delta * smoothing)
			# Try to attack if close enough
			if can_attack and not is_attacking:
				start_attack()
	else:
		chase = false
		roaming = true
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
	
	# Check if player is nearby
	check_for_player()
	
	# Stay still when dormant or waking up
	if not awake and not is_waking:
		move_and_slide()
		return
	
	# Don't move while waking up or attacking
	if is_waking or is_attacking:
		velocity.x = 0
		move_and_slide()
		return
	
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
	
	# Animation and sprite flipping (only when awake and not attacking)
	if awake and sprite.animation != "attack" and sprite.animation != "wakeup":
		if abs(velocity.x) > 10:
			sprite.play("walk")
			# Flip sprite based on movement direction
			if velocity.x < 0:
				sprite.flip_h = true
			elif velocity.x > 0:
				sprite.flip_h = false
		else:
			sprite.play("idle")
	
	move_and_slide()

func _on_direction_timer_timeout():
	if roaming and not chase and awake:  # Only change direction if awake
		dir = -dir
