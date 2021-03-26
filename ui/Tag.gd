extends Node2D

var playernumber = 0
var controller = 0
var color = Color(1,1,1,1)

var w

func _ready():
	w = get_parent()

func _process(_delta):
	controller = w.players[playernumber-1].controller
	if controller > 0:
		$Name.text = "P" + str(w.players[playernumber-1].controller)
	else:
		$Name.text = "CPU"
	if w.TEAMMODE:
		if w.players[playernumber-1].team == 0:
			color = Globals.LEFTCOLOR
		else:
			color = Globals.RIGHTCOLOR
	else:
		color = Globals.CONTROLLERCOLORS[controller]
	$Name.set("custom_colors/font_color", color)
	
	$Name.visible = !w.players[playernumber-1].defeated
	
	position = w.players[playernumber-1].position + Vector2(0, -72)
