extends Area2D

const TARGET_POS := Vector2(8000, -10)

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.global_position = TARGET_POS
		body.velocity = Vector2.ZERO
		print(body.global_position)
