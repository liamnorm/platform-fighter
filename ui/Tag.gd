extends Node2D

var playernumber = 0
var controller = 0
var color = Color(1,1,1,1)

func _process(_delta):
	controller = Globals.players[playernumber-1].controller
	if controller > 0:
		$Name.text = "P" + str(playernumber)
	else:
		$Name.text = "CPU"
	color = Globals.CONTROLLERCOLORS[controller]
	$Name.set("custom_colors/font_color", color)
	
	$Name.visible = !Globals.players[playernumber-1].defeated
	
	position = Globals.players[playernumber-1].position + Vector2(0, -96)
