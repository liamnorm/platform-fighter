extends Node2D

var buttons = []
var buttonnames = []

func _ready():
	
	Globals.SELECTEDMENUBUTTON = 0
	buttons = [$StockButton, 
	$TimeButton, 
	$SoccerButton, 
	$TrainingButton, 
	$OnlineButton]
	buttonnames = ["STOCK", "TIME", "SOCCER", "TRAINING", "ONLINE"]
	
	for i in range(5):
		buttons[i].get_node("Text").text = " " + buttonnames[i]
		buttons[i].buttonnumber = i


func _process(_delta):

	if Input.is_action_just_pressed("down"):
		if Globals.SELECTEDMENUBUTTON < 4:
			Globals.SELECTEDMENUBUTTON += 1
	if Input.is_action_just_pressed("jump"):
		if Globals.SELECTEDMENUBUTTON > 0:
			Globals.SELECTEDMENUBUTTON -= 1
			
	if Input.is_action_just_pressed("pause") || Input.is_action_just_pressed("select") || Input.is_action_just_pressed("attack"):
		Globals.GAMEMODE = buttonnames[Globals.SELECTEDMENUBUTTON]
		advance_to_css()

func start_game():
	var _game = get_tree().change_scene("res://scenes/mainscene/World.tscn")
	
func advance_to_css():
	var _css = get_tree().change_scene("res://scenes/supportscenes/CSS.tscn")
