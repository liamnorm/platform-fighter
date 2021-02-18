extends Camera2D


var minx = 0
var maxx = 0
var miny = 0
var maxy = 0
var x_offset = 0
var y_offset = 0
const XBOUNDS = 200
const YBOUNDS = 200
const SCREENX = 200
const SCREENY = 200
var do_rumble = 0
var rumblex = 0
var rumbley = 0

var NUM_OF_PLAYERS = 2


func _ready():
	NUM_OF_PLAYERS = Globals.NUM_OF_PLAYERS

func _process(_delta):
		
	do_rumble = Globals.IMPACTFRAME
	if !Globals.PAUSED:

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
		var zoomo = finalmax/400
		zoomo = lerp(zoomo,zoom.x,0.99)
		zoomo = clamp(zoomo, 0.75, 1.5)
		zoom = Vector2(zoomo, zoomo) 
		
		x_offset = (maxx+minx)/2
		y_offset = (maxy+miny)/2
		
		x_offset = clamp(x_offset,-XBOUNDS-SCREENX/zoomo,XBOUNDS+SCREENX/zoomo)
		y_offset = clamp(y_offset,-YBOUNDS-SCREENY/zoomo, YBOUNDS+SCREENY/zoomo)
		
		x_offset = lerp(x_offset, position.x, 0.95)
		y_offset = lerp(y_offset, position.y, 0.95)
		
		
		rumblex = do_rumble * randi()%10
		rumbley = do_rumble * randi()%10
		set_position(Vector2(x_offset+rumblex, y_offset+rumbley))
