extends Node2D

@onready var forest: AudioStreamPlayer = $Forest
@onready var tutorial: AudioStreamPlayer = $Tutorial
@onready var menu: AudioStreamPlayer = $Menu
@onready var death: AudioStreamPlayer = $Death

func _ready():
	menu.play()
	forest.stop()
	tutorial.stop()
	death.stop()

func play_tutorial_music():
	menu.stop()
	forest.stop()
	tutorial.play()
	death.stop()

func play_menu_music():
	tutorial.stop()
	forest.stop()
	menu.play()
	death.stop()

func play_forest_music():
	menu.stop()
	tutorial.stop()
	forest.play()
	death.stop()
	
func play_death_music():
	menu.stop()
	tutorial.stop()
	forest.stop()
	death.play()
	
func stop_all():
	menu.stop()
	tutorial.stop()
	forest.stop()
	death.stop()
