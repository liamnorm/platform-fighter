extends RichTextLabel

var FPS
var DAMAGE

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
	
	text = str(FPS) + " FPS"
	#text += "\n\n\n  " + DAMAGE)
