extends Node2D

var Mat

func _ready():
	Mat = $Sprite.get_material()
	
	if Globals.WINNER == 0:
		$The_Winner.text = ""
		$Winner.text = "TIE"
	else:
		if Globals.GAMEMODE == "SOCCER":
			$The_Winner.text = "THE WINNER IS..."
			if Globals.WINNER == 1:
				$Winner.text = "LEFT TEAM"
			else:
				$Winner.text = "RIGHT TEAM"
		else:
			$The_Winner.text = "THE WINNER IS..."
			$Winner.text = Globals.WINNERCHARACTER
	$Banner.color = Globals.CONTROLLERCOLORS[Globals.WINNERCONTROLLER]
	Mat.set_shader_param("skin", Globals.playerskins[Globals.WINNER-1])
	

func _process(_delta):
	if Input.is_action_just_pressed("pause") || Input.is_action_just_pressed("select") || Input.is_action_just_pressed("attack"):
		go_to_menu()


func go_to_menu():
	var menu = get_tree().change_scene("res://scenes/supportscenes/Menu.tscn")
