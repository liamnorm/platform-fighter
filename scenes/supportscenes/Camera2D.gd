extends Camera2D


var minx = 0
var maxx = 0
var miny = 0
var maxy = 0
var x_offset = 0
var y_offset = 0
var XBOUNDS = 2500
var YLOWERBOUND = 1500
var YUPPERBOUND = -1300
var SCREENX = 1920
var SCREENY = 1080
var do_rumble = 0
var rumblex = 0
var rumbley = 0
var finalposx = 0
var finalposy = 0
var smargx = 512
var smargy = 256

var Parallax

var w

var NUM_OF_ACTIVE_PLAYERS

func _ready():
	w = get_parent()

func _process(_delta):
	
	XBOUNDS = Globals.STAGEDATA[w.STAGE]["cameraxbound"]
	YUPPERBOUND = Globals.STAGEDATA[w.STAGE]["camerayupperbound"]
	YLOWERBOUND = Globals.STAGEDATA[w.STAGE]["cameraylowerbound"]
	
	do_rumble = w.IMPACTFRAME
	
	
	var paused = w.PAUSED
	var framechange = Input.is_action_just_pressed("nextframe")
	var _intro = w.FRAME < 0
	var slowmo = w.SLOMOFRAME % 2 != 1 && w.SLOMOFRAME > 0
	if ((!paused) || framechange) && !slowmo:
		
		minx = 0
		miny = 0
		maxx = 0
		maxy = 0
		
		NUM_OF_ACTIVE_PLAYERS = 0
		for i in range(w.NUM_OF_PLAYERS):
			var node_name = "../Player" + str(i+1)
			var pxpos = get_node(node_name).get_position().x
			var pypos = get_node(node_name).get_position().y
			if !get_node(node_name).defeated:
				NUM_OF_ACTIVE_PLAYERS += 1
				if NUM_OF_ACTIVE_PLAYERS == 1:
					minx = pxpos - smargx
					maxx = pxpos + smargx
					miny = pypos - smargy
					maxy = pypos + smargy
				else:
					minx = min(minx, pxpos - smargx)
					maxx = max(maxx, pxpos + smargx)
					miny = min(miny, pypos - smargy)
					maxy = max(maxy, pypos + smargy)
					
		for i in range(len(w.projectiles)):
			if w.projectiles[i]!=null:
				if w.projectiles[i].important_to_camera:
					var pxpos = w.projectiles[i].get_position().x
					var pypos = w.projectiles[i].get_position().y
					minx = min(minx, pxpos - smargx)
					maxx = max(maxx, pxpos + smargx)
					miny = min(miny, pypos - smargy)
					maxy = max(maxy, pypos + smargy)
					
		minx = clamp(minx, -XBOUNDS, XBOUNDS)
		maxx = clamp(maxx, -XBOUNDS, XBOUNDS)
		miny = clamp(miny, YUPPERBOUND, YLOWERBOUND)
		maxy = clamp(maxy, YUPPERBOUND, YLOWERBOUND)
		
		
		SCREENX = Globals.SCREENX
		SCREENY = Globals.SCREENY - 128
		
		var finalmax
		if float(maxx-minx) / SCREENX > float(maxy-miny) / SCREENY:
			finalmax = float(maxx-minx) / SCREENX
		else:
			finalmax = float(maxy-miny) / SCREENY
		
		
		var zoomo = finalmax
		zoomo = lerp(zoomo,zoom.x,0.95)
		
		var biggestzoom = 0.5 * 1920 / SCREENX
		var smallestzoom = 4 * 1920 / SCREENX
		zoomo = clamp(zoomo, biggestzoom, smallestzoom)
		zoom = Vector2(zoomo, zoomo) 
		
		x_offset = (maxx+minx)/2
		y_offset = (maxy+miny)/2
		
		
		#x_offset = clamp(x_offset, -XBOUNDS*zoomo, XBOUNDS*zoomo)
		
		#x_offset = clamp(x_offset,-XBOUNDS-SCREENX/zoomo,XBOUNDS+SCREENX/zoomo)
		#y_offset = clamp(y_offset,-YBOUNDS-SCREENY/zoomo, YBOUNDS+SCREENY/zoomo)
		
		x_offset = lerp(x_offset, finalposx, 0.95)
		y_offset = lerp(y_offset, finalposy, 0.95)
		
		if x_offset + zoom.x * SCREENX/2 > XBOUNDS:
			x_offset = XBOUNDS - zoom.x * SCREENX/2
			
		if x_offset - zoom.x * SCREENX/2 < -XBOUNDS:
			x_offset = -XBOUNDS + zoom.x * SCREENX/2
		
		if y_offset + zoom.x * SCREENY/2 > YLOWERBOUND:
			y_offset = YLOWERBOUND - zoom.y * SCREENY/2
			
		if y_offset - zoom.y * SCREENY/2 < YUPPERBOUND:
			y_offset = YUPPERBOUND + zoom.y * SCREENY/2
		
		
		rumblex = do_rumble * randi()%10
		rumbley = do_rumble * randi()%10
		finalposx = x_offset
		finalposy = y_offset
		set_position(Vector2(finalposx+rumblex, finalposy+rumbley+64))
		
		#Parallax.position = -.0125 * zoomo * Vector2(finalposx+rumblex, 0) + Vector2(Globals.SCREENX/2, Globals.SCREENY)
		#Parallax.scale = Vector2(2/sqrt(zoomo), 2/sqrt(zoomo))
		#Parallax.position = Vector2(SCREENX/2, SCREENY/2 + 500)
		#Parallax.scale = Vector2(SCREENX/1920, SCREENX/1920)
