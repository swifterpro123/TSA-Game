extends CharacterBody2D
class_name DroneEnemy

const SPEED := 120
const ROAM_SPEED := 60
var chase: bool = false
var health := 80
var dead := false
var player: Node2D
var dir: Vector2 = Vector2.LEFT
var roaming := true
var chase_range: float = 200.0
var stop_distance: float = 30.0  # NEW: Stop this far from player

func _ready():
	player = get_tree().get_first_node_in_group("player")
	if player:
		print("Player found: ", player.name)
	else:
		print("WARNING: No player found!")
	
func handle_chase():
	if player == null:
		return
		
	var distance = global_position.distance_to(player.global_position)
	
	if distance <= chase_range:
		chase = true
		roaming = false
		
		# NEW: Only move if outside stopping distance
		if distance > stop_distance:
			dir = (player.global_position - global_position).normalized()
			velocity = dir * SPEED
		else:
			# Stop when close enough
			velocity = Vector2.ZERO
	else:
		chase = false
		roaming = true
		velocity = dir * ROAM_SPEED

func _physics_process(_delta):
	if dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	handle_chase()
	move_and_slide()

func choose(array):
	array.shuffle()
	return array.front()

func _on_direction_timer_timeout() -> void:
	var new_time = choose([1.5, 2.0, 2.5])
	$DirectionTimer.wait_time = new_time
	$DirectionTimer.start()
	
	if roaming and not chase:
		dir = choose([Vector2.RIGHT, Vector2.LEFT])
