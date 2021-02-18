extends Node2D

onready var PLAYER = preload("res://characters/fox/Fox.tscn")

onready var DAMAGE = preload("res://ui/Damage.tscn")

func _ready():
	
	Globals.players = []
	Globals.projectiles = []
	for i in range(Globals.NUM_OF_PLAYERS):
		Globals.players.append(PLAYER.instance())
	
		var pos = Vector2((i-(Globals.NUM_OF_PLAYERS-1.0)/2.0)*1440.0/(Globals.NUM_OF_PLAYERS), 0)
		Globals.players[i].playernumber = i+1
		Globals.players[i].character = "Fox"
		Globals.players[i].name = "Player" + str(i+1)
		Globals.players[i].skin = i
		if i == 0:
			Globals.players[i].controller = 1
		Globals.players[i].respawn(pos, true)
		Globals.players[i].d = -pos.x / abs(pos.x)
		add_child(Globals.players[i])
		
		var damage_card = DAMAGE.instance()
		pos = Vector2((i-(Globals.NUM_OF_PLAYERS-1.0)/2.0)*1440.0/(Globals.NUM_OF_PLAYERS)+720, 800)
		damage_card.set_position(pos)
		damage_card.playernumber = i+1
		damage_card.character = Globals.players[i].character
		$CanvasLayer.add_child(damage_card)


func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		Globals.PAUSED = !Globals.PAUSED
		
	if Input.is_action_just_pressed("select"):
		Globals.SHOWHITBOXES = !Globals.SHOWHITBOXES
	
	if Globals.IMPACTFRAME > 0:
		Globals.IMPACTFRAME -= 1
