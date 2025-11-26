extends CharacterBody2D

class_name DroneEnemy

const speed = 10
var chase: bool

var health = 80
var healthMax = 80
var healthMin = 0

var dead: bool = false
var takingDamage: bool = false
#var damage_to_deal = 10 #IF WE WANT HP BAR INSTEAD OF HK LIVES SYSTEM
var dealingDamage: bool = false

var dir: Vector2
const gravity = 900
var knockback = 200
var roaming: bool = true

func _process(delta: float) -> void:
	#if !is_on_floor(): #FOR ENEMIES ON THE GROUND
		#velocity.y += gravity * delta
		#velocity.x = 0
	move(delta)
	move_and_slide()

func move(delta) -> void:
	if !dead:
		if !chase:
			velocity += dir * speed * delta
		roaming = true
	elif dead:
		velocity.x = 0

func _on_direction_timer_timeout() -> void:
	var newTime = choose([1.5,2.0,2.5])
	$DirectionTimer.stop()
	$DirectionTimer.wait_time = newTime
	$DirectionTimer.start()
	if !chase:
		dir = choose([Vector2.RIGHT, Vector2.LEFT])
		velocity.x = 0

func choose(array):
	array.shuffle()
	return array.front()
