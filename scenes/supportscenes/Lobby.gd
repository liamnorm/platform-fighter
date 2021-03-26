extends Node2D


func _ready():
	pass

func _process(delta):
	if Input.is_action_pressed("special"):
		go_back()
		
		
func go_back():
	var _menu = get_tree().change_scene("res://scenes/supportscenes/Menu.tscn")

