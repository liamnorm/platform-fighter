extends Node2D

onready var PLAYER = preload("res://characters/fox/Fox.tscn")


const NUM_OF_PLAYERS = 2

const LEDGES = [[Vector2(-640, 256), 1], [Vector2(640, 256), -1]]
#const LEDGES = [[Vector2(-768, 256), 1], [Vector2(768, 256), -1]]

var hitboxes 

var players

var PAUSED = false

var IMPACTFRAME = 10

var SHOWHITBOXES = false

const TOPBLASTZONE = -1080
const BOTTOMBLASTZONE = 1440
const SIDEBLASTZONE = 1728

func _ready():
	
	players = []
	for i in range(NUM_OF_PLAYERS):
		players.append(PLAYER.instance())
	
		var pos = Vector2((i-(NUM_OF_PLAYERS-1.0)/2.0)*1440.0/(NUM_OF_PLAYERS), 0)
		players[i].playernumber = i+1
		players[i].character = "Fox"
		players[i].name = "Player" + str(i+1)
		players[i].skin = i
		if i == 0:
			players[i].controller = 1
		players[i].respawn(pos)
		players[i].d = -pos.x / abs(pos.x)
		add_child(players[i])


func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		PAUSED = !PAUSED
	
	if IMPACTFRAME > 0:
		IMPACTFRAME -= 1
