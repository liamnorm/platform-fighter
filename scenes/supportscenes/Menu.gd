extends Node2D

var Mat

func _ready():
	Mat = $Sprite.get_material()


func _process(_delta):
	if Input.is_action_just_pressed("pause") || Input.is_action_just_pressed("select") || Input.is_action_just_pressed("attack"):
		start_game()
	if Input.is_action_just_pressed("right"):
		if Globals.playerskins[0] == Globals.NUM_OF_SKINS - 1:
			Globals.playerskins[0] = 0
		else:
			Globals.playerskins[0] = (Globals.playerskins[0] + 1) % Globals.NUM_OF_SKINS
	if Input.is_action_just_pressed("left"):
		if Globals.playerskins[0] == 0:
			Globals.playerskins[0] = Globals.NUM_OF_SKINS - 1
		else:
			Globals.playerskins[0] = (Globals.playerskins[0] - 1) % Globals.NUM_OF_SKINS
	Mat.set_shader_param("skin", Globals.playerskins[0])
	
	if Input.is_action_just_pressed("jump"):
		if Globals.NUM_OF_PLAYERS < 8:
			Globals.NUM_OF_PLAYERS += 1
	if Input.is_action_just_pressed("down"):
		if Globals.NUM_OF_PLAYERS > 1:
			Globals.NUM_OF_PLAYERS -= 1
			
	$Num_of_players.text = str(Globals.NUM_OF_PLAYERS) + " PLAYERS"

func start_game():
	var game = get_tree().change_scene("res://scenes/mainscene/World.tscn")
