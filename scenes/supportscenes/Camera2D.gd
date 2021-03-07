extends Camera2D


var minx = 0
var maxx = 0
var miny = 0
var maxy = 0
var x_offset = 0
var y_offset = 0
var XBOUNDS = 2500
var YLOWERBOUND = 800
var YUPPERBOUND = -800
var SCREENX = 200
var SCREENY = 200
var do_rumble = 0
var rumblex = 0
var rumbley = 0
var finalposx = 0
var finalposy = 0

var NUM_OF_ACTIVE_PLAYERS

func _ready():
	pass

func _process(_delta):
	
	do_rumble = Globals.IMPACTFRAME
	
	
	var paused = Globals.PAUSED
	var framechange = Input.is_action_just_pressed("nextframe")
	var intro = Globals.FRAME < 0
	var slowmo = Globals.SLOMOFRAME % 2 != 1 && Globals.SLOMOFRAME > 0
	if ((!paused) || framechange) && !slowmo:
		
		minx = 0
		miny = 0
		maxx = 0
		maxy = 0
		
		NUM_OF_ACTIVE_PLAYERS = 0
		for i in range(Globals.NUM_OF_PLAYERS):
			var node_name = "../Player" + str(i+1)
			var pxpos = get_node(node_name).get_position().x
			var pypos = get_node(node_name).get_position().y
			if !get_node(node_name).defeated:
				NUM_OF_ACTIVE_PLAYERS += 1
				if NUM_OF_ACTIVE_PLAYERS == 1:
					minx = pxpos
					miny = pypos
					maxx = pxpos
					maxy = pypos
				else:
					minx = min(minx, pxpos)
					maxx = max(maxx, pxpos)
					miny = min(miny, pypos)
					maxy = max(maxy, pypos)
					
		for i in range(len(Globals.projectiles)):
			if Globals.projectiles[i]!=null:
				if Globals.projectiles[i].important_to_camera:
					var pxpos = Globals.projectiles[i].get_position().x
					var pypos = Globals.projectiles[i].get_position().y
					minx = min(minx, pxpos)
					maxx = max(maxx, pxpos)
					miny = min(miny, pypos)
					maxy = max(maxy, pypos)
		
		var finalmax = max(abs(maxx-minx), abs(maxy-miny)*2)
		
		SCREENX = Globals.SCREENX
		SCREENY = Globals.SCREENY - 400
		
		var biggestzoom = 0.75 * 1440 / SCREENX
		var smallestzoom = 2.5 * 1440 / SCREENX
		
		var zoomo = sqrt(finalmax)/22 * 1440 / SCREENX
		zoomo = lerp(zoomo,zoom.x,0.95)
		
		
		zoomo = clamp(zoomo, biggestzoom, smallestzoom)
		zoom = Vector2(zoomo, zoomo) 
		
		x_offset = (maxx+minx)/2
		y_offset = (maxy+miny)/2
		
		#x_offset = clamp(x_offset, -XBOUNDS*zoomo, XBOUNDS*zoomo)
		
		#x_offset = clamp(x_offset,-XBOUNDS-SCREENX/zoomo,XBOUNDS+SCREENX/zoomo)
		#y_offset = clamp(y_offset,-YBOUNDS-SCREENY/zoomo, YBOUNDS+SCREENY/zoomo)
		
		x_offset = lerp(x_offset, finalposx, 0.95)
		y_offset = lerp(y_offset, finalposy, 0.95)
		
		var xadj = SCREENX*0.5*zoomo
		var yadj = SCREENY*0.5*zoomo
		
		if x_offset < -XBOUNDS + xadj:
			x_offset = -XBOUNDS + xadj
		
		if x_offset > XBOUNDS - xadj:
			x_offset = XBOUNDS - xadj
		
		if y_offset > YLOWERBOUND - yadj:
			y_offset = YLOWERBOUND - yadj
		
		if y_offset < YUPPERBOUND + yadj:
			y_offset = YUPPERBOUND + yadj
		
		
		
		rumblex = do_rumble * randi()%10
		rumbley = do_rumble * randi()%10
		finalposx = x_offset
		finalposy = y_offset
		set_position(Vector2(finalposx+rumblex, finalposy+rumbley+64))
