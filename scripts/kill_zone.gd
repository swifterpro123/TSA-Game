extends Area2D

func _on_body_entered(body):
	if body.is_in_group("player") and body.lives > 0:
		body.take_damage(body.lives)
