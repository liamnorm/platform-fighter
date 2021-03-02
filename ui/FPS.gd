extends RichTextLabel

var FPS
var DAMAGE
var thetext

func _ready():
	set("custom_fonts/normal_font",load("res://ui/fonts/smallerfont.tres"))

func _process(_delta):
	FPS = Engine.get_frames_per_second()
	
	DAMAGE = ""
	var i = 1
	for player in Globals.players:
		DAMAGE += "P" + str(i) + ": " + str(player.damage) + "%\n  "
		#DAMAGE += str(player.input[1] && player.input[2]) + "\n  "
		i += 1
	
	thetext = ""
	thetext += " " + str(FPS) + " FPS"
	
	var seconds = (Globals.FRAME / 60) % 60
	var minutes = (Globals.FRAME / 3600)
	var secondsprinted = str(seconds)
	if len(secondsprinted) == 1:
		secondsprinted = "0" + secondsprinted
	thetext += "\n " + str(minutes) + ":" + secondsprinted
	
	
	thetext += "\n\n\n " + str(Globals.COMBO) + " COMBO"

	text = thetext