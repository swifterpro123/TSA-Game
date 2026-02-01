extends Area2D
@onready var tut_bg: Node2D = $"../../TutBG"
@onready var sky_bg: Node2D = $"../../SkyBG"


const TARGET_POS := Vector2(8000, -10)
@export var respawn_offset := Vector2(80, 0)
@export var checkpoint_index: int = 1

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		get_parent().set_checkpoint(checkpoint_index, global_position + respawn_offset)
		body.global_position = TARGET_POS
		body.velocity = Vector2.ZERO
		tut_bg.visible = false
		sky_bg.visible = true
		get_tree().root.get_node("Bgmusic").play_forest_music()
