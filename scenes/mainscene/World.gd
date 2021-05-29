extends Node2D

onready var SPACEDOG = preload("res://characters/spacedog/Spacedog.tscn")
onready var TODD = preload("res://characters/todd/Todd.tscn")
onready var BALL = preload("res://projectiles/ball/Ball.tscn")
onready var EFFECT = preload("res://resources/ImpactEffect.tscn")
onready var DAMAGE = preload("res://ui/Damage.tscn")
onready var TAG = preload("res://ui/Tag.tscn")


var NUM_OF_PLAYERS = 2
var STOCKS = 4
var TIME = 120
var GAMEMODE = "STOCK"
var SHOWHITBOXES = false
var TEAMATTACK = false
var TEAMMODE = false
var STAGE = 0
var SCORETOWIN = 5
var ONLINE = false
var ISSERVER = false


var LEDGES = []
var PLATFORMLEDGES = []
var TOPBLASTZONE = -1100
var BOTTOMBLASTZONE = 1300
var SIDEBLASTZONE = 3000
var DOUBLEBLASTZONE = 1152
var TRIPLEBLASTZONE = 2048

var RIGHTSCORE = 0
var LEFTSCORE = 0

var FRAME = 0
var PAUSED = false
var IMPACTFRAME = 0
var GAMEENDFRAME = 0
var SLOMOFRAME = 0
var KOFRAME = 0
var DOUBLEKOFRAME = 0
var TRIPLEKOFRAME = 0
var LEFTSCOREFRAME = 0
var RIGHTSCOREFRAME = 0
var DEFEATORDER = []
var ELIMINATIONFRAME = 0
var ELIMINATEDPLAYER = 0
var CSSBACKFRAME = 0
var COMBO = 0

var spawnpositions


var players = []
var projectiles = []

var iq = []

func _ready():
	
	if !ONLINE:
		GAMEMODE = Globals.GAMEMODE
		TIME = Globals.TIME
		STOCKS = Globals.STOCKS
		NUM_OF_PLAYERS = Globals.NUM_OF_PLAYERS
		TEAMMODE = Globals.TEAMMODE
		STAGE = Globals.STAGE
		SCORETOWIN = Globals.SCORETOWIN
	ONLINE = Globals.ONLINE
	ISSERVER = Globals.ISSERVER
	
	var stage = null
	match STAGE:
		0:
			stage = load("res://stage/FinalDestination.tscn").instance()
			LEDGES = [[Vector2(-640, 256), 1, 0], [Vector2(640, 256), -1, 0]]
		1:
			stage = load("res://stage/SoccerField.tscn").instance()
		2:
			stage = load("res://stage/TheVoid.tscn").instance()
	stage.name = "Stage"
	add_child(stage)
	
	TOPBLASTZONE = Globals.STAGEDATA[STAGE]["TOPBLASTZONE"]
	BOTTOMBLASTZONE = Globals.STAGEDATA[STAGE]["BOTTOMBLASTZONE"]
	SIDEBLASTZONE = Globals.STAGEDATA[STAGE]["SIDEBLASTZONE"]
	DOUBLEBLASTZONE = Globals.STAGEDATA[STAGE]["DOUBLEBLASTZONE"]
	TRIPLEBLASTZONE = Globals.STAGEDATA[STAGE]["TRIPLEBLASTZONE"]
	
	SHOWHITBOXES = false
	if !ONLINE:
		PAUSED = false
	if GAMEMODE == "TRAINING":
		FRAME = 0
	else:
		FRAME = -180
	DOUBLEKOFRAME = 0
	TRIPLEKOFRAME = 0
	GAMEENDFRAME = 0
	SLOMOFRAME = 0
	LEFTSCOREFRAME = 0
	RIGHTSCOREFRAME = 0
	ELIMINATIONFRAME = 0
	DEFEATORDER = []
	for _i in range(NUM_OF_PLAYERS):
		DEFEATORDER.append(0)
	
	LEFTSCORE = 0
	RIGHTSCORE = 0
	
	if !ONLINE:
	
		delete_children(self)
		players = []
		projectiles = []
		
		
		var pos = []
		for i in NUM_OF_PLAYERS:
			pos.append(Globals.STAGEDATA[STAGE]["spawnpositions"][i])


		spawnpositions = [] 
		var indexList = range(NUM_OF_PLAYERS)
		for p in range(NUM_OF_PLAYERS):
			var x = 0
			if TEAMMODE:
				var d = 1
				if Globals.playerteams[p] == 1:
					d = -1
				x = randi()%indexList.size()
				var j = 0
				while pos[indexList[x]].x * d > 0 && j < 100:
					x = randi()%indexList.size()
					j += 1
			else:
				x = randi()%indexList.size()
			spawnpositions.append(pos[indexList[x]])
			indexList.remove(x)

		
		for i in range(NUM_OF_PLAYERS):
			var character = Globals.playerchars[i]
			var characterdict = {-1: SPACEDOG, 0: SPACEDOG, 1:TODD}
			players.append(characterdict[character].instance())
			
			add_child(players[i])
		
			resetplayer(i)
		
			
			var damage_card = DAMAGE.instance()
			damage_card.playernumber = i+1
			damage_card.character = players[i].character
			$CanvasLayer.add_child(damage_card)
			
			var tag = TAG.instance()
			tag.playernumber = i+1
			tag.controller =  players[i].controller
			add_child(tag)
		
		if GAMEMODE == "SOCCER":
			spawnball()
	

static func delete_children(node):
	for n in node.get_children():
		if n.get_class() == "KinematicBody2D":
			node.remove_child(n)
			n.queue_free()

func resetplayer(i):
	
	var pos = spawnpositions[i]
	if pos.x != 0:
		players[i].d = -pos.x / abs(pos.x)
	else:
		players[i].d = 1
	players[i].playernumber = i+1
	players[i].character = Globals.characternames[Globals.playerchars[i]]
	players[i].name = "Player" + str(i+1)
	players[i].skin = Globals.playerskins[i]
	players[i].controller = Globals.playercontrollers[i]
	players[i].team = Globals.playerteams[i]
	players[i].respawn(pos, true)
	

func _process(_delta):
	
	if ISSERVER:
		modulate.a = .5
		$Camera2D.current = false
	
	if ONLINE && !ISSERVER:
		
		if get_tree().get_root().get_node_or_null("Lobby") == null:
			Globals.INGAME = false
			Globals.CONNECTED = false
		
		else:
			var player_info = get_tree().get_root().get_node("Lobby").player_info
			for p in players:
				if !p.is_network_master():
					if !player_info.has(p.playerid):
						Globals.INGAME = false
		
		
		if (!Globals.CONNECTED || !Globals.INGAME):
			print("I'VE DISCONNECTED")
			get_tree().network_peer = null
			go_to_menu()
	
	if GAMEENDFRAME == 0:
		
		
		if !ONLINE:
			if Input.is_action_just_pressed("pause"):
				PAUSED = !PAUSED
			
			if Input.is_action_just_pressed("select"):
				SHOWHITBOXES = !SHOWHITBOXES

			if Input.is_action_just_pressed("swap"):
				if players[0].controller == 1:
					players[0].controller = 0
					players[1].controller = 1
				else:
					players[0].controller = 1
					players[1].controller = 0
		
			if (Input.is_action_just_pressed("reset")):
				for i in range(NUM_OF_PLAYERS):
					resetplayer(i)
				for p in projectiles:
					if p != null:
						p.respawn(p.spawnposition)
				
			if (Input.is_action_just_pressed("pause") &&
				Input.is_action_pressed("attack") &&
				Input.is_action_pressed("shield")):
				go_to_menu()
	
	if IMPACTFRAME > 0:
		IMPACTFRAME -= 1
		
	
	if players.size() > 1:
		COMBO = players[1].combo
	
	if !ISSERVER:
		bottommenu()
		background()
	
	
	var paused = PAUSED
	var framechange = Input.is_action_just_pressed("nextframe")
	if ((!paused) || framechange):
		FRAME += 1
		
		if ELIMINATIONFRAME > 0:
			ELIMINATIONFRAME -= 1
		if KOFRAME > 0:
			KOFRAME -= 1
		if DOUBLEKOFRAME > 0:
			DOUBLEKOFRAME -= 1
		if TRIPLEKOFRAME > 0:
			TRIPLEKOFRAME -= 1
		if RIGHTSCOREFRAME > 0:
			RIGHTSCOREFRAME -= 1
		if LEFTSCOREFRAME > 0:
			LEFTSCOREFRAME -= 1
			
		if GAMEENDFRAME == 0:
			get_node("Sounds").get_node("Music").stream_paused = false
			if Globals.MUTED:
				get_node("Sounds").get_node("Music").volume_db = -80
			else:
				get_node("Sounds").get_node("Music").volume_db = 0
				
				
			var players_left = players.size()
			for p in players:
				if p.defeated:
					players_left -= 1
			if players_left < 2:
				GAMEENDFRAME = 1
				Globals.RESULTDATA = getresultdata()
			
			elif TIME > 0 && FRAME > TIME * 60:
				if GAMEMODE == "TIME":
					Globals.RESULTDATA = getresultdata()
			
				elif GAMEMODE == "SOCCER":
					GAMEENDFRAME = 1
					Globals.LEFTSCORE = LEFTSCORE
					Globals.RIGHTSCORE = RIGHTSCORE
					Globals.RESULTDATA = getresultdata()
				
				elif GAMEMODE == "STOCK":
					GAMEENDFRAME = 1
					Globals.RESULTDATA = getresultdata()
					
				
		if GAMEENDFRAME > 0:
			get_node("Sounds").get_node("Music").stream_paused = true
			GAMEENDFRAME += 1
			SLOMOFRAME += 1
			if GAMEENDFRAME > 120:
				results()
		
		spaceoutplayers()
		
		interactions()
		
func go_to_menu():
	Globals.MENU = "CSS"
	var _menu = get_tree().change_scene("res://scenes/supportscenes/Menu.tscn")
	queue_free()
		
func results():
	var _results = get_tree().change_scene("res://scenes/supportscenes/Results.tscn")
	
func spaceoutplayers():
	var pushythings = []
	for p in players:
		pushythings.append(p)
	for p in projectiles:
		if p != null:
			if p.pushable:
				pushythings.append(p)
	for i in range(pushythings.size()):
		for j in range(i+1,pushythings.size()):
			var ps = [pushythings[i], pushythings[j]]
			var pushymoves = ["idle", "run", "runend", "turnaround", "shield", "crouch", "land", "jumpstart", "knockeddown"]
			if (
			#running into idle player: both move.
				(pushymoves.has(ps[0].state) &&
				pushymoves.has(ps[1].state))): 
			
				var pos0 = ps[0].get_position() + ps[0].SHIELDOFFSET
				var pos1 = ps[1].get_position() + ps[1].SHIELDOFFSET
				if (pos0-pos1).length() < ps[0].pushradius + ps[1].pushradius:
					var averagexmotion = (ps[0].motion.x+ps[1].motion.x)/2
					var xdiff = pos0.x-pos1.x
					ps[0].motion.x = averagexmotion
					ps[1].motion.x = averagexmotion
					
					var maxaccel = 500
					var accel0
					var accel1
					if xdiff !=0:
						accel0 = clamp(ps[0].ACCEL*(50/xdiff), -maxaccel, maxaccel)
						accel1 = clamp(ps[1].ACCEL*(50/xdiff), -maxaccel, maxaccel)
					else:
						accel0 = maxaccel
						accel1 = maxaccel
					ps[0].motion.x += accel0
					ps[1].motion.x -= accel1

func interactions():
	
	iq = []
	for i in range(players.size()):
		#player detecting player
		for j in range(players.size()):
			if j != i:
				var ps = [players[i], players[j]]
				for h in ps[1].hitboxes:
					for b in range(len(h.topleft)):
						checkforoverlap(ps,h,b)
						
						
		#player detecting projectile
		for p in projectiles:
			if p != null:
				var ps = [players[i], p]
				for h in ps[1].hitboxes:
					for b in range(len(h.topleft)):
						checkforoverlap(ps,h,b,true)
	
		#projectile detecting player
		for p in projectiles:
			if p != null:
				var ps = [p, players[i]]
				for h in ps[1].hitboxes:
					for b in range(len(h.topleft)):
						checkforoverlap(ps,h,b)
				checkforreflect(ps)
	
	for i in iq:
		match i[0]:
			"shield":
				shieldattack(i[1], i[2], i[3])
			"invincible":
				invincibleattack(i[1], i[2], i[3])
			"hit":
				behurt(i[1], i[2], i[3])
			"reflect":
				reflect(i[1])
			


func checkforoverlap(ps,h,b,player_on_projectile = false):
	if (!(ps[0].intangibility_frame > 0) &&  #thing attacked must not be intangible
	!(ps[1].state == "ledge") && 
	!(h.players_to_ignore.has(ps[0].playernumber)) &&   #thing attacked must not already attacked by this hitbox
	(h.startframe[b] < FRAME) && #hitbox must be out
	(h.startframe[b] + h.boxlengths[b]>= FRAME) &&
	((!player_on_projectile) || (ps[0].playernumber != ps[1].playernumber))): #players can't attack their own projectiles
		if (!(TEAMMODE && TEAMATTACK && (ps[0].team == ps[1].team)) && #teammates can't attack each other with TEAMMATTACK off
		!(ps[0].holder > 0)): #thing can't be held by a player
			var them = ps[1].get_position()
			var me = ps[0].get_position() + Vector2(ps[0].hurtboxoffset.x * ps[0].d, ps[0].hurtboxoffset.y)
			var htl = h.topleft[b]
			var hbr = h.bottomright[b]
			var hcenter = Vector2((htl.x+hbr.x)/2,(htl.y+hbr.y)/2)
			var hsize = Vector2(abs(htl.x-hbr.x)/2, abs(htl.y-hbr.y)/2)
			var xdist = abs(me.x - (them.x + (hcenter.x*h.d)))
			var ydist = abs(me.y - (them.y + hcenter.y))
			if  xdist < (ps[0].hurtboxsize.x + hsize.x) && ydist < (ps[0].hurtboxsize.y + hsize.y):
				if (ps[0].state == "shield" && ps[0].frame > 1) || ps[0].state == "shieldstun":
					if !player_on_projectile:
						iq.append(["shield", ps, h, b])
				elif (ps[0].invincibility_frame > 0):
					iq.append(["invincible", ps, h, b])
				else:
					iq.append(["hit", ps, h, b])

func checkforreflect(ps):
	if !(ps[0].holder > 0):
		var them = ps[1].get_position() + Vector2(ps[1].SHIELDOFFSET.x * ps[1].d, ps[1].SHIELDOFFSET.y)
		var me = ps[0].get_position() + Vector2(ps[0].hurtboxoffset.x * ps[0].d, ps[0].hurtboxoffset.y)
		var xdist = (ps[1].shield_physical_size + ps[0].hurtboxsize.x)
		var ydist = (ps[1].shield_physical_size + ps[0].hurtboxsize.y)
		if  abs(them.x-me.x) < xdist && abs(them.y-me.y) < ydist:
			if (((ps[1].state == "shield" && ps[1].frame > 1) || ps[1].state == "shieldstun") && 
				!ps[0].state == "reflect" &&
				!ps[0].player_who_last_hit_me == ps[1].playernumber):
				iq.append(["reflect", ps])


func shieldattack(ps,h,b):
	h.players_to_ignore.append(ps[0].playernumber)
	ps[0].state = "shieldstun"
	ps[0].frame = 1
	ps[0].stage = 0
	ps[0].shield_stun = h.shieldstun[b]
	ps[0].shield_size -= h.shieldstun[b] * 4
	if ps[0].shield_size < 30:
		ps[0].state = "shieldbreak"
		ps[0].nextstate = "shieldbreak"
		ps[0].motion = Vector2(0, ps[0].JUMPFORCE*-1.5)
		playsound("SHIELDBREAK")
	else:
		playsound("SHIELDHIT")
	ps[0].player_who_last_hit_me = ps[1].playernumber
	var hitlength = h.shieldstun[b]
	if hitlength > ps[0].impact_frame:
		ps[0].impact_frame = hitlength
	hitlength = h.stun[b]
	if hitlength > ps[1].impact_frame:
		ps[1].impact_frame = hitlength
	ps[1].shieldconnected = true
	
func invincibleattack(ps,h,b):
	ps[0].player_who_last_hit_me = ps[1].playernumber
	h.players_to_ignore.append(ps[0].playernumber)
	var hitlength = h.stun[b]
	if hitlength > ps[1].impact_frame:
		ps[1].impact_frame = hitlength
	ps[1].shieldconnected = true
	
func behurt(ps,h,b):
	h.players_to_ignore.append(ps[0].playernumber)
	ps[0].damage += h.damage[b]
	if h.hitstun[b]:
		combocounter(ps)
		impact(ps, h, b)
		ps[0].state = "hitstun"
		if ps[1].d == 1:
			ps[0].launch_direction = h.hitdirection[b]
		else:
			ps[0].launch_direction = 180-h.hitdirection[b]
		ps[0].frame = 1
		ps[0].stage = 0
		if !ps[0].is_projectile:
			ps[0].has_airdodge = true
			ps[0].floatframe = ps[0].FLOATTIME
			#ps[1].has_double_jump = true
		ps[0].motion = Vector2(0,0)
		ps[0].hitter_motion = ps[1].motion * .1
		ps[0].player_who_last_hit_me = ps[1].playernumber
		ps[0].launch_knockback = ps[0].damage * 50 * h.knockback[b] + h.constknockback[b]
		if ps[0].launch_direction%360 < 90 || ps[0].launch_direction%360 > 270:
			ps[0].d = -1
		else:
			ps[0].d = 1
		playsound("HIT")
			
	Input.start_joy_vibration(0, 1, 1, 0.1)
	ps[1].connected = true
	
	if (ps[0].launch_knockback > ps[0].LAUNCH_THRESHOLD && b == 0):
		pass
	
	if h.stun[b] > 0:
		visualstun(ps, h, b)
	
func visualstun(ps, h, b):
	ps[0].stun_length = int(21+ps[0].damage/15)
	var hitlength = int(h.stun[b] + ps[0].damage/40)
	if hitlength > ps[0].impact_frame:
		ps[0].impact_frame = hitlength
	if hitlength > ps[1].impact_frame:
		ps[1].impact_frame = hitlength
	IMPACTFRAME = hitlength
	
func impact(ps, h, b):
	var effect = EFFECT.instance()
	var hboxpos = h.get_parent().get_position() + (h.topleft[b]/2 + h.bottomright[b]/2) * Vector2(h.get_parent().d, 0)
	effect.position = (hboxpos + ps[0].get_position())/2
	effect.d = h.d
	effect.myframe = 0
	effect.playernumber = ps[0].playernumber
	effect.effecttype = "impact"
	effect.scale = Vector2(1,1) + Vector2(h.damage[b], h.damage[b]) / 10.0
	if ps[0].combo > 1:
		effect.modulate = Color(1,0,1,1)
	elif ["neutralground", "sideground", "upground", "downground", "neutralair", "forwardair", "backair", "upair", "downair", "neutralspecial", "sidespecial", "upspecial", "downspecial", "shieldstun"].has(ps[0].state) && ps[0].stage > 0:
		effect.modulate = Color(0,1,1,1)
	else:
		effect.modulate = Color(1,1,1,1)
	add_child(effect)
	
func combocounter(ps):
	if ["hitstun", "mildstun"].has(ps[0].state) || (ps[0].state == "hit" && ps[0].stage == 0):
		ps[0].combo+=1
	else:
		ps[0].combo = 1
		
func reflect(ps):
#	var pos0 = ps[0].get_position() + ps[1].SHIELDOFFSET
#	var pos1 = ps[1].get_position() + ps[1].SHIELDOFFSET
	#ps[0].motion = (pos0-pos1).normalized() * (ps[0].motion.length()+200)
	var stun = ps[0].shieldstun
	if ps[0].projectiletype != "ball":
		ps[0].shieldstun += 4
		ps[0].damage_delt *= 1.5
	ps[0].motion = ps[0].motion * -1.5
	ps[1].state = "shieldstun"
	ps[1].frame = 0
	ps[1].stage = 0
	ps[1].shield_stun = stun
	ps[1].shield_size -= stun * 4
	if ps[1].shield_size < 30:
		ps[1].state = "shieldbreak"
		ps[1].motion = Vector2(0, ps[1].JUMPFORCE*-1.5)
	var hitlength = stun
	if hitlength > ps[0].impact_frame:
		ps[0].impact_frame = hitlength
	if hitlength > ps[1].impact_frame:
		ps[1].impact_frame = hitlength
	ps[0].connected = false
	ps[0].state = "reflect"
	ps[0].frame = 0
	ps[0].stage = 0
	ps[0].player_who_last_hit_me = ps[1].playernumber
	ps[0].playernumber = ps[1].playernumber
	
	var effect = EFFECT.instance()
	effect.position = (ps[0].get_position() + ps[1].get_position()) / 2
	effect.d = 1
	effect.myframe = 0
	effect.playernumber = ps[1].playernumber
	effect.effecttype = "reflect"
	add_child(effect)
	
	playsound("REFLECT")

func spawnball():
	var ball = BALL.instance()
	ball.position = Globals.STAGEDATA[STAGE]["ballspawn"]
	ball.d = 1
	ball.frame = 0
	ball.playernumber = 0
	add_child(ball)
	projectiles.append(ball)
	ball.start()

func bottommenu():
	var SCREENX = Globals.SCREENX
	var SCREENY = Globals.SCREENY

	$CanvasLayer/BottomBar.margin_left = 0
	$CanvasLayer/BottomBar.margin_right = SCREENX + 128
	$CanvasLayer/BottomBar.margin_top = SCREENY - 128
	$CanvasLayer/BottomBar.margin_bottom = SCREENY + 128
	
	$CanvasLayer/Score.margin_left = SCREENX/2 - 256
	$CanvasLayer/Score.margin_right = SCREENX/2 + 256
	$CanvasLayer/Score.margin_top = SCREENY - 128
	$CanvasLayer/Score.margin_bottom = SCREENY
	
	$CanvasLayer/Time.margin_left = 0
	$CanvasLayer/Time.margin_right = SCREENX - 32
	$CanvasLayer/Time.margin_top = 32
	$CanvasLayer/Time.margin_bottom = 64
	
	if PAUSED:
		$CanvasLayer/BottomBarFront.visible = true
		$CanvasLayer/BottomBarFront.margin_left = 0
		$CanvasLayer/BottomBarFront.margin_right = SCREENX
	else:
		if NUM_OF_PLAYERS == 2 || TEAMMODE:
			$CanvasLayer/BottomBarFront.margin_left = SCREENX/2 - 256
			$CanvasLayer/BottomBarFront.margin_right = SCREENX/2 + 256
			$CanvasLayer/BottomBarFront.visible = true
		else:
			$CanvasLayer/BottomBarFront.visible = false
	$CanvasLayer/BottomBarFront.margin_top = SCREENY - 128
	$CanvasLayer/BottomBarFront.margin_bottom = SCREENY
	
	
	var margin = 20
	$CanvasLayer/Pause.margin_left = 0 + margin
	$CanvasLayer/Pause.margin_right = SCREENX + 128 - margin
	$CanvasLayer/Pause.margin_top = SCREENY - 128 + margin
	$CanvasLayer/Pause.margin_bottom = SCREENY + 128 - margin
	
	$CanvasLayer/Pause.visible = PAUSED
	$CanvasLayer/PauseEffect.visible = PAUSED
	if PAUSED:
		$CanvasLayer/PauseEffect.margin_left = 0
		$CanvasLayer/PauseEffect.margin_right = SCREENX + 128
		$CanvasLayer/PauseEffect.margin_top = 0
		$CanvasLayer/PauseEffect.margin_bottom = SCREENY - 128
	
	
	#3 2 1 GO!!
	$CanvasLayer/Message.margin_left = 0
	$CanvasLayer/Message.margin_right = SCREENX
	$CanvasLayer/Message.margin_top = 0
	$CanvasLayer/Message.margin_bottom = SCREENY - 128
	
	if !(GAMEMODE == "TRAINING") &&  FRAME < 60:
		$CanvasLayer/Message.visible = true
		if FRAME < -120:
			$CanvasLayer/Message.text = "3"
		elif FRAME < -60:
			$CanvasLayer/Message.text = "2"
		elif FRAME < 0:
			$CanvasLayer/Message.text = "1"
		else:
			$CanvasLayer/Message.text = "GO!"
	elif GAMEENDFRAME > 0:
		$CanvasLayer/Message.set("custom_colors/font_color", Color(1,1,1,1))
		$CanvasLayer/Message.visible = true
		$CanvasLayer/Message.text = "GAME!"
	elif ELIMINATIONFRAME > 0:
		$CanvasLayer/Message.visible = true
		if ELIMINATEDPLAYER > 0:
			$CanvasLayer/Message.text = "PLAYER " + str(players[ELIMINATEDPLAYER-1].controller) + "\nDEFEATED"
		else:
			$CanvasLayer/Message.text = "COMPUTER \nPLAYER \nDEFEATED"
		if ELIMINATIONFRAME%10 < 6:
			$CanvasLayer/Message.set("custom_colors/font_color", Color(1,1,1,1))
		else:
			$CanvasLayer/Message.set("custom_colors/font_color", Globals.CONTROLLERCOLORS[players[ELIMINATEDPLAYER-1].controller])
	elif TRIPLEKOFRAME > 0:
		$CanvasLayer/Message.visible = true
		$CanvasLayer/Message.text = "TRIPLE K.O."
		if TRIPLEKOFRAME%10 < 6:
			$CanvasLayer/Message.set("custom_colors/font_color", Color(1,1,1,1))
		else:
			$CanvasLayer/Message.set("custom_colors/font_color", Color(1,.5,1,1))
	elif DOUBLEKOFRAME > 0:
		$CanvasLayer/Message.visible = true
		$CanvasLayer/Message.text = "DOUBLE K.O."
		if DOUBLEKOFRAME%10 < 6:
			$CanvasLayer/Message.set("custom_colors/font_color", Color(1,1,1,1))
		else:
			$CanvasLayer/Message.set("custom_colors/font_color", Color(1,1,.5,1))
	elif KOFRAME > 0:
		if NUM_OF_PLAYERS == 2:
			$CanvasLayer/Message.set("custom_colors/font_color", Color(1,1,1,1))
			$CanvasLayer/Message.visible = true
			$CanvasLayer/Message.text = str(players[0].stock) + "-" + str(players[1].stock)
	elif LEFTSCOREFRAME > 0:
		if LEFTSCOREFRAME%10 < 6:
			$CanvasLayer/Message.set("custom_colors/font_color", Color(1,1,1,1))
		else:
			$CanvasLayer/Message.set("custom_colors/font_color", Globals.LEFTCOLOR)
		$CanvasLayer/Message.visible = true
		$CanvasLayer/Message.text = "LEFT SCORES!"
		#$CanvasLayer/Message.text += "\n" + str(LEFTSCORE) + "-" + str(RIGHTSCORE)
	elif RIGHTSCOREFRAME > 0:
		if RIGHTSCOREFRAME%10 < 6:
			$CanvasLayer/Message.set("custom_colors/font_color", Color(1,1,1,1))
		else:
			$CanvasLayer/Message.set("custom_colors/font_color", Globals.RIGHTCOLOR)
		$CanvasLayer/Message.visible = true
		$CanvasLayer/Message.text = "RIGHT SCORES!"
		#$CanvasLayer/Message.text += "\n" + str(LEFTSCORE) + "-" + str(RIGHTSCORE)
	elif TIME > 0 && FRAME > TIME*60-300 && !(GAMEMODE == "TRAINING"):
		$CanvasLayer/Message.visible = true
		$CanvasLayer/Message.text = str((TIME*60-FRAME)/60+1)
		if GAMEENDFRAME > 0:
			$CanvasLayer/Message.visible = true
			$CanvasLayer/Message.text = "GAME!"
	else:
		$CanvasLayer/Message.visible = false

func background():
	
	var SCREENX = Globals.SCREENX
	var SCREENY = Globals.SCREENY
	
	$Stage/Background/Background.margin_left = -$Camera2D.rumblex
	$Stage/Background/Background.margin_top = -$Camera2D.rumbley
	$Stage/Background/Background.margin_right = max(SCREENX,SCREENY)/4 -$Camera2D.rumblex
	$Stage/Background/Background.margin_bottom = max(SCREENX,SCREENY)/4  -$Camera2D.rumbley
	
	var bottom = BOTTOMBLASTZONE
	var top = TOPBLASTZONE
	var side = SIDEBLASTZONE
	var side2 = DOUBLEBLASTZONE
	var side3 = TRIPLEBLASTZONE
	$Stage/LeftDoubleZone.margin_bottom = bottom
	$Stage/LeftDoubleZone.margin_top = top
	$Stage/LeftTripleZone.margin_bottom = bottom
	$Stage/LeftTripleZone.margin_top = top
	$Stage/RightDoubleZone.margin_bottom = bottom
	$Stage/RightDoubleZone.margin_top = top
	$Stage/RightTripleZone.margin_bottom = bottom
	$Stage/RightTripleZone.margin_top = top
	
	$Stage/LeftDoubleZone.margin_left = -side
	$Stage/LeftDoubleZone.margin_right = -side2
	$Stage/LeftTripleZone.margin_left = -side
	$Stage/LeftTripleZone.margin_right = -side3
	$Stage/RightDoubleZone.margin_left = side2
	$Stage/RightDoubleZone.margin_right = side
	$Stage/RightTripleZone.margin_left = side3
	$Stage/RightTripleZone.margin_right = side
	
	
	var thetext = ""
	if GAMEMODE == "TIME" ||  GAMEMODE == "SOCCER":
		if TIME - (FRAME / 60) > 0:
			var seconds = (TIME - (FRAME / 60)) % 60
			var minutes = (TIME - (FRAME/60)) / 60
			var secondsprinted = str(seconds)
			if len(secondsprinted) == 1:
				secondsprinted = "0" + secondsprinted
			thetext = str(minutes) + ":" + secondsprinted
	else:
		var seconds = (FRAME / 60) % 60
		var minutes = (FRAME/60) / 60
		var secondsprinted = str(seconds)
		if len(secondsprinted) == 1:
			secondsprinted = "0" + secondsprinted
		thetext = str(minutes) + ":" + secondsprinted
	
	if GAMEMODE == "SOCCER":
		$Stage/LeftDoubleZone.color = Globals.LEFTSIDECOLOR
		$Stage/RightDoubleZone.color = Globals.RIGHTSIDECOLOR
		$Stage/LeftTripleZone.color = Globals.LEFTGOALCOLOR
		$Stage/RightTripleZone.color = Globals.RIGHTGOALCOLOR
		$Stage/LeftDoubleZone/Label.text = ""
		$Stage/RightDoubleZone/Label.text = ""
		$Stage/LeftTripleZone/Label.text = "+1"
		$Stage/RightTripleZone/Label.text = "+1"
		$CanvasLayer/Score.visible = true
		$CanvasLayer/Score.text = str(LEFTSCORE) + "-" + str(RIGHTSCORE)
		$CanvasLayer/Time.visible = true
		$CanvasLayer/Time.text = thetext
	else:
		$Stage/LeftDoubleZone.color = Globals.DOUBLECOLOR
		$Stage/RightDoubleZone.color = Globals.DOUBLECOLOR
		$Stage/LeftTripleZone.color = Globals.TRIPLECOLOR
		$Stage/RightTripleZone.color = Globals.TRIPLECOLOR
		$Stage/LeftDoubleZone/Label.text = "-2"
		$Stage/RightDoubleZone/Label.text = "-2"
		$Stage/LeftTripleZone/Label.text = "-3"
		$Stage/RightTripleZone/Label.text = "-3"
		$CanvasLayer/Score.visible = false
		$CanvasLayer/Time.visible = true
		$CanvasLayer/Time.text = thetext
		if players.size() == 2:
			$CanvasLayer/Score.text = str(players[0].stock) + "-" + str(players[1].stock)
			$CanvasLayer/Score.visible = true
		$CanvasLayer/Time.visible = FRAME > 0
		$CanvasLayer/Time.text = thetext
				
				
				
func playsound(sound):
	if !(Globals.MUTED || GAMEENDFRAME > 0):
		if sound == "HIT":
			sound = "HIT" + str(randi()%5)
		get_node("Sounds").get_node(sound).play()
		
func getresultdata():
	var results = []
	for p in players:
		var pdata = {}
		pdata.playernumber = p.playernumber
		pdata.tag = p.tag
		pdata.skin = p.skin
		pdata.controller = p.controller
		pdata.character = p.character
		pdata.team = p.team
		pdata.stock = p.stock
		pdata.score = p.score
		pdata.defeattime = p.defeattime

		results.append(pdata)
	return results
