extends Sprite

var beeframe = 0
var pos = Vector2(0,0)

func _ready():
	pos = Vector2((randi()%100)/100.0, 1)
	offset = Vector2(pos.x*Globals.SCREENX, pos.y*Globals.SCREENY)


func _process(_delta):
	pos += Vector2((randi()%8)/1000.0-0.005, -(randi()%8)/500.0)
	offset = Vector2(pos.x*Globals.SCREENX, pos.y*Globals.SCREENY)
	beeframe += 1
	if beeframe > 100:
		queue_free()
