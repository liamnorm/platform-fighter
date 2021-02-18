extends StaticBody2D

var pos


func _ready():
	pos = get_position()
	Globals.PLATFORMLEDGES.append([Vector2(-160,0)+pos, 1])
	Globals.PLATFORMLEDGES.append([Vector2(160,0)+pos, -1])
