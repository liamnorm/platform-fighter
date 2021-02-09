extends CheckBox


func _ready():
	pass


func _process(_delta):
	get_tree().get_root().get_node("World").SHOWHITBOXES = is_pressed()
