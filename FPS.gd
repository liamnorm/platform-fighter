extends RichTextLabel

var FPS
var DAMAGE

func _ready():
	set("custom_fonts/normal_font",load("res://ui/font.tres"))

func _process(_delta):
	FPS = Engine.get_frames_per_second()
	
	DAMAGE = ""
	var i = 1
	for player in get_tree().get_root().get_node("World").players:
		DAMAGE += "P" + str(i) + ": " + str(player.damage) + "%\n  "
		i += 1
	
	
	text = (str(FPS) + " FPS  \n\n\n  " + DAMAGE)
