extends Node2D

var buttons = []
var buttonnames = []
var SCREENX = 1920
var SCREENY = 1080

func _ready():
	
	buttons = [$StockButton, 
	$TimeButton, 
	$SoccerButton, 
	$TrainingButton, $OnlineButton]
	buttonnames = ["STOCK", "TIME", "SOCCER", "TRAINING", "ONLINE"]

	
	for i in range(5):
		buttons[i].get_node("Text").text = buttonnames[i]
		buttons[i].buttonnumber = i
		buttons[i].visible = true
	lookgood()


func _process(_delta):

	if Input.is_action_just_pressed("down"):
		if Globals.SELECTEDMENUBUTTON < 4:
			Globals.SELECTEDMENUBUTTON += 1
	if Input.is_action_just_pressed("jump"):
		if Globals.SELECTEDMENUBUTTON > 0:
			Globals.SELECTEDMENUBUTTON -= 1
			
	if Input.is_action_just_pressed("pause") || Input.is_action_just_pressed("select") || Input.is_action_just_pressed("attack"):
		if buttonnames[Globals.SELECTEDMENUBUTTON] == "ONLINE":
			advance_to_lobby()
		else:
			Globals.GAMEMODE = buttonnames[Globals.SELECTEDMENUBUTTON]
			if  Globals.GAMEMODE == "SOCCER":
				Globals.STAGE = 1
				Globals.TEAMMODE = true
			else:
				Globals.STAGE = 0
				Globals.TEAMMODE = false
			advance_to_css()
	
	SCREENX = Globals.SCREENX
	SCREENY = Globals.SCREENY
	lookgood()

func lookgood():
	
	$Title.margin_right = SCREENX
	$Title.margin_bottom = SCREENY / 3
	$Title.visible = true
	$Background.margin_right = SCREENX + 128
	$Background.margin_bottom = SCREENY + 128
	var i = 0
	for b in buttons:
		b.position = Vector2(SCREENX/2, SCREENY/3)
		b.position.y += i * 64
		i+= 1

func start_game():
	var _game = get_tree().change_scene("res://scenes/mainscene/World.tscn")
	
func advance_to_css():
	var _css = get_tree().change_scene("res://scenes/supportscenes/CSS.tscn")
	
func advance_to_lobby():
	var _css = get_tree().change_scene("res://scenes/supportscenes/Lobby.tscn")
