extends Node2D

@onready var forest: AudioStreamPlayer = $Forest
@onready var tutorial: AudioStreamPlayer = $Tutorial
@onready var menu: AudioStreamPlayer = $Menu
@onready var death: AudioStreamPlayer = $Death
@onready var bossfight: AudioStreamPlayer = $Bossfight
@onready var end_music: AudioStreamPlayer = $EndMusic
@onready var volcano: AudioStreamPlayer = $Volcano
@onready var pre_boss: AudioStreamPlayer = $PreBoss
@onready var actual_forest: AudioStreamPlayer = $ActualForest

func _ready():
	menu.play()
	forest.stop()
	tutorial.stop()
	death.stop()
	bossfight.stop()
	end_music.stop()
	volcano.stop()
	pre_boss.stop()
	actual_forest.stop()

func play_tutorial_music():
	menu.stop()
	forest.stop()
	tutorial.play()
	death.stop()
	bossfight.stop()
	end_music.stop()
	volcano.stop()
	pre_boss.stop()
	actual_forest.stop()

func play_menu_music():
	tutorial.stop()
	forest.stop()
	menu.play()
	death.stop()
	bossfight.stop()
	end_music.stop()
	volcano.stop()
	pre_boss.stop()
	actual_forest.stop()
	
func play_volcano_music():
	tutorial.stop()
	forest.stop()
	menu.stop()
	death.stop()
	bossfight.stop()
	end_music.stop()
	volcano.play()
	pre_boss.stop()
	actual_forest.stop()
	
func play_actualforest_music():
	menu.stop()
	forest.stop()
	tutorial.stop()
	death.stop()
	bossfight.stop()
	end_music.stop()
	volcano.stop()
	pre_boss.stop()
	actual_forest.play()

func play_forest_music():
	menu.stop()
	tutorial.stop()
	forest.play()
	death.stop()
	bossfight.stop()
	end_music.stop()
	volcano.stop()
	pre_boss.stop()
	actual_forest.stop()
	
func play_death_music():
	menu.stop()
	tutorial.stop()
	forest.stop()
	death.play()
	bossfight.stop()
	end_music.stop()
	volcano.stop()
	pre_boss.stop()
	actual_forest.stop()
	
func play_boss_music():
	menu.stop()
	tutorial.stop()
	forest.stop()
	death.stop()
	bossfight.play()
	end_music.stop()
	volcano.stop()
	pre_boss.stop()
	actual_forest.stop()

func play_preboss_music():
	menu.stop()
	tutorial.stop()
	forest.stop()
	death.stop()
	bossfight.stop()
	end_music.stop()
	volcano.stop()
	pre_boss.play()
	actual_forest.stop()

func play_end_music():
	menu.stop()
	tutorial.stop()
	forest.stop()
	death.stop()
	bossfight.stop()
	end_music.play()
	volcano.stop()
	pre_boss.stop()
	actual_forest.stop()
	
func stop_all():
	menu.stop()
	tutorial.stop()
	forest.stop()
	death.stop()
	bossfight.stop()
	end_music.stop()
	volcano.stop()
	pre_boss.stop()
	actual_forest.stop()
