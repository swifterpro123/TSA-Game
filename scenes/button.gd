extends Button

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		get_parent().visible = false
		player.respawn()
