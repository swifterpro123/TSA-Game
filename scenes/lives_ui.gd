extends HBoxContainer

@export var full_life: Texture2D
@export var broken_life: Texture2D

func _ready():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.lives_changed.connect(update_lives)

func update_lives(current_lives: int):
	for i in get_child_count():
		var icon = get_child(i) as TextureRect
		icon.texture = full_life if i < current_lives else broken_life
