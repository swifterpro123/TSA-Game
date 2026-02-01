extends Area2D

var speed := 200.0
var direction := Vector2.RIGHT
var damage := 1

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(damage)
		queue_free()  # Destroy projectile after hit
	elif body is TileMap or body is StaticBody2D:
		queue_free()  # Destroy if hits wall

func set_direction(dir: Vector2):
	direction = dir.normalized()
