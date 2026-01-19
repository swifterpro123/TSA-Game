extends CharacterBody2D
class_name DroneEnemy
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var direction_timer: Timer = $DirectionTimer
const SPEED := 120.0
const ROAM_SPEED := 60.0
var chase := false
var roaming := true
var dead := false
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
@onready var attack_timer: Timer = Timer.new()

var is_knockback := false  # New variable
var knockback_velocity := Vector2.ZERO  # New variable

func _ready():
	player = get_tree().get_first_node_in_group("player")
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	# setup attack cooldown timer
	attack_timer.wait_time = ATTACK_COOLDOWN
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_timeout)
	add_child(attack_timer)

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

func _on_hitbox_body_entered(body):
	if not can_attack:
		return
	if body.is_in_group("player"):
		body.take_damage(1)
		can_attack = false
		attack_timer.start()

func _on_attack_cooldown_timeout():
	can_attack = true

func handle_chase(delta: float):
	if player == null:
		return
	var distance := global_position.distance_to(player.global_position)
	if distance <= chase_range:
		chase = true
		roaming = false
		if distance > stop_distance:
			var desired_velocity := (player.global_position - global_position).normalized() * SPEED
			velocity = velocity.lerp(desired_velocity, delta * smoothing)
		else:
			velocity = velocity.lerp(Vector2.ZERO, delta * smoothing)
	else:
		chase = false
		roaming = true
		var roam_velocity := dir * ROAM_SPEED
		velocity = velocity.lerp(roam_velocity, delta * smoothing)

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
	
	# Handle knockback
	if is_knockback:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, delta * 8.0)
		if knockback_velocity.length() < 50:
			is_knockback = false
			knockback_velocity = Vector2.ZERO
	else:
		handle_chase(delta)
	
	# Flip sprite based on movement direction
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false
	
	move_and_slide()

func _on_direction_timer_timeout():
	if roaming and not chase:
		dir = -dir
