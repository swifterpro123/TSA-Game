extends Node2D

var furthest_checkpoint := 0
var respawn_position := Vector2.ZERO

func _ready():
	var spawn = get_tree().current_scene.get_node("SpawnPoint")
	if spawn:
		respawn_position = spawn.global_position

func set_checkpoint(index: int, pos: Vector2):
	if index > furthest_checkpoint:
		furthest_checkpoint = index
		respawn_position = pos
		print("Checkpoint reached:", index)

func respawn_player(player):
	player.global_position = respawn_position + Vector2(0, -16)
	player.velocity = Vector2.ZERO
