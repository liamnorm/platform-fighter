extends Node2D

var playernumber = 0
var SCREENX = 1920
var SCREENY = 1080
var P = 8
var size = Vector2(50,50)
var p = {}

var Mat

func start(i):
	playernumber = i
	if is_instance_valid((Globals.RESULTDATA)):
		if i <= Globals.RESULTDATA.size():
			p = Globals.RESULTDATA[i-1]
		else:
			queue_free()
	else:
		queue_free()
	Mat = $Portrait.get_material()

func _ready():
	pass

func _process(_delta):
	display()
	
func display():
	SCREENX = Globals.SCREENX
	SCREENY = Globals.SCREENY
	P = Globals.NUM_OF_PLAYERS
	size = Vector2(SCREENX/P, SCREENY/4)
	position = Vector2((playernumber-1) * size.x, SCREENY * .75)
	$Background.margin_right = size.x - 0
	$Background.margin_bottom = size.y - 0
	if !Globals.TEAMMODE:
		$Background.color = Globals.CONTROLLERCOLORS[p.controller]
	else:
		if p.team == 0:
			$Background.color = Globals.LEFTCOLOR
		else:
			$Background.color = Globals.RIGHTCOLOR
	$Background.color.a = 0.7
	
#	$TextureRect.margin_left = size.x/2 - 256
#	$TextureRect.margin_bottom = size.y
#	$TextureRect.margin_top = size.y - SCREENY/2

	
	$Label.margin_left = 16
	$Label.margin_right = size.x - 16
	$Label.text = p.character
	$Label.margin_top = 10
	
	$CPU.position.y = size.y - 32
	$CPU.position.x = 32
	$CPU.frame = !p.controller > 0
	$P.margin_left = 62
	$P.margin_top = size.y - 58
	$P.margin_bottom = size.y
	$P.margin_right = size.x
	if Globals.playercontrollers[playernumber-1] > 0:
		$P.text = "P" + str(p.playernumber)
	else:
		$P.text = ""

	$LabelBack.margin_bottom = size.y
	$LabelBack.margin_right = size.x
	$LabelBack.color = Globals.CONTROLLERCOLORS[p.controller]
	$LabelBack.color *= 0.2
	$LabelBack.color.a = 0.8
	if size.x < 300:
		$Label.set("custom_fonts/font", load("res://ui/fonts/smallerfont.tres"))
		$LabelBack.margin_top = size.y - 64
	else:
		$Label.set("custom_fonts/font", load("res://ui/fonts/font.tres"))
		$LabelBack.margin_top = size.y - 64
	
	Mat.set_shader_param("skin", p.skin)
	Mat.set_shader_param("sizex", 1.0/(P)*(SCREENX/960.0))
	
	updatetexture()
	
func updatetexture():
	if Globals.playerchars[playernumber-1] >= 0:
		var c = Globals.characterdirectories[0]
		#$TextureRect.texture = load("res://characters/" + c + "/cssportrait.png")
		Mat.set_shader_param("palette_tex",load("res://characters/" + c + "/palette.png"))
		$Portrait.visible = true
		$Label.visible = true
	else:
		$Portait.visible = false
		$Label.visible = false
	
