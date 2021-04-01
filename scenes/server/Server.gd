extends Node

var lobbymade = false

func _ready():
	
	Globals.ONLINE = true
	Globals.ISSERVER = true
	lobbymade = false
	
func _process(_delta):
	if !lobbymade:
		var lobby = preload("res://scenes/supportscenes/Lobby.tscn").instance()
		get_tree().get_root().add_child(lobby)
		lobbymade = true
