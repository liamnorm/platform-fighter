extends Node2D

onready var PLAYER = preload("res://characters/fox/Fox.tscn")
onready var EFFECT = preload("res://resources/ImpactEffect.tscn")
onready var DAMAGE = preload("res://ui/Damage.tscn")
onready var TAG    = preload("res://ui/Tag.tscn")

var iq = []

func _ready():
	Globals.PAUSED = false
	Globals.players = []
	Globals.projectiles = []
	for i in range(Globals.NUM_OF_PLAYERS):
		Globals.players.append(PLAYER.instance())
	
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
	Globals.players[i].character = "Fox"
	Globals.players[i].name = "Player" + str(i+1)
	Globals.players[i].skin = Globals.playerskins[i]
	if i == 0:
		Globals.players[i].controller = 1
	Globals.players[i].respawn(pos, true)
	

func _process(_delta):
	
	if Input.is_action_just_pressed("pause"):
		Globals.PAUSED = !Globals.PAUSED
		
	if Input.is_action_just_pressed("select"):
		Globals.SHOWHITBOXES = !Globals.SHOWHITBOXES
	
	if (Input.is_action_just_pressed("reset")):
		for i in range(Globals.NUM_OF_PLAYERS):
			resetplayer(i)
			
	if (Input.is_action_just_pressed("pause") &&
		Input.is_action_pressed("attack") &&
		Input.is_action_pressed("shield")):
		returntomenu()
	
	if Globals.IMPACTFRAME > 0:
		Globals.IMPACTFRAME -= 1
		
		
	bottommenu()
	
	
	var paused = Globals.PAUSED
	var framechange = Input.is_action_just_pressed("nextframe")
	if ((!paused) || framechange):
		Globals.FRAME += 1
		
		spaceoutplayers()
		
		interactions()
		
func returntomenu():
	var menu = get_tree().change_scene("res://scenes/supportscenes/Menu.tscn")
		
func spaceoutplayers():
	for i in range(Globals.NUM_OF_PLAYERS):
		for j in range(i+1,Globals.NUM_OF_PLAYERS):
			var ps = [Globals.players[i], Globals.players[j]]
			var pushymoves = ["idle", "run", "runend", "turnaround", "shield", "crouch", "land", "jumpstart", "knockeddown"]
			if (
			#running into idle player: both move.
				(pushymoves.has(ps[0].state) &&
				pushymoves.has(ps[1].state))): 
			
				var pos0 = ps[0].get_position()
				var pos1 = ps[1].get_position()
				if (pos0-pos1).length() < 100:
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
		for j in range(Globals.NUM_OF_PLAYERS):
			if j != i:
				var ps = [Globals.players[i], Globals.players[j]]
				for h in ps[1].hitboxes:
					for b in range(len(h.topleft)):
						checkforoverlap(ps,h,b)
	
		for p in Globals.projectiles:
			var ps = [Globals.players[i], p]
			for h in ps[1].hitboxes:
				for b in range(len(h.topleft)):
					checkforprojectiles(ps,h,b)
	
	for i in iq:
		match i[0]:
			"shield":
				shieldattack(i[1], i[2], i[3])
			"invincible":
				invincibleattack(i[1], i[2], i[3])
			"hit":
				behurt(i[1], i[2], i[3])
			


func checkforoverlap(ps,h,b):
	if (!(ps[0].intangibility_frame > 0) &&
	!(h.players_to_ignore.has(ps[0].playernumber)) && 
	(h.startframe[b] < Globals.FRAME) && 
	(h.startframe[b] + h.boxlengths[b]>= Globals.FRAME)):
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
				iq.append(["shield", ps, h, b])
			elif (ps[0].invincibility_frame > 0):
				iq.append(["invincible", ps, h, b])
			else:
				iq.append(["hit", ps, h, b])


func checkforprojectiles(ps, h, b):
	if (!(h.players_to_ignore.has(ps[0].playernumber)) && 
	(h.startframe[b] < Globals.FRAME) && 
	(h.startframe[b] + h.boxlengths[b]>= Globals.FRAME)):
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
				shieldattack(ps, h, b)
			elif (ps[0].invincibility_frame > 0):
				invincibleattack(ps, h, b)
			else:
				behurt(ps, h, b)


func shieldattack(ps,h,b):
	h.players_to_ignore.append(ps[0].playernumber)
	ps[0].state = "shieldstun"
	ps[0].frame = 0
	ps[0].stage = 0
	ps[0].shield_stun = h.shieldstun[b]
	ps[0].shield_size -= h.shieldstun[b] * 3
	ps[0].player_who_last_hit_me = ps[1].playernumber
	var hitlength = h.shieldstun[b]
	if hitlength > ps[0].impact_frame:
		ps[0].impact_frame = hitlength
	hitlength = h.stun[b]
	if hitlength > ps[1].impact_frame:
		ps[1].impact_frame = hitlength
	ps[1].connected = true
	
func invincibleattack(ps,h,b):
	ps[0].player_who_last_hit_me = ps[1].playernumber
	h.players_to_ignore.append(ps[0].playernumber)
	var hitlength = h.stun[b]
	if hitlength > ps[1].impact_frame:
		ps[1].impact_frame = hitlength
	ps[1].connected = true
	
func behurt(ps,h,b):
	h.players_to_ignore.append(ps[0].playernumber)
	ps[0].damage += h.damage[b]
	if h.hitstun[b]:
		if ps[0].playernumber == 2:
			combocounter(ps)
		ps[0].state = "hitstun"
		if ps[1].d == 1:
			ps[0].launch_direction = h.hitdirection[b]
		else:
			ps[0].launch_direction = 180-h.hitdirection[b]
		ps[0].frame = 1
		ps[0].stage = 0
		ps[0].has_airdodge = true
		ps[0].motion = Vector2(0,0)
		ps[0].player_who_last_hit_me = ps[1].playernumber
		ps[0].launch_knockback = ps[0].damage * 30 * h.knockback[b] + h.constknockback[b]
		if ps[0].launch_direction%360 < 90 || ps[0].launch_direction%360 > 270:
			ps[0].d = -1
		else:
			ps[0].d = 1
			
	Input.start_joy_vibration(0, 1, 1, 0.1)
	
	if ps[0].launch_knockback > ps[0].LAUNCH_THRESHOLD && b == 0:
		impact(ps, h, b)
	
	visualstun(ps, h, b)
	
func visualstun(ps, h, b):
	ps[0].stun_length = int(20+ps[0].damage/10)
	var hitlength = int(h.stun[b] + ps[0].damage/20)
	if hitlength > ps[0].impact_frame:
		ps[0].impact_frame = hitlength
	if hitlength > ps[1].impact_frame:
		ps[1].impact_frame = hitlength
	ps[1].connected = true
	Globals.IMPACTFRAME = hitlength
	
func impact(ps, h, b):
	var effect = EFFECT.instance()
	effect.position = h.get_parent().get_position() + (-h.topleft[b]/2 + h.bottomright[b]/2) * Vector2(h.get_parent().d, 0)
	effect.d = ps[0].d
	effect.myframe = 0
	effect.player = ps[0].playernumber
	effect.effecttype = "impact"
	get_tree().get_root().add_child(effect)
	
func combocounter(ps):
	if ["hitstun", "hit", "mildstun"].has(ps[0].state):
		Globals.COMBO+=1
	else:
		Globals.COMBO = 1


func bottommenu():
	var SCREENX = Globals.SCREENX
	var SCREENY = Globals.SCREENY
	$CanvasLayer/BottomBar.margin_left = 0
	$CanvasLayer/BottomBar.margin_right = SCREENX + 128
	$CanvasLayer/BottomBar.margin_top = SCREENY - 128
	$CanvasLayer/BottomBar.margin_bottom = SCREENY + 128
	
	$CanvasLayer/Pause.visible = Globals.PAUSED
	$CanvasLayer/PauseEffect.visible = Globals.PAUSED
	if Globals.PAUSED:
		$CanvasLayer/PauseEffect.margin_left = 0
		$CanvasLayer/PauseEffect.margin_right = SCREENX + 128
		$CanvasLayer/PauseEffect.margin_top = 0
		$CanvasLayer/PauseEffect.margin_bottom = SCREENY + 128
