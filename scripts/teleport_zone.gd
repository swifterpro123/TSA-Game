extends Area2D
@onready var tut_bg: Parallax2D = $"../TutBG/Parallax2D"
@onready var sky_bg: Parallax2D = $"../SkyBG/Parallax2D"

const TARGET_POS := Vector2(8000, -10)

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.global_position = TARGET_POS
		body.velocity = Vector2.ZERO
		tut_bg.visible = false
		sky_bg.visible = true
		get_tree().root.get_node("Bgmusic").play_forest_music()
