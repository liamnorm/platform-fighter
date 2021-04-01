extends Node2D

onready var SLATE = preload("res://ui/CharSlate.tscn")
onready var CHIP = preload("res://ui/Chip.tscn")
onready var POINTER = preload("res://ui/Pointer.tscn")

var slates = []
var chips = []
var pointers = []

var Mat

func _ready():
	Mat = $Sprite.get_material()
	if !Globals.ONLINE:
		if Globals.NUM_OF_PLAYERS < 2:
			Globals.NUM_OF_PLAYERS = 2
	else:
		Globals.NUM_OF_PLAYERS = 1
	
	slates = []
	for i in range(8):
		slates.append(SLATE.instance())
		slates[i].start(i+1)
		add_child(slates[i])
		
	Globals.CSSFRAME = 0
	Globals.chippos = []
	Globals.pointpos = []
	Globals.playerselected = []
	Globals.chipholder =  [0,0,0,0,0,0,0,0,0]
	for i in range(8):
		Globals.pointpos.append(Vector2((i+0.5)/8.0, 0.45))
		if Globals.playercontrollers[i] == 0:
			Globals.chippos.append(Vector2(0.5, .25))
		else:
			Globals.chippos.append(Vector2((i+0.5)/8.0, 0.45))
		#Globals.playerselected.append(!(Globals.playercontrollers[i] > 0))
		Globals.playerselected.append(true)
		
	chips = []
	for i in range(8):
		chips.append(CHIP.instance())
		chips[i].start(i+1)
		add_child(chips[i])
		
	pointers = []
	for i in range(8):
		pointers.append(POINTER.instance())
		pointers[i].start(i+1)
		add_child(pointers[i])



func _process(_delta):
	if (Input.is_action_just_pressed("pause") ||
		Input.is_action_just_pressed("select")
		) && !Globals.playerselected.has(false):
			start_game()
	if Input.is_action_pressed("special"):
		Globals.CSSBACKFRAME += 1
	else:
		Globals.CSSBACKFRAME = 0
	if Globals.CSSBACKFRAME > 45:
		if Globals.GAMEMODE == "TRAINING":
			go_back()
		else:
			go_back_to_rules()


	$Num_of_players.text = str(Globals.NUM_OF_PLAYERS) + " PLAYERS"
	
	$Rules.text = Globals.GAMEMODE
	
	$Sprite.position = Vector2(Globals.SCREENX / 2, Globals.SCREENY / 4)
	
	$Background.margin_left = 0
	$Background.margin_top = 0
	$Background.margin_right = max(Globals.SCREENX,Globals.SCREENY)
	$Background.margin_bottom = max(Globals.SCREENX,Globals.SCREENY)
	
	$Back.get_material().set_shader_param("progress", Globals.CSSBACKFRAME/45.0)
	
	$ColorRect.margin_left = 0
	$ColorRect.margin_top = 0
	$ColorRect.margin_right = Globals.SCREENX
	$ColorRect.margin_bottom = Globals.SCREENY/2
	
	if !Globals.ONLINE:
	
		$Add.visible = true
		$Add.position.x = Globals.SCREENX - 192
		$Add.position.y = Globals.SCREENY/2 - 64
		
		$Subtract.visible = true
		$Subtract.position.x = Globals.SCREENX - 64
		$Subtract.position.y = Globals.SCREENY/2 - 64
	else:
		$Add.visible = false
		$Subtract.visible = false
	
	Globals.CSSFRAME += 1
	
	
func start_game():
	if Globals.ONLINE:
		var _lobby = get_tree().change_scene("res://scenes/supportscenes/Lobby.tscn")
	else:
		var _game = get_tree().change_scene("res://scenes/mainscene/World.tscn")
	
func go_to_lobby():
	var _lobby = get_tree().change_scene("res://scenes/supportscenes/Lobby.tscn")

func go_back():
	var _menu = get_tree().change_scene("res://scenes/supportscenes/Menu.tscn")
	
func go_back_to_rules():
	var _rules = get_tree().change_scene("res://scenes/supportscenes/Rules.tscn")
