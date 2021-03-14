extends Node2D

var buttonnumber

func _ready():
	pass # Replace with function body.

func _process(_delta):
	if buttonnumber == Globals.SELECTEDMENUBUTTON:
		$Rect.color = Color("ffe300")
		$Text.set("custom_colors/font_color", Color(0,0,0,1))
	else:
		$Rect.color = Color("26294a")
		$Text.set("custom_colors/font_color", Color(1,1,1,1))
