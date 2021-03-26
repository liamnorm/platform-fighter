extends Node2D

var Mat
var BMat

var SCREENX = 1920
var SCREENY = 1080

func _ready():
	Mat = $Sprite.get_material()
	BMat = $Background.get_material()

	
	var bgcolor
	
	if Globals.WINNER == 0:
		$The_Winner.text = ""
		$Winner.text = "TIE"
		bgcolor = Globals.CONTROLLERCOLORS[0]
	else:
		if Globals.TEAMMODE:
			$The_Winner.text = "THE WINNER IS..."
			if Globals.WINNER == 1:
				bgcolor = Globals.LEFTCOLOR
				$Winner.text = "LEFT TEAM"
			else:
				bgcolor = Globals.RIGHTCOLOR
				$Winner.text = "RIGHT TEAM"
		else:
			bgcolor = Globals.CONTROLLERCOLORS[Globals.WINNERCONTROLLER]
			$The_Winner.text = "THE WINNER IS..."
			$Winner.text = Globals.WINNERCHARACTER
	
	Mat.set_shader_param("skin", Globals.WINNERSKIN)
	
	bgcolor.a = 0.7
	$Banner.color = bgcolor
	

func _process(_delta):
	if Input.is_action_just_pressed("pause") || Input.is_action_just_pressed("select") || Input.is_action_just_pressed("attack"):
		go_to_css()
		
	SCREENX = get_viewport().size.x
	SCREENY = get_viewport().size.y
		
	$Banner.margin_left = 0
	$Banner.margin_top = 0
	$Banner.margin_right = max(SCREENX,SCREENY)
	$Banner.margin_bottom = max(SCREENX,SCREENY)
	
	$The_Winner.margin_left = 0
	$The_Winner.margin_top = SCREENY/32
	$The_Winner.margin_right = SCREENX
	$The_Winner.margin_bottom = SCREENY/8
	$Winner.margin_left = 0
	$Winner.margin_top = SCREENY/8
	$Winner.margin_right = SCREENX
	$Winner.margin_bottom = SCREENY/4
	
	$Background.margin_left = 0
	$Background.margin_top = 0
	$Background.margin_right = max(SCREENX,SCREENY)
	$Background.margin_bottom = max(SCREENX,SCREENY)


func go_to_menu():
	var menu = get_tree().change_scene("res://scenes/supportscenes/Menu.tscn")

func go_to_css():
	var _css = get_tree().change_scene("res://scenes/supportscenes/CSS.tscn")
