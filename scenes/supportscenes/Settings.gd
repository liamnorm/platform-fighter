extends Node2D

onready var BUTTON = preload("res://ui/RuleOption.tscn")
onready var BEE = preload("res://ui/Bee.tscn")

var buttons = []
var buttonnames = []
var SCREENX = 1920
var SCREENY = 1080
var gamemode = "STOCK"

var num_of_options = 1


var desc = {
	"MUSIC": "PLAY MUSIC?",
	"BEES": "BEEEES?",
	"SETTINGS": "SHOULD SETTINGS BE INVERTED?",
}


var options = {
	"MUSIC": ["ON", "OFF"],
	"BEES": ["ON", "OFF"],
	"SETTINGS": ["NORMAL", "INVERTED", "GREEN", "AAAA"],
}

func _ready():
	
	Globals.MENU = "SETTINGS"
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
			
			go_to_menu()
	
	SCREENX = Globals.SCREENX
	SCREENY = Globals.SCREENY
	lookgood()

func lookgood():
	
	$Background.margin_right = SCREENX + 128
	$Background.margin_bottom = SCREENY + 128
	
	if Globals.BEES:
		for i in range(20):
			var bee = BEE.instance()
			add_child(bee)
		
		
	var i = 0
	for b in buttons:
		b.position = Vector2(SCREENX/2, SCREENY/4)
		b.position.y += i * 32
		i+= 1
		
func thebuttons():
	
	delete_children(self)
	buttons = []
	
	buttonnames = ["MUSIC", "BEES", "SETTINGS"]
	
		
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
		"MUSIC":
			if Globals.SETTINGS == "INVERTED":
				Globals.MUTED = ind != 1
			else:
				Globals.MUTED = ind == 1
		"BEES":
			if Globals.SETTINGS == "INVERTED":
				Globals.BEES = ind == 1
			else:
				Globals.BEES = ind != 1
		"SETTINGS":
			Globals.SETTINGS = choice
			buttonaction(0)
			buttonaction(1)
		
static func delete_children(node):
	for n in node.get_children():
		if n.get_class() == "Node2D":
			node.remove_child(n)
			n.queue_free()

func start_game():
	var _game = get_tree().change_scene("res://scenes/mainscene/World.tscn")

	
func go_to_menu():
	var menu = load("res://scenes/supportscenes/MainMenu.tscn").instance()
	get_parent().add_child(menu)
	queue_free()
