extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var speed := 200.0
var direction := Vector2.RIGHT
var damage := 2

var is_active := false
var activation_timer := 0.0
var has_hit_player := false

var lifetime := 3.0
var life_timer := 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	
	if sprite:
		sprite.play("beam")

func start_with_delay(delay: float):
	activation_timer = delay
	is_active = false

func _physics_process(delta):
	if not is_active:
		activation_timer -= delta
		if activation_timer <= 0:
			is_active = true
	
	if is_active:
		position += direction * speed * delta
	
	life_timer += delta
	if life_timer >= lifetime:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player") and not has_hit_player:
		body.take_damage(damage)
		has_hit_player = true
	elif body is TileMap or body is StaticBody2D:
		queue_free()

func set_direction(dir: Vector2):
	direction = dir.normalized()
	if dir.x < 0:
		rotation = PI
