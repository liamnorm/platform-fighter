extends Node2D

var skin = 0
var playernumber = 0
var character = ""
var Mat
var damage
var playername = "SPACEDOG"

var SCREENX = 1920
var SCREENY = 1080
var P = 0
var size

var w


func _ready():
	w = get_parent().get_parent()
	
func _process(_delta):
	
	SCREENX = Globals.SCREENX
	SCREENY = Globals.SCREENY
	P = Globals.NUM_OF_PLAYERS

	size = Vector2(SCREENX/P, 128)
	position = Vector2((playernumber-1) * size.x, SCREENY - 128)
	
	if P == 2:
		size.x = (SCREENX/P) - 256
		if playernumber == 1:
			position.x = 0
		else:
			position.x = SCREENX - size.x
	
	$Color.margin_right = size.x - 0
	$Color.margin_bottom = size.y - 0
	
	
	
	Mat = $Portrait.get_material()
	Mat.set_shader_param("skin", w.players[playernumber-1].skin%Globals.NUM_OF_SKINS)
	#Mat.set_shader_param("outofgame", w.players[playernumber-1].defeated)
	if w.players[playernumber-1].defeated:
		modulate.a = .25
	else:
		modulate.a = 1
	damage = floor(w.players[playernumber-1].damage)
	$Damage.text = str(damage) + "%"
	$Damage.set("custom_colors/font_color", getdamagecolor(damage))
	$Damage.visible =  !w.players[playernumber-1].defeated
	
	$Damage.margin_left = size.x - 128
	$Damage.margin_right = size.x
	
	if size.x < 300:
		$Damage.set("custom_fonts/font", load("res://ui/fonts/smallerfont.tres"))
	else:
		$Damage.set("custom_fonts/font", load("res://ui/fonts/font.tres"))
	

	
	var stock = str(w.players[playernumber-1].stock)
	playername = w.players[playernumber-1].character
	$Name.text = " " + playername
	
	if w.GAMEMODE != "STOCK":
		$Score.text = ""
	else:
		$Score.text = " " + stock

	var color = Globals.CONTROLLERCOLORS[w.players[playernumber-1].controller]
	if w.TEAMMODE:
		if w.players[playernumber-1].team == 1:
			color = Globals.RIGHTCOLOR
		else:
			color = Globals.LEFTCOLOR
	$Color.color = color
	
	
	visible = !w.PAUSED
	
#	position = Vector2(
#		(playernumber-1-(w.NUM_OF_PLAYERS-1.0)/2.0)*1000/
#		(w.NUM_OF_PLAYERS)+(Globals.SCREENX/2.0), 
#		Globals.SCREENY - 100)
	
func getdamagecolor(d):
	var r = 1
	var g = 1
	var b = 1
	r = 1 - ((d-100) / 100.0)
	g = .7 - ((d-50) / 50.0)
	b = 1 - ((d-20) / 50.0)	
	
	r = clamp(r, 0.4, 1.0)
	g = clamp(g, 0.0, 1.0)
	b = clamp(b, 0.0, 1.0)
	
	return Color(r,g,b)
