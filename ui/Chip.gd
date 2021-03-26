extends Node2D

var playernumber = 0
var SCREENX = 1920
var SCREENY = 1080
var P = 8
var pos = Vector2(0,0)
var xspeed = 0.1
var yspeed = 0.1

var Mat

func start(i):
	playernumber = i
	Mat = $Sprite.get_material()
	

func _ready():
	display()

func _process(_delta):
	display()
	
func display():
	var color = Globals.CONTROLLERCOLORS[Globals.playercontrollers[playernumber-1]]
	if Globals.TEAMMODE:
		if Globals.playerteams[playernumber-1] == 1:
			color = Globals.RIGHTCOLOR
		else:
			color = Globals.LEFTCOLOR
	Mat.set_shader_param("color", color)
	visible = playernumber <= Globals.NUM_OF_PLAYERS
	$Sprite.frame = (playernumber-1)*2 + (Globals.CSSFRAME/10)%2
	if Globals.chipholder[playernumber-1] > 0:
		var targetpos = Globals.pointpos[Globals.chipholder[playernumber-1]-1]
		pos = lerp(pos, targetpos, 0.75)
	else:
		pos = Globals.chippos[playernumber-1]
		var circlepos = Vector2(0.5, .25)
		var otherplayers = 0
		var me = 0
		for i in Globals.NUM_OF_PLAYERS:
			if Globals.playerselected[i]:
				if i == playernumber -1:
					me = i
				otherplayers += 1
		var angle = (6.28 / otherplayers) * me
		var vector = Vector2(cos(angle), 1.5 * sin(angle)) * (otherplayers-1) * 0.005
		Globals.chippos[playernumber-1] = circlepos + vector
	if Globals.chipholder[playernumber-1] > 0:
		visible = false
	position = Vector2(
		pos.x * Globals.SCREENX,
		pos.y * Globals.SCREENY)
	
