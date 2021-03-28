extends Node2D

var buttonnumber

var rulename = ""
var ruleoption = ""

func _ready():
	lookgood()

func _process(_delta):
	lookgood()
	
func lookgood():
	
	position = Vector2(Globals.SCREENX/2, Globals.SCREENY/4)
	position.y += buttonnumber * 32
	if buttonnumber == Globals.SELECTEDRULE:
		$Rect.color = Color("ffe300")
		$Option.set("custom_colors/font_color", Color(0,0,0,1))
	else:
		$Rect.color = Color("26294a")
		$Option.set("custom_colors/font_color", Color(1,1,1,1))
	$Name.text = rulename
	$Option.text = ruleoption
