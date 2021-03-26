extends StaticBody2D

var pos
var w


func _ready():
	w = get_parent().get_parent()
	pos = get_position()
	w.PLATFORMLEDGES.append([Vector2(-160,0)+pos, 1])
	w.PLATFORMLEDGES.append([Vector2(160,0)+pos, -1])
