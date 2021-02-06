extends Camera2D


var minx
var maxx
var miny
var maxy
var x_offset
var y_offset
const XBOUNDS = 0
const SCREENX = 500
const SCREENY = 500

var NUM_OF_PLAYERS = 2


func _ready():
	NUM_OF_PLAYERS = get_tree().get_root().get_node("World").get("NUM_OF_PLAYERS")

func _process(delta):
	for i in range(NUM_OF_PLAYERS):
		var node_name = "../Player" + str(i+1)
		var pxpos = get_node(node_name).get_position().x
		var pypos = get_node(node_name).get_position().y
		if i == 0:
			minx = pxpos
			miny = pypos
			maxx = pxpos
			maxy = pypos
		else:
			minx = min(minx, pxpos)
			maxx = max(maxx, pxpos)
			miny = min(miny, pypos)
			maxy = max(maxy, pypos)
	
	var finalmax = max(abs(maxx-minx), abs(maxy-miny)*2)
	var zoomo = finalmax/600
	zoomo = lerp(zoomo,zoom.x,0.9)
	zoomo = clamp(zoomo, 1, 2)
	zoom = Vector2(zoomo, zoomo) 
	
	x_offset = (maxx+minx)/2
	y_offset = (maxy+miny)/2
	
	x_offset = clamp(x_offset,-XBOUNDS-SCREENX/zoomo,XBOUNDS+SCREENX/zoomo)
	y_offset = clamp(y_offset,-SCREENY/zoomo, SCREENY/zoomo)
	
	x_offset = lerp(x_offset, position.x, 0.9)
	y_offset = lerp(y_offset, position.y, 0.9)
	
	set_position(Vector2(x_offset,y_offset))
