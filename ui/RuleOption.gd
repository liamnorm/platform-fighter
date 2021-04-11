extends Node2D

var buttonnumber

var yellow = Color("ffe300")
var darkblue = Color("26294a")
var green = Color("00eb04")

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
		if Globals.SETTINGS == "GREEN":
			$Rect.color = green
		else:
			$Rect.color = yellow
		$Option.set("custom_colors/font_color", Color(0,0,0,1))
	else:
		$Rect.color = darkblue
		$Option.set("custom_colors/font_color", Color(1,1,1,1))
	
	$Name.margin_right = -312
	$Name.margin_top = 0
	$Option.margin_right = 288
	$Option.margin_left = -288
	$Option.margin_top = 0
	if Globals.SETTINGS == "AAAA":
		$Name.text = "AAAAAAA"
		$Option.text = "AAAAAAAAAAAA"
		$Name.margin_right += -25 + randi()%50
		$Name.margin_top +=  -25 + randi()%50
		$Option.margin_left += -25 + randi()%50
		$Option.margin_top +=  -25 + randi()%50
	else:
		$Name.text = rulename
		$Option.text = ruleoption
