extends Area2D

@export var checkpoint_index := 3
const TARGET_POS := Vector2(39100.0, -65.0)
@onready var sky_bg: Node2D = $"../../SkyBG"
@onready var tut_bg: Node2D = $"../../TutBG"
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var volcano_bg: Node2D = $"../../VolcanoBG"

func _ready():
	body_entered.connect(_on_body_entered)
	print("Checkpoint ", checkpoint_index, " position:", collision_shape.global_position)

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("Checkpoint! Index:", checkpoint_index, "Position:", collision_shape.global_position)
		
		var checkpoints = get_tree().current_scene.get_node("Checkpoints")
		if checkpoints:
			checkpoints.set_checkpoint(checkpoint_index, Vector2(collision_shape.global_position.x -100, collision_shape.global_position.y))
		else:
			print("ERROR: Checkpoints node not found!")
		
		body.call_deferred("set", "global_position", TARGET_POS)
		body.call_deferred("set", "velocity", Vector2.ZERO)
		
		get_tree().root.get_node("Bgmusic").play_tutorial_music()
		tut_bg.visible = false
		sky_bg.visible = false
		volcano_bg.visible = true
