extends Node2D

var furthest_checkpoint := -1
var respawn_position := Vector2.ZERO

func _ready():
	var spawn = get_tree().current_scene.get_node("SpawnPoint")
	if spawn:
		respawn_position = spawn.global_position
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.set_checkpoint(Vector2(0,0))

func set_checkpoint(index: int, pos: Vector2):
	print("Trying to set checkpoint. Index:", index, "Pos:", pos, "Current furthest:", furthest_checkpoint)
	if index >= furthest_checkpoint:
		furthest_checkpoint = index
		respawn_position = pos
		
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.set_checkpoint(pos)
			print("Successfully set player checkpoint")
			
		print("Checkpoint reached:", index)
	else:
		print("Checkpoint", index, "ignored (not further than", furthest_checkpoint, ")")
