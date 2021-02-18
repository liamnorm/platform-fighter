extends CheckBox


func _ready():
	pass


func _process(_delta):
	Globals.SHOWHITBOXES = is_pressed()
