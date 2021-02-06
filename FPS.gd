extends RichTextLabel

var FPS

func _ready():
	set("custom_fonts/normal_font",load("res://ui/font.tres"))

func _process(_delta):
	FPS = Engine.get_frames_per_second()
	text = (str(FPS) + " FPS")
