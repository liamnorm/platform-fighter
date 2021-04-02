extends Node2D

onready var BUTTON = preload("res://ui/RuleOption.tscn")

var buttons = []
var buttonnames = []
var SCREENX = 1920
var SCREENY = 1080
var gamemode = "STOCK"

var num_of_options = 1

var desc = {
	"STAGE":       "WHERE TO?",
	"GAME MODE":   "WHAT TO PLAY?",
	"STOCKS":      "HOW MANY LIVES SHOULD EVERYONE START WITH?",
	"TIME LIMIT":  "SHOULD THE GAME END?",
	"TIME":        "HOW LONG SHOULD THE GAME GO FOR?",
	"TEAMS":       "TEAM UP?",
	"TEAM ATTACK": "TEAMMATES CAN ATTACK EACH OTHER?",
	"TIEBREAKER":  "MWHAT HAPPENS WHEN THERE'S A TIE?",
	"CPU LEVEL":   "ON A SCALE OF 1 TO 5, HOW GOOD SHOULD COMPUTER PLAYERS BE?",
	"SCORE TO WIN":"SCORE TO WIN?"
}


var options = {
	"STAGE":       ["FINAL DESTINATION", "SOCCER FIELD"],
	"GAME MODE":   ["STOCK", "TIME", "SOCCER"],
	"STOCKS":      ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "INFINITE"],
	"TIME LIMIT":  ["NONE", "1:00", "2:00", "3:00", "4:00", "5:00", "6:00", "7:00", "8:00", "9:00", "10:00"],
	"TIME":        ["NONE", "1:00", "2:00", "3:00", "4:00", "5:00", "6:00", "7:00", "8:00", "9:00", "10:00"],
	"TEAMS":       ["OFF", "ON"],
	"TEAM ATTACK": ["OFF", "ON"],
	"TIEBREAKER":  ["WHATEVS", "SUDDEN DEATH", "SOCCER"],
	"CPU LEVEL":   ["1", "2", "3", "4", "5"],
	"SCORE TO WIN":["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21"],
}

var moderules = {
	"STOCK":  ["STOCKS", "TIME LIMIT"],
	"TIME":   ["TIME"],
	"SOCCER": ["TIME LIMIT", "SCORE TO WIN"],
}

func _ready():
	
	Globals.MENU = "RULES"
	Globals.SELECTEDRULE = 0
	
	thebuttons()
	lookgood()


func _process(_delta):

	if Input.is_action_just_pressed("down"):
		if Globals.SELECTEDRULE < num_of_options-1:
			Globals.SELECTEDRULE += 1
	if Input.is_action_just_pressed("jump"):
		if Globals.SELECTEDRULE > 0:
			Globals.SELECTEDRULE -= 1
	
	if Globals.ONLINE:
		$Description.text = "PREFERRED RULES"
	else:
		$Description.text = desc[buttonnames[Globals.SELECTEDRULE]]
			
	if Input.is_action_just_pressed("left") || Input.is_action_just_pressed("right"):
		var opt = buttonnames[Globals.SELECTEDRULE]
		var maxoption = len(options[opt])
		if Input.is_action_just_pressed("right"):
			Globals.RULECHOICES[opt] += 1
		else:
			Globals.RULECHOICES[opt] += -1 + maxoption
		Globals.RULECHOICES[opt] = Globals.RULECHOICES[opt] % maxoption
		
		var choice = options[opt][Globals.RULECHOICES[opt]]
		
		buttons[Globals.SELECTEDRULE].ruleoption = choice
		
		buttonaction(Globals.SELECTEDRULE)
		
	
	if Input.is_action_just_pressed("special"):
		go_to_menu()
			
	if Input.is_action_just_pressed("pause") || Input.is_action_just_pressed("select") || Input.is_action_just_pressed("attack"):
			for i in range(buttonnames.size()):
				buttonaction(i)
			
			go_to_css()
	
	SCREENX = Globals.SCREENX
	SCREENY = Globals.SCREENY
	lookgood()

func lookgood():
	
	$Background.margin_right = SCREENX + 128
	$Background.margin_bottom = SCREENY + 128
	var i = 0
	for b in buttons:
		b.position = Vector2(SCREENX/2, SCREENY/4)
		b.position.y += i * 32
		i+= 1
		
func thebuttons():
	
	delete_children(self)
	buttons = []
	
	buttonnames = ["STAGE", "GAME MODE"]
	
	if Globals.GAMEMODE == "TRAINING":
		Globals.GAMEMODE = "STOCK"
	
	gamemode = Globals.GAMEMODE

	var bta = moderules[gamemode]
	for i in bta:
		buttonnames.append(i)
	
	if !Globals.ONLINE:
		if !gamemode == "SOCCER":
			buttonnames.append("TEAMS")
			buttonnames.append("TEAM ATTACK")
	
		buttonnames.append("CPU LEVEL")
		buttonnames.append("TIEBREAKER")
		
	num_of_options = len(buttonnames)
	
	for i in range(num_of_options):
		var button = BUTTON.instance()
		button.rulename = buttonnames[i]
		button.ruleoption = options[buttonnames[i]][Globals.RULECHOICES[buttonnames[i]]]
		button.buttonnumber = i
		button.visible = true
		buttons.append(button)
		add_child(button)
		
func buttonaction(rule):
	
	var opt = buttonnames[rule]
	var choice = options[opt][Globals.RULECHOICES[opt]]
	var ind = Globals.RULECHOICES[opt]
	
	match buttonnames[rule]:
		"STAGE":
			Globals.STAGE = ind
		"GAME MODE":
			Globals.GAMEMODE = choice
			thebuttons()
			if choice == "SOCCER":
				Globals.TEAMMODE = true
		"STOCKS":
			if ind < 10:
				Globals.STOCKS = ind + 1
			else:
				Globals.STOCKS = 0
		"TIME LIMIT":
			Globals.TIME = (ind) * 60
		"TIME":
			Globals.TIME = (ind) * 60
		"TEAMS":
			Globals.TEAMMODE = ind == 1
		"TEAMATTACK":
			Globals.TEAMATTACK = ind == 1
		"TIEBREAKER":
			Globals.TIEBREAKER = choice
		"CPU LEVEL":
			Globals.CPULEVEL = ind
		"SCORE TO WIN":
			Globals.SCORETOWIN = ind
		
static func delete_children(node):
	for n in node.get_children():
		if n.get_class() == "Node2D":
			node.remove_child(n)
			n.queue_free()

func start_game():
	var _game = get_tree().change_scene("res://scenes/mainscene/World.tscn")
	
func go_to_css():
	var css = load("res://scenes/supportscenes/CSS.tscn").instance()
	get_parent().add_child(css)
	queue_free()

	
func go_to_menu():
	var menu = load("res://scenes/supportscenes/MainMenu.tscn").instance()
	get_parent().add_child(menu)
	queue_free()
