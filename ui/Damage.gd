extends Node2D

var skin = 0
var playernumber = 0
var character = ""
var Mat
var damage
var playername = "SPACEDOG"


func _ready():
	pass
	
func _process(_delta):
	Mat = $Portrait.get_material()
	Mat.set_shader_param("skin", Globals.players[playernumber-1].skin%8)
	damage = floor(Globals.players[playernumber-1].damage)
	$Damage.text = str(damage) + "%"
	$Damage.set("custom_colors/default_color", getdamagecolor(damage))
	$Damage.visible =  !Globals.players[playernumber-1].defeated
	
	var stock = Globals.players[playernumber-1].stock
	playername = Globals.players[playernumber-1].character
	if Globals.GAMEMODE == "STOCK":
		$Name.text = " " + playername + " x" + str(stock)
	else:
		$Name.text = " " + playername
	
	$Color.modulate = Globals.CONTROLLERCOLORS[Globals.players[playernumber-1].controller]
	
	
	visible = !Globals.PAUSED
	
	position = Vector2(
		(playernumber-1-(Globals.NUM_OF_PLAYERS-1.0)/2.0)*1000/
		(Globals.NUM_OF_PLAYERS)+(Globals.SCREENX/2.0), 
		Globals.SCREENY - 100)
	
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
