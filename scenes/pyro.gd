extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var projectile_blast: AudioStreamPlayer2D = $ProjectileBlast

const SHOOT_COOLDOWN := 3.0
const SHOOT_ANIMATION_TIME := 1.0
const BEAM_SPAWN_DELAY := 1.0
const BEAM_PHYSICS_DELAY := 0.5

var dead := false
var health := 100
var shoot_range := 400.0

var player: Node2D

var flash_timer := 0.0
var flash_duration := 0.5
var flashing := false
var original_modulate := Color(1, 1, 1, 1)

var can_shoot := true
var is_attacking := false

var is_knockback := false  # Added knockback support
var knockback_velocity := Vector2.ZERO  # Added knockback support

@export var projectile_scene: PackedScene

@onready var shoot_timer: Timer = Timer.new()
@onready var beam_spawn_timer: Timer = Timer.new()

func _ready():
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)
	
	shoot_timer.wait_time = SHOOT_COOLDOWN
	shoot_timer.one_shot = true
	shoot_timer.timeout.connect(func(): can_shoot = true)
	add_child(shoot_timer)
	
	beam_spawn_timer.wait_time = BEAM_SPAWN_DELAY
	beam_spawn_timer.one_shot = true
	beam_spawn_timer.timeout.connect(_spawn_projectile)
	add_child(beam_spawn_timer)
	
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)
		sprite.play("idle")

func take_damage(amount: int) -> void:
	if dead:
		return
	health -= amount
	flash_red()
	if health <= 0:
		die()

func apply_knockback(direction: Vector2, force: float) -> void:
	# Added this function so player can attack the pyro
	is_knockback = true
	knockback_velocity = direction * force

func die():
	dead = true
	queue_free()

func flash_red():
	flash_timer = flash_duration
	flashing = true
	sprite.modulate = Color(1, 0, 0, 1)

func _on_hitbox_body_entered(_body):
	pass

func _on_animation_finished():
	if sprite.animation == "attack":
		is_attacking = false
		sprite.play("idle")

func shoot_projectile():
	if projectile_scene == null:
		return
	
	can_shoot = false
	is_attacking = true
	shoot_timer.start()
	
	sprite.play("attack")
	if projectile_blast:
		projectile_blast.play()
	
	beam_spawn_timer.start()

func _spawn_projectile():
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	
	var direction = Vector2.RIGHT if not sprite.flip_h else Vector2.LEFT
	projectile.set_direction(direction)
	projectile.start_with_delay(BEAM_PHYSICS_DELAY)

func update_animation():
	if is_attacking:
		return
	
	if sprite.animation != "idle":
		sprite.play("idle")

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
		velocity.x = 0  # Pyro doesn't move on its own
	
	if player != null:
		var distance := global_position.distance_to(player.global_position)
		
		if not is_attacking:
			if player.global_position.x < global_position.x:
				sprite.flip_h = true
			else:
				sprite.flip_h = false
		
		if distance <= shoot_range and can_shoot and not is_attacking:
			shoot_projectile()
	
	update_animation()
	move_and_slide()
