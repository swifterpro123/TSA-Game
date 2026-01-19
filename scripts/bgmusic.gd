extends Node2D

@onready var forest: AudioStreamPlayer = $Forest
@onready var tutorial: AudioStreamPlayer = $Tutorial
@onready var menu: AudioStreamPlayer = $Menu

func _ready():
	menu.play()
	forest.stop()
	tutorial.stop()

func play_tutorial_music():
	menu.stop()
	forest.stop()
	tutorial.play()

func play_menu_music():
	tutorial.stop()
	forest.stop()
	menu.play()

func play_forest_music():
	menu.stop()
	tutorial.stop()
	forest.play()
