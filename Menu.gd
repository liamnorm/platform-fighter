extends Node2D

func _ready():
	pass


func _process(delta):
	if Input.is_action_just_pressed("attack"):
		start_game()

func start_game():
	get_tree().change_scene("res://scenes/mainscene/World.tscn")
