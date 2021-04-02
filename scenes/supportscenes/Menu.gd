extends Node


var maxvol = -80
var minvol = -80
var volchange = 80

func _ready():
	delete_children()
	if Globals.MENU == "MAIN":
		var mainmenu = preload("res://scenes/supportscenes/MainMenu.tscn").instance()
		add_child(mainmenu)
	elif Globals.MENU == "CSS":
		var css = preload("res://scenes/supportscenes/CSS.tscn").instance()
		add_child(css)
	
	$MainMenu.volume_db = 0
	$RuleMenu.volume_db = -80
	$CharacterMenu.volume_db = -80
	
func delete_children():
	for n in self.get_children():
		if n.get_class() == "Node2D":
			self.remove_child(n)
			n.queue_free()


func _process(_delta):
	$MainMenu.volume_db = changevolume($MainMenu.volume_db, "MAIN")
	$RuleMenu.volume_db = changevolume($RuleMenu.volume_db, "RULES")
	$CharacterMenu.volume_db = changevolume($CharacterMenu.volume_db, "CSS")
	
	
func changevolume(vol, menu):
	if !Globals.MUTED:
		if Globals.MENU == menu:
			if vol < maxvol:
				vol += volchange
			else:
				vol = maxvol
		else:
			if vol > minvol:
				vol -= volchange
			else:
				vol = minvol
		return vol
	else:
		return -80
