extends RichTextLabel

var FPS
var DAMAGE
var thetext

var w

func _ready():
	w = get_parent().get_parent()
	set("custom_fonts/normal_font",load("res://ui/fonts/smallerfont.tres"))

func _process(_delta):
	
	if w.FRAME > 0 && !w.PAUSED:
		visible = true
		FPS = Engine.get_frames_per_second()
		
		DAMAGE = ""
		var i = 1
		for player in w.players:
			DAMAGE += "P" + str(i) + ": " + str(player.damage) + "%\n  "
			#DAMAGE += str(player.input[1] && player.input[2]) + "\n  "
			i += 1
		
		thetext = ""
		
		if w.ISSERVER:
			thetext += "SERVER\n"
			
		thetext += " " + str(FPS) + " FPS"
		
		if w.GAMEMODE == "TIME" ||  w.GAMEMODE == "SOCCER":
			if w.TIME - (w.FRAME / 60) > 0:
				var seconds = (w.TIME - (w.FRAME / 60)) % 60
				var minutes = (w.TIME - (w.FRAME/60)) / 60
				var secondsprinted = str(seconds)
				if len(secondsprinted) == 1:
					secondsprinted = "0" + secondsprinted
				thetext += "\n " + str(minutes) + ":" + secondsprinted
		
		if w.GAMEMODE == "TRAINING":
			thetext += "\n " + str(w.COMBO) + " COMBO"

		text = thetext
	else:
		visible = false
