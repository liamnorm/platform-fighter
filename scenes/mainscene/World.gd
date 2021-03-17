extends Node2D

onready var SPACEDOG = preload("res://characters/spacedog/Spacedog.tscn")
onready var TODD = preload("res://characters/todd/Todd.tscn")
onready var BALL = preload("res://projectiles/ball/Ball.tscn")
onready var EFFECT = preload("res://resources/ImpactEffect.tscn")
onready var DAMAGE = preload("res://ui/Damage.tscn")
onready var TAG = preload("res://ui/Tag.tscn")

var iq = []

func _ready():
	
	if Globals.GAMEMODE == "TRAINING":
		Globals.FRAME = 0
	else:
		Globals.FRAME = -180
	Globals.DOUBLEKOFRAME = 0
	Globals.TRIPLEKOFRAME = 0
	Globals.GAMEENDFRAME = 0
	Globals.SLOMOFRAME = 0
	Globals.LEFTSCOREFRAME = 0
	Globals.RIGHTSCOREFRAME = 0
	Globals.ELIMINATIONFRAME = 0
	Globals.DEFEATORDER = []
	for i in range(Globals.NUM_OF_PLAYERS):
		Globals.DEFEATORDER.append(0)
	
	Globals.LEFTSCORE = 0
	Globals.RIGHTSCORE = 0
	
	delete_children(self)
	Globals.PAUSED = false
	Globals.players = []
	Globals.projectiles = []
	for i in range(Globals.NUM_OF_PLAYERS):
		var character = Globals.playerchars[i]
		var characterdict = {-1: SPACEDOG, 0: SPACEDOG, 1:TODD}
		Globals.players.append(characterdict[character].instance())
	
		resetplayer(i)
		
		add_child(Globals.players[i])
		
		var damage_card = DAMAGE.instance()
		damage_card.playernumber = i+1
		damage_card.character = Globals.players[i].character
		$CanvasLayer.add_child(damage_card)
		
		var tag = TAG.instance()
		tag.playernumber = i+1
		tag.controller =  Globals.players[i].controller
		add_child(tag)
	
	if Globals.GAMEMODE == "SOCCER":
		spawnball()
	

static func delete_children(node):
	for n in node.get_children():
		if n.get_class() == "KinematicBody2D":
			node.remove_child(n)
			n.queue_free()

func resetplayer(i):
	var pos
	if Globals.NUM_OF_PLAYERS != 1:
		pos = Vector2((i-(Globals.NUM_OF_PLAYERS-1.0)/2.0)*1440.0/(Globals.NUM_OF_PLAYERS), 0)
	else:
		pos = Vector2(0,0)
	if pos.x != 0:
		Globals.players[i].d = -pos.x / abs(pos.x)
	else:
		Globals.players[i].d = 1
	Globals.players[i].playernumber = i+1
	Globals.players[i].character = Globals.characternames[Globals.playerchars[i]]
	Globals.players[i].name = "Player" + str(i+1)
	Globals.players[i].skin = Globals.playerskins[i]
	Globals.players[i].controller = Globals.playercontrollers[i]
	Globals.players[i].team = Globals.playerteams[i]
	Globals.players[i].respawn(pos, true)
	

func _process(_delta):
	
	if Globals.GAMEENDFRAME == 0:
		if Input.is_action_just_pressed("pause"):
			Globals.PAUSED = !Globals.PAUSED
			
		if Input.is_action_just_pressed("select"):
			Globals.SHOWHITBOXES = !Globals.SHOWHITBOXES
		
		if (Input.is_action_just_pressed("reset")):
			for i in range(Globals.NUM_OF_PLAYERS):
				resetplayer(i)
			for p in Globals.projectiles:
				if p != null:
					p.respawn(p.spawnposition)
				
		if (Input.is_action_just_pressed("pause") &&
			Input.is_action_pressed("attack") &&
			Input.is_action_pressed("shield")):
			go_to_menu()
	
	if Globals.IMPACTFRAME > 0:
		Globals.IMPACTFRAME -= 1
		
		
	if Globals.NUM_OF_PLAYERS > 1:
		Globals.COMBO = Globals.players[1].combo
	
	bottommenu()
	background()
	
	
	var paused = Globals.PAUSED
	var framechange = Input.is_action_just_pressed("nextframe")
	if ((!paused) || framechange):
		Globals.FRAME += 1
		
		if Globals.ELIMINATIONFRAME > 0:
			Globals.ELIMINATIONFRAME -= 1
		if Globals.KOFRAME > 0:
			Globals.KOFRAME -= 1
		if Globals.DOUBLEKOFRAME > 0:
			Globals.DOUBLEKOFRAME -= 1
		if Globals.TRIPLEKOFRAME > 0:
			Globals.TRIPLEKOFRAME -= 1
		if Globals.RIGHTSCOREFRAME > 0:
			Globals.RIGHTSCOREFRAME -= 1
		if Globals.LEFTSCOREFRAME > 0:
			Globals.LEFTSCOREFRAME -= 1
			
		if Globals.GAMEENDFRAME == 0:
			if Globals.GAMEMODE == "TIME" && Globals.FRAME > Globals.TIME*60:
				var winner = 0
				var maxscore = 0
				for i in range(Globals.NUM_OF_PLAYERS):
					if Globals.players[i].score > maxscore:
						winner = i+1
						maxscore = Globals.players[i].score
				Globals.GAMEENDFRAME = 1
				Globals.WINNER = winner
				if Globals.WINNER != 0:
					Globals.WINNERCHARACTER = Globals.players[winner-1].character
					Globals.WINNERCONTROLLER = Globals.players[winner-1].controller
		
			if Globals.GAMEMODE == "SOCCER" && Globals.FRAME > Globals.TIME*60:
				Globals.GAMEENDFRAME = 1
				if Globals.LEFTSCORE > Globals.RIGHTSCORE:
					Globals.WINNER = 1
				else:
					Globals.WINNER = 2
				
		if Globals.GAMEENDFRAME > 0:
			Globals.GAMEENDFRAME += 1
			Globals.SLOMOFRAME += 1
			if Globals.GAMEENDFRAME > 180:
				results()
		
		spaceoutplayers()
		
		interactions()
		
func go_to_menu():
	var _menu = get_tree().change_scene("res://scenes/supportscenes/Menu.tscn")
		
func results():
	var _results = get_tree().change_scene("res://scenes/supportscenes/Results.tscn")
	
func spaceoutplayers():
	for i in range(Globals.NUM_OF_PLAYERS):
		for j in range(i+1,Globals.NUM_OF_PLAYERS):
			var ps = [Globals.players[i], Globals.players[j]]
			var pushymoves = ["idle", "run", "runend", "turnaround", "shield", "crouch", "land", "jumpstart", "knockeddown"]
			if (
			#running into idle player: both move.
				(pushymoves.has(ps[0].state) &&
				pushymoves.has(ps[1].state))): 
			
				var pos0 = ps[0].get_position() + ps[0].SHIELDOFFSET
				var pos1 = ps[1].get_position() + ps[1].SHIELDOFFSET
				if (pos0-pos1).length() < 128:
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
	for i in range(Globals.NUM_OF_PLAYERS):
		#player detecting player
		for j in range(Globals.NUM_OF_PLAYERS):
			if j != i:
				var ps = [Globals.players[i], Globals.players[j]]
				for h in ps[1].hitboxes:
					for b in range(len(h.topleft)):
						checkforoverlap(ps,h,b)
						
						
		#player detecting projectile
		for p in Globals.projectiles:
			if p != null:
				var ps = [Globals.players[i], p]
				for h in ps[1].hitboxes:
					for b in range(len(h.topleft)):
						checkforoverlap(ps,h,b,true)
	
		#projectile detecting player
		for p in Globals.projectiles:
			if p != null:
				var ps = [p, Globals.players[i]]
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
	if (!(ps[0].intangibility_frame > 0) &&
	!(h.players_to_ignore.has(ps[0].playernumber)) && 
	(h.startframe[b] < Globals.FRAME) && 
	(h.startframe[b] + h.boxlengths[b]>= Globals.FRAME) &&
	(!player_on_projectile || ps[0].playernumber != ps[1].playernumber)):
		var them = ps[1].get_position()
		var me = ps[0].get_position() + ps[0].hurtboxoffset
		var htl = h.topleft[b]
		var hbr = h.bottomright[b]
		var hcenter = Vector2((htl.x+hbr.x)/2,(htl.y+hbr.y)/2)
		var hsize = Vector2(abs(htl.x-hbr.x)/2, abs(htl.y-hbr.y)/2)
		var xdist = abs(me.x - (them.x + (hcenter.x*ps[1].d)))
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
		var them = ps[1].get_position() + ps[1].SHIELDOFFSET
		var me = ps[0].get_position() + ps[0].hurtboxoffset
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
		ps[0].state = "hitstun"
		if ps[1].d == 1:
			ps[0].launch_direction = h.hitdirection[b]
		else:
			ps[0].launch_direction = 180-h.hitdirection[b]
		ps[0].frame = 1
		ps[0].stage = 0
		if !ps[0].is_projectile:
			ps[0].has_airdodge = true
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
	impact(ps, h, b)
	
	visualstun(ps, h, b)
	
func visualstun(ps, h, b):
	ps[0].stun_length = int(20+ps[0].damage/10)
	var hitlength = int(h.stun[b] + ps[0].damage/20)
	if hitlength > ps[0].impact_frame:
		ps[0].impact_frame = hitlength
	if hitlength > ps[1].impact_frame:
		ps[1].impact_frame = hitlength
	Globals.IMPACTFRAME = hitlength
	
func impact(ps, h, b):
	var effect = EFFECT.instance()
	effect.position = h.get_parent().get_position() + (h.topleft[b]/2 + h.bottomright[b]/2) * Vector2(h.get_parent().d, 0)
	effect.d = ps[0].d
	effect.myframe = 0
	effect.playernumber = ps[0].playernumber
	effect.effecttype = "impact"
	effect.scale = Vector2(1,1) + Vector2(h.damage[b], h.damage[b]) / 10.0
	if ps[0].combo < 2:
		effect.modulate = Color(1,1,1,1)
	else:
		effect.modulate = Color(1,0,1,1)
	get_tree().get_root().add_child(effect)
	
func combocounter(ps):
	if ["hitstun", "hit", "mildstun"].has(ps[0].state):
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
	playsound("REFLECT")

func spawnball():
	var ball = BALL.instance()
	ball.position = Vector2(0, -160)
	ball.d = 1
	ball.frame = 0
	ball.playernumber = 0
	get_tree().get_root().get_node("World").add_child(ball)
	Globals.projectiles.append(ball)
	ball.start()

func bottommenu():
	var SCREENX = Globals.SCREENX
	var SCREENY = Globals.SCREENY

	$CanvasLayer/BottomBar.margin_left = 0
	$CanvasLayer/BottomBar.margin_right = SCREENX + 128
	$CanvasLayer/BottomBar.margin_top = SCREENY - 128
	$CanvasLayer/BottomBar.margin_bottom = SCREENY + 128
	
	var margin = 20
	$CanvasLayer/Pause.margin_left = 0 + margin
	$CanvasLayer/Pause.margin_right = SCREENX + 128 - margin
	$CanvasLayer/Pause.margin_top = SCREENY - 128 + margin
	$CanvasLayer/Pause.margin_bottom = SCREENY + 128 - margin
	
	$CanvasLayer/Pause.visible = Globals.PAUSED
	$CanvasLayer/PauseEffect.visible = Globals.PAUSED
	if Globals.PAUSED:
		$CanvasLayer/PauseEffect.margin_left = 0
		$CanvasLayer/PauseEffect.margin_right = SCREENX + 128
		$CanvasLayer/PauseEffect.margin_top = 0
		$CanvasLayer/PauseEffect.margin_bottom = SCREENY + 128
	
	
	#3 2 1 GO!!
	$CanvasLayer/Message.margin_left = 0
	$CanvasLayer/Message.margin_right = SCREENX
	$CanvasLayer/Message.margin_top = 0
	$CanvasLayer/Message.margin_bottom = SCREENY - 128
	
	if !(Globals.GAMEMODE == "TRAINING") &&  Globals.FRAME < 60:
		$CanvasLayer/Message.visible = true
		if Globals.FRAME < -120:
			$CanvasLayer/Message.text = "3"
		elif Globals.FRAME < -60:
			$CanvasLayer/Message.text = "2"
		elif Globals.FRAME < 0:
			$CanvasLayer/Message.text = "1"
		else:
			$CanvasLayer/Message.text = "GO!"
	elif (Globals.GAMEMODE == "TIME" || Globals.GAMEMODE == "SOCCER") && Globals.FRAME > Globals.TIME*60-300:
		$CanvasLayer/Message.visible = true
		$CanvasLayer/Message.text = str((Globals.TIME*60-Globals.FRAME)/60+1)
		if Globals.GAMEENDFRAME > 0:
			$CanvasLayer/Message.visible = true
			$CanvasLayer/Message.text = "GAME!"
	elif Globals.GAMEENDFRAME > 0:
		$CanvasLayer/Message.set("custom_colors/font_color", Color(1,1,1,1))
		$CanvasLayer/Message.visible = true
		$CanvasLayer/Message.text = "GAME!"
	elif Globals.ELIMINATIONFRAME > 0:
		$CanvasLayer/Message.visible = true
		if Globals.ELIMINATEDPLAYER > 0:
			$CanvasLayer/Message.text = "PLAYER " + str(Globals.ELIMINATEDPLAYER) + "\nDEFEATED"
		else:
			$CanvasLayer/Message.text = "COMPUTER \nPLAYER \nDEFEATED"
		if Globals.ELIMINATIONFRAME%10 < 6:
			$CanvasLayer/Message.set("custom_colors/font_color", Color(1,1,1,1))
		else:
			$CanvasLayer/Message.set("custom_colors/font_color", Globals.CONTROLLERCOLORS[Globals.players[Globals.ELIMINATEDPLAYER-1].controller])
	elif Globals.TRIPLEKOFRAME > 0:
		$CanvasLayer/Message.visible = true
		$CanvasLayer/Message.text = "TRIPLE K.O."
		if Globals.TRIPLEKOFRAME%10 < 6:
			$CanvasLayer/Message.set("custom_colors/font_color", Color(1,1,1,1))
		else:
			$CanvasLayer/Message.set("custom_colors/font_color", Color(1,.5,1,1))
	elif Globals.DOUBLEKOFRAME > 0:
		$CanvasLayer/Message.visible = true
		$CanvasLayer/Message.text = "DOUBLE K.O."
		if Globals.DOUBLEKOFRAME%10 < 6:
			$CanvasLayer/Message.set("custom_colors/font_color", Color(1,1,1,1))
		else:
			$CanvasLayer/Message.set("custom_colors/font_color", Color(1,1,.5,1))
	elif Globals.KOFRAME > 0:
		if Globals.NUM_OF_PLAYERS == 2:
			$CanvasLayer/Message.set("custom_colors/font_color", Color(1,1,1,1))
			$CanvasLayer/Message.visible = true
			$CanvasLayer/Message.text = str(Globals.players[0].stock) + "-" + str(Globals.players[1].stock)
	elif Globals.LEFTSCOREFRAME > 0:
		$CanvasLayer/Message.set("custom_colors/font_color", Color(1,1,1,1))
		$CanvasLayer/Message.visible = true
		$CanvasLayer/Message.text = "LEFT SCORES!"
		$CanvasLayer/Message.text += "\n" + str(Globals.LEFTSCORE) + "-" + str(Globals.RIGHTSCORE)
	elif Globals.RIGHTSCOREFRAME > 0:
		$CanvasLayer/Message.set("custom_colors/font_color", Color(1,1,1,1))
		$CanvasLayer/Message.visible = true
		$CanvasLayer/Message.text = "RIGHT SCORES!"
		$CanvasLayer/Message.text += "\n" + str(Globals.LEFTSCORE) + "-" + str(Globals.RIGHTSCORE)
	else:
		$CanvasLayer/Message.visible = false

func background():
	
	
	$Background/Background.margin_left = 0
	$Background/Background.margin_top = 0
	$Background/Background.margin_right = max(Globals.SCREENX,Globals.SCREENY)/4
	$Background/Background.margin_bottom = max(Globals.SCREENX,Globals.SCREENY)/4
	
	var bottom = Globals.BOTTOMBLASTZONE
	var top = Globals.TOPBLASTZONE
	var side = Globals.SIDEBLASTZONE
	var side2 = Globals.DOUBLEBLASTZONE
	var side3 = Globals.TRIPLEBLASTZONE
	$LeftDoubleZone.margin_bottom = bottom
	$LeftDoubleZone.margin_top = top
	$LeftTripleZone.margin_bottom = bottom
	$LeftTripleZone.margin_top = top
	$RightDoubleZone.margin_bottom = bottom
	$RightDoubleZone.margin_top = top
	$RightTripleZone.margin_bottom = bottom
	$RightTripleZone.margin_top = top
	
	$LeftDoubleZone.margin_left = -side
	$LeftDoubleZone.margin_right = -side2
	$LeftTripleZone.margin_left = -side
	$LeftTripleZone.margin_right = -side3
	$RightDoubleZone.margin_left = side2
	$RightDoubleZone.margin_right = side
	$RightTripleZone.margin_left = side3
	$RightTripleZone.margin_right = side
	
	if Globals.GAMEMODE == "SOCCER":
		$LeftDoubleZone.color = Globals.LEFTSIDECOLOR
		$RightDoubleZone.color = Globals.RIGHTSIDECOLOR
		$LeftTripleZone.color = Globals.LEFTGOALCOLOR
		$RightTripleZone.color = Globals.RIGHTGOALCOLOR
		$LeftDoubleZone/Label.text = ""
		$RightDoubleZone/Label.text = ""
		$LeftTripleZone/Label.text = "+1"
		$RightTripleZone/Label.text = "+1"
		$CanvasLayer/Score.visible = true
		$CanvasLayer/Score.text = str(Globals.LEFTSCORE) + "-" + str(Globals.RIGHTSCORE)
	else:
		$LeftDoubleZone.color = Globals.DOUBLECOLOR
		$RightDoubleZone.color = Globals.DOUBLECOLOR
		$LeftTripleZone.color = Globals.TRIPLECOLOR
		$RightTripleZone.color = Globals.TRIPLECOLOR
		$LeftDoubleZone/Label.text = "-2"
		$RightDoubleZone/Label.text = "-2"
		$LeftTripleZone/Label.text = "-3"
		$RightTripleZone/Label.text = "-3"
		$CanvasLayer/Score.visible = false
		if Globals.NUM_OF_PLAYERS == 2:
			if Globals.GAMEMODE == "STOCK":
				$CanvasLayer/Score.text = str(Globals.players[0].stock) + "-" + str(Globals.players[1].stock)
				$CanvasLayer/Score.visible = true
				
				
				
func playsound(sound):
	if !Globals.MUTED:
		if sound == "HIT":
			sound = "HIT" + str(randi()%4)
		get_node("Sounds").get_node(sound).play()
