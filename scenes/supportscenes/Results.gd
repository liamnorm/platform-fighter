extends Node2D

onready var SLATE = preload("res://ui/ResultSlate.tscn")

var Mat
var BMat

var slates = []

var SCREENX = 1920
var SCREENY = 1080
var resultsframe = 0

func _ready():
	Mat = $Sprite.get_material()
	BMat = $Background.get_material()
	resultsframe = 0
	
	slates = []
	for i in range(8):
		slates.append(SLATE.instance())
		slates[i].start(i+1)
		add_child(slates[i])

	
	var bgcolor
	
	var winner = 0
	
	if Globals.WINNER == -1:
		$The_Winner.text = ""
		$Winner.text = "TIE"
		bgcolor = Globals.CONTROLLERCOLORS[0]
	else:
		if Globals.TEAMMODE:
			$The_Winner.text = "THE WINNER IS..."
			if Globals.WINNER == 0:
				bgcolor = Globals.LEFTCOLOR
				$Winner.text = "LEFT TEAM"
			else:
				bgcolor = Globals.RIGHTCOLOR
				$Winner.text = "RIGHT TEAM"
		else:
			var w = Globals.RESULTDATA[winner]
			bgcolor = Globals.CONTROLLERCOLORS[w.controller]
			$The_Winner.text = "THE WINNER IS..."
			$Winner.text = w.character
			Mat.set_shader_param("skin", w.skin)
	
	bgcolor.a = 0.7
	$Banner.color = bgcolor
	

func _process(_delta):
	resultsframe += 1
	if resultsframe > 120:
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
	Globals.MENU = "MAIN"
	var _menu = get_tree().change_scene("res://scenes/supportscenes/Menu.tscn")
	queue_free()

func go_to_css():
	Globals.MENU = "CSS"
	var _menu = get_tree().change_scene("res://scenes/supportscenes/Menu.tscn")
	queue_free()
