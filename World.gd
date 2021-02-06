extends Node2D

onready var PLAYER = preload("res://characters/fox/Fox.tscn")

const NUM_OF_PLAYERS = 8

const LEDGES = [[Vector2(-640, 256), 1], [Vector2(640, 256), -1]]

var players

func _ready():
	
	players = []
	for i in range(NUM_OF_PLAYERS):
		players.append(PLAYER.instance())
	
		var pos = Vector2((i-(NUM_OF_PLAYERS-1.0)/2.0)*1280.0/(NUM_OF_PLAYERS), 0)
		players[i].playernumber = i+1
		players[i].character = "Fox"
		players[i].name = "Player" + str(i+1)
		players[i].skin = i
		if i == 0:
			players[i].controller = 1
		players[i].respawn(pos)
		add_child(players[i])
