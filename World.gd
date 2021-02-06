extends Node2D

onready var PLAYER = preload("res://characters/fock/Fock.tscn")

const NUM_OF_PLAYERS = 2

const LEDGES = [[Vector2(-640, 256), 1], [Vector2(640, 256), -1]]

var players

func _ready():
	
	players = []
	for i in range(NUM_OF_PLAYERS):
		players.append(PLAYER.instance())
	
		var pos = Vector2((i-3.5)*128, 0)
		players[i].character = "Fock"
		players[i].name = "Player" + str(i+1)
		players[i].skin = i
		if i == 0:
			players[i].controller = 1
		players[i].respawn(pos)
		add_child(players[i])
