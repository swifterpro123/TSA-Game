extends Control

func _ready():
	visible = true

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		visible = false
		get_tree().root.get_node("Bgmusic").play_tutorial_music()
