extends StaticBody2D

var pos
var w


func _ready():
	position = Vector2(0,256)
	w = get_parent().get_parent()
	pos = get_position()
	w.PLATFORMLEDGES.append([Vector2(-160,0)+pos, 1])
	w.PLATFORMLEDGES.append([Vector2(160,0)+pos, -1])
