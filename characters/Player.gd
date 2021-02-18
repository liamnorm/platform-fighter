extends KinematicBody2D

onready var HITBOX = preload("res://characters/Hitbox.tscn")
var hitboxes = []

var playernumber = 0
var character = "Fox"
var skin = 0
var controller = 0

var Mat

const UP = Vector2(0, -1)

const SHIELDTIME = 500.0

const LEDGETIME = 300


var GRAVITY = 70
var MAXFALLSPEED = 1200
var JUMPFORCE = 1500
var DOUBLEJUMPFORCE = 1500
var SHORTJUMPFORCE = 1100

var MAXGROUNDSPEED = 1200
var ACCEL = 256
var FRICTION = 0.5

var MAXAIRSPEED = 700
var AIRACCEL = 256
var AIRFRICTION = 0.5
var FASTFALLSPEED = 1400
var ROLLSPEED = 250
var ROLLFRAMES = 20
var SPOTDODGEFRAMES = 17
var AIRDODGEFRAMES = 18


var state = "idle"
var nextstate = "idle"
var bufferedstate = "none"
var buffereddirection = "none"
var buffering = false
var frame = 0
var stage = 0
var on_floor = false
var current_ledge = null
var frames_since_ledge = 0
var hurtboxsize = Vector2(64,64)
var hurtboxoffset = Vector2(0,0)

var motion = Vector2()

var x
var y
var d = 1
var has_double_jump = true
var in_fast_fall = false
var has_airdodge = true
var shield_size = SHIELDTIME
var damage = 0
var invincibility_frame = 0
var intangibility_frame = 0
var first_time_at_ledge = true
var drop_frame = 0
var landing_lag = 0
var neutral_airdodge = false

var impact_frame = 0
var launch_direction = 0
var launch_knockback = 1
var stun_length = 0
var connected = false

var stock = 3
var spawnposition = Vector2(0,-512)

var input =      [false,false,false,false,false,false,false,false,false,false,false,false]
var new_input =  [false,false,false,false,false,false,false,false,false,false,false,false]
var prev_input = [false,false,false,false,false,false,false,false,false,false,false,false]
var input_lengths = [0,0,0,0,0,0,0,0,0,0,0,0]

var ref = 0

func _ready():
	pass
	
func _physics_process(_delta):
	
	x = get_position().x
	y = get_position().y
		
	get_input()
	
	if (Input.is_action_just_pressed("reset")):
			respawn(spawnposition, true)
	
	var paused = Globals.PAUSED
	var framechange = Input.is_action_just_pressed("nextframe")
	if ((!paused) || framechange) && impact_frame == 0:
		
		
		if (y > Globals.BOTTOMBLASTZONE || 
			(y < Globals.TOPBLASTZONE && state == "hit") || 
			abs(x) > Globals.SIDEBLASTZONE):
			respawn(Vector2(0,-512))
		
		if !state == "ledge":
			motion.y += GRAVITY
		
		statebasedaction()
		
		interact()
		
		motion = move_and_slide(motion, UP)
		
		
		respectedge()
		
		
		#FRAME STUFF
		frame += 1
		frames_since_ledge += 1
		invincibility_frame -= 1
		invincibility_frame = max(invincibility_frame, 0)
		intangibility_frame -= 1
		intangibility_frame = max(intangibility_frame, 0)
		
		shield_size += 1
		shield_size = clamp(shield_size, 0, SHIELDTIME)
	
	impact_frame -= 1
	if impact_frame < 1:
		impact_frame = 0
	else:
		directionalinput()
		
	#DRAW
	updateDirection()
	playerEffects()
	drawPlayer()
	drawhurtbox()


func statebasedaction():
	match state:
		"idle":
			movement()
			if input[0] || input[1]:
				be("run")
			elif input[3]:
				be("crouch")
			groundoptions()
				
		"run":
			movement()
			if frame == 1:
				if d == 1:
					if input[1]:
						d = -1
						frame = 0
						motion.x = -MAXGROUNDSPEED
				else:
					if input[0]:
						d = 1
						frame = 0
						motion.x = MAXGROUNDSPEED
			elif (input[0] && d == 1) || (input[1] && d == -1):
				if frame < 4:
					if motion.x * d < 0:
						frame = 0
					motion.x = d * MAXGROUNDSPEED
				else:
					motion.x += d * ACCEL
				if input[0]:
					d = 1
				else:
					d = -1
			else:
				if !(input[0] || input[1]):
					be("runend")
				else:
					be("turnaround")
			groundoptions()
		
		"runend":
			movement()
			buffer(true)
			if input[0]:
				if d == 1:
					be("run")
				else:
					be("turnaround")
			elif input[1]:
				if d == -1:
					be("run")
				else:
					be("turnaround")
			if frame > 10:
				be("idle")
		
		"turnaround":
			motion.x = lerp(motion.x, 0, .1)
			if frame > 12:
				be("run")
		
		"jumpstart":
			movement()
			has_double_jump = true
			in_fast_fall = false
			if frame > 4:
				if input[2]:
					motion.y = -JUMPFORCE
				else:
					motion.y = -SHORTJUMPFORCE
				be("jump")

		"jump":
			movement()
			if updatefloorstate():
				be("land")
			airoptions()
			
		"land":
			if landing_lag < 5:
				landing_lag = 5
			movement()
			if frame > landing_lag - 5:
				buffer(true)
			if frame > landing_lag:
				landing_lag = 5
				if input[3]:
					be("crouch")
				else:
					be("idle")
		"crouch":
			if frame == 6:
				position += Vector2(0, 10)
			movement()
			if !input[3]:
				be("idle")
			groundoptions()
			
		"neutralspecial":
			neutralspecial()
		"sidespecial":
			sidespecial()
		"upspecial":
			upspecial()
		"downspecial":
			downspecial()
		
		"neutralground":
			neutralground()
		"sideground":
			sideground()
		"downground":
			downground()
		
		"neutralair":
			neutralair()
		"forwardair":
			forwardair()
		"backair":
			backair()
		"upair":
			upair()
		"downair":
			downair()
		
		"ledge":
			if first_time_at_ledge:
				invincibility_frame = 60
			in_fast_fall = false
			has_double_jump = true
			has_airdodge = true
			frames_since_ledge = 0
			first_time_at_ledge = false
			d = current_ledge[1]
			motion = Vector2(0,0)
			var ledge_x = current_ledge[0].x + current_ledge[1] * -64
			var ledge_y = current_ledge[0].y + 64
			set_position(Vector2(ledge_x, ledge_y))
			
			if frame > 15:
				if input[0]:
					if current_ledge[1] == 1:
						ledge_x = current_ledge[0].x + current_ledge[1] * 64
						ledge_y = current_ledge[0].y - 64
						set_position(Vector2(ledge_x, ledge_y))
						be("ledgegetup")
					else:
						be("jump")
				elif input[1]:
					if current_ledge[1] == -1:
						ledge_x = current_ledge[0].x + current_ledge[1] * 64
						ledge_y = current_ledge[0].y - 64
						set_position(Vector2(ledge_x, ledge_y))
						be("ledgegetup")
					else:
						be("jump")
				elif input[2]:
					motion.y = -JUMPFORCE
					be("jump")
				elif new_input[3]:
					in_fast_fall = true
					be("jump")
				if frame > LEDGETIME:
					be("jump")
		
		"ledgegetup":
			if frame > 15:
				be("idle")

		"shield":
			movement()
			shield_size -= 2
			if frame > 8 || frame < 2:
				if input[0]:
					d = 1
					be("roll")
				elif input[1]:
					d = -1
					be("roll")
				elif input[3]:
					be("spotdodge")
				elif !input[6]:
					be("outofshield")
		"outofshield":
			movement()
			buffer(true)
			if frame > 5:
				be("idle")
		"airdodge":
			if frame == 1:
				neutral_airdodge = false
				if input[2]:
					motion = Vector2(0,-800)
					if input[0]:
						motion = Vector2(1000,-600)
					if input[1]:
						motion = Vector2(-1000,-600)
				elif input[3]:
					motion = Vector2(0, 1400)
					if input[0]:
						motion = Vector2(1000,1400)
					if input[1]:
						motion = Vector2(-1000,1400)
				elif input[0]:
					motion = Vector2(1100,-200)
				elif input[1]:
					motion = Vector2(-1100,-200)
				else:
					neutral_airdodge = true
					intangibility_frame += 10 
					
			if !neutral_airdodge:
				motion.x = lerp(motion.x, 0, .05)
				if frame > 20:
					motion.x = clamp(motion.x, -MAXAIRSPEED, MAXAIRSPEED)
					if motion.y > MAXFALLSPEED:
						motion.y = MAXFALLSPEED
					ledgesnap()
				else:
					motion.y -= GRAVITY/3
			else:
				movement()
			if frame > 50:
				be("jump")
			if updatefloorstate():
				be("land")
					
		"roll":
			var speedmodifier = pow(ROLLFRAMES - abs(frame-(ROLLFRAMES/4)),2)/50
			motion.x = ROLLSPEED * -d * speedmodifier
			if frame > ROLLFRAMES:
				motion.x = 0
				buffer(true)
				if frame > ROLLFRAMES+8:
					be("idle")
		"spotdodge":
			motion.x = 0
			if frame > SPOTDODGEFRAMES:
				buffer(true)
				if frame > SPOTDODGEFRAMES+8:
					be("idle")
			movement()
		"hitstun":
			motion = Vector2(0,0)
			directionalinput()
			if frame > 0:
				motion = Vector2(cos(launch_direction * PI/180), sin(launch_direction * PI/180)) 
				motion *= launch_knockback
				if motion.length() <  400:
					be("jump")
				else:
					be("hit")
		"hit":
			match stage:
				0:
					launchdirectionalinput()
					if updatefloorstate():
						motion = Vector2(cos(launch_direction * PI/180), sin(launch_direction * PI/180)) 
						motion *= launch_knockback
						motion.y = -abs(motion.y)
					motion.y -= GRAVITY
					motion.y = lerp(motion.y, MAXFALLSPEED, .05)
					motion.x = lerp(motion.x, 0, 0.05)
					if input[0]:
						motion.x += AIRACCEL/4
					if input[1]:
						motion.x -= AIRACCEL/4
					if frame > stun_length && (abs(motion.y) < MAXFALLSPEED && abs(motion.x) < MAXAIRSPEED):
						stage = 1
						frame = 0
				1:
					if motion.y > MAXFALLSPEED:
						motion.y = MAXFALLSPEED
					motion.x = clamp(motion.x, -MAXAIRSPEED, MAXAIRSPEED)
					if input[0]:
						motion.x += AIRACCEL
					if input[1]:
						motion.x -= AIRACCEL
					if new_input[2]:
						be("jump")
						doublejump()
					if new_input[3]:
						in_fast_fall = true
					ledgesnap()
					if updatefloorstate():
						be("knockeddown")
		"knockeddown":
			movement()
			match stage:
				0:
					if frame > 18:
						stage = 1
						frame = 0
				1:
					if input[0] || input[1]:
						be("roll")
					if frame > 300 || input[2] || input[6]:
						be("getup")
					if input[4] || input[5]:
						be("getupattack")
		"getup":
			if frame > 10 || input[2]:
				be("idle")
		"getupattack":
			if frame > 30 || input[2]:
				be("idle")
	
	
	#TEMPORARY FAILSAFE
	if frame > 60 && !input.has(true) && !["ledge", "jump", "hitstun", "hit", "knockeddown"].has(state):
		nextstate = "idle"
		
	state = nextstate



func be(get):
	if buffering:
		bufferedstate = get
	else:
		if !(bufferedstate == "none"):
			if bufferedstate == "doublejump":
				doublejump()
				nextstate = "jump"
			else:
				nextstate = bufferedstate
			if buffereddirection == "right":
				if !bufferedstate == "roll":
					d = 1
				else:
					d = -1
			if buffereddirection == "left":
				if !bufferedstate == "roll":
					d = -1
				else:
					d = 1
		else:
			nextstate = get
		frame = 0
		stage = 0
		
		if nextstate == "roll":
			intangibility_frame = ROLLFRAMES
		if nextstate == "spotdodge":
			intangibility_frame = SPOTDODGEFRAMES
		if nextstate == "airdodge":
			intangibility_frame = AIRDODGEFRAMES
		
		if !(["jump", "airdodge", "hit", "forwardair", "backair", "upair", "downair", "neutralair"].has(nextstate)):
			if input[0]:
				if !nextstate == "roll":
					d = 1
				else:
					d = -1
			elif input[1]:
				if !nextstate == "roll":
					d = -1
				else:
					d = 1
		bufferedstate = "none"
		buffereddirection = "none"





func buffer(on_ground):
	buffering = true
	if on_ground:
		groundoptions()
	else:
		airoptions()
	buffereddirection = "none"
	if !(bufferedstate == "airdodge" || bufferedstate == "jump"):
		if input[0]:
			buffereddirection = "right"
		elif input[1]:
			buffereddirection = "left"
	buffering = false
			
	
func groundoptions():
	if input[4]:
		if input[2]:
			be("upspecial")
		elif input[3]:
			be("downspecial")
		elif input[0] || input[1]:
			be("sidespecial")
		else:
			be("neutralspecial")
	elif input[5]:
		if input[3]:
			be("downground")
		elif input[0] || input[1]:
			be("sideground")
		else:
			be("neutralground")
	elif input[6]:
		if input[0] || input[1]:
			be("roll")
		else:
			be("shield")
	elif new_input[2]:
		be("jumpstart")
	elif buffering:
		if input[3]:
			be("crouch")
		
func airoptions():
	if input[4]:
		if input[2]:
			be("upspecial")
		elif input[3]:
			be("downspecial")
		elif input[0] || input[1]:
			be("sidespecial")
		else:
			be("neutralspecial")
	elif input[5]:
		if input[2]:
			be("upair")
		elif input[3]:
			be("downair")
		elif input[0]:
			if d == 1:
				be("forwardair")
			else:
				be("backair")
		elif input[1]:
			if d == -1:
				be("forwardair")
			else:
				be("backair")
		else:
			be("neutralair")
	elif input[6]:
		be("airdodge")
	elif input[10]:
		be("upair")
	elif input[11]:
		be("downair")
	elif input[8]:
		if d == 1:
			be("forwardair")
		else:
			be("backair")
	elif input[9]:
		if d == -1:
			be("forwardair")
		else:
			be("backair")
	elif new_input[2]:
		if has_double_jump:
			if buffering:
				bufferedstate = "doublejump"
			else:
				doublejump()

func updatefloorstate():
	if is_on_floor() && on_floor == false:
		on_floor = true
		has_double_jump = true
		has_airdodge = true
		first_time_at_ledge = true
		if ["jump", "neutralair", "forwardair", "backair", "upair", "downair", "airdodge"].has(state):
			be("land")
	if !is_on_floor() && on_floor == true:
		on_floor = false
		if ["run", "idle", "crouch", "land"].has(state):
			be("jump")
	return on_floor

func movement():
	if updatefloorstate():
		fallcap(true)
	else:
		if input[0]:
			motion.x += AIRACCEL
		elif input[1]:
			motion.x -= AIRACCEL
		
		if new_input[3]:
			in_fast_fall = true
			
		if in_fast_fall:
			set_collision_layer_bit(1, 0)
		else:
			set_collision_layer_bit(1, 1)

		ledgesnap()
		fallcap(false)
		
func ledgesnap():
	if frames_since_ledge > 30:
		var myx = get_position().x
		for ledge in Globals.LEDGES:
			if abs(myx+64*ledge[1]-ledge[0].x) < 64:
				var myy = get_position().y
				if abs(myy-64-ledge[0].y) < 64:
					current_ledge = ledge	
					be("ledge")
		
func fallcap(on_ground):
	updatefloorstate()
	if on_ground:
		if !(state == "run" || state == "jumpstart"):
			motion.x = lerp(motion.x,0,FRICTION)
		motion.x = clamp(motion.x,-MAXGROUNDSPEED,MAXGROUNDSPEED)
	else:
		motion.x = lerp(motion.x,0,AIRFRICTION)
			
		motion.x = clamp(motion.x,-MAXAIRSPEED,MAXAIRSPEED)
	
		if in_fast_fall:
			motion.y += GRAVITY*4
			if motion.y > FASTFALLSPEED:
				motion.y = FASTFALLSPEED
		else:
			if motion.y > MAXFALLSPEED:
				motion.y = MAXFALLSPEED

func doublejump():
	if input[0]:
		motion.x = MAXAIRSPEED
	elif input[1]:
		motion.x = -MAXAIRSPEED
	else:
		motion.x = 0
	has_double_jump = false
	in_fast_fall = false
	motion.y = -DOUBLEJUMPFORCE
	
func directionalinput():
	var di = Vector2(0,0)
	if input[0]:
		di += Vector2(1,0)
	if input[1]:
		di += Vector2(-1,0)
	if input[2]:
		di += Vector2(0,-1)
	if input[3]:
		di += Vector2(0,1)
	move_and_slide(di*50, UP)
	
func launchdirectionalinput():
	var di = Vector2(0,0)
	if input[0]:
		di += Vector2(1,0)
	if input[1]:
		di += Vector2(-1,0)
	if input[2]:
		di += Vector2(0,-1)
	if input[3]:
		di += Vector2(0,1)
	motion += di*25
			
func respawn(place, first_time_respawning=false):
	if first_time_respawning:
		spawnposition = place
		on_floor = true
	else:
		spawnposition = Vector2(0,-512)
		on_floor = false
	motion = Vector2(0,0)
	self.position = spawnposition
	in_fast_fall = false
	has_double_jump = true
	has_airdodge = true
	if self.position.x < 0:
		d = 1
	else:
		d = -1
	bufferedstate = "none"
	buffereddirection = "none"
	buffering = false
	if !first_time_respawning:
		invincibility_frame = 180
	else:
		invincibility_frame = 0
	intangibility_frame = 0
	first_time_at_ledge = true
	drop_frame = 0
	damage = 0
	
	impact_frame = 0
	launch_direction = 0
	stun_length = 0
	
	stock -= 1
	
	be("jump")
	
	Mat = $Sprite.get_material()
	Mat.set_shader_param("skin", skin)

func drawhurtbox():
	$Hurtbox.margin_left = -hurtboxsize.x + hurtboxoffset.x
	$Hurtbox.margin_right = hurtboxsize.x + hurtboxoffset.x
	$Hurtbox.margin_top = -hurtboxsize.y + hurtboxoffset.y
	$Hurtbox.margin_bottom = hurtboxsize.y + hurtboxoffset.y


func get_input():
	prev_input = input
	if controller == 0:
		#for i in range(6):
			#input_lengths[i]+= 1
			#if i==1:
			#	input[1] = !input[0]
			#if (input_lengths[i] > randi()%50 + 30):
				#input[i] = !input[i]
				#input_lengths[i] = 0
		
		input = [
			false,
			false,
			false,
			false,
			false,
			false,
			false,
			false,
			false,
			false,
			false,
			false,
		]
		var enemyx = Globals.players[0].get_position().x
		var enemyy = Globals.players[0].get_position().y
		
		input[0] = x < Globals.LEDGES[0][0].x
		input[1] = x > Globals.LEDGES[1][0].x
		input[2] = abs(get_position().x) > Globals.LEDGES[1][0].x && frame % 8 == 0
		input[4] = abs(get_position().x) > Globals.LEDGES[1][0].x && frame % 8 == 0
		
		input[0] = input[0] || x < enemyx
		input[1] = input[1]|| x > enemyx

#		input[4] = randi()%31 == 0
#		input[5] = randi()%31 == 0

#		input[5] = frame % 120 != 0
		input[5] = randi()%40 == 0
		input[2] = randi()%39 == 0

	else:
		input = [
			Input.is_action_pressed("right"),
			Input.is_action_pressed("left"),
			Input.is_action_pressed("jump"),
			Input.is_action_pressed("down"),
			Input.is_action_pressed("special"),
			Input.is_action_pressed("attack"),
			Input.is_action_pressed("shield"),
			false,
			Input.is_action_pressed("rightattack"),
			Input.is_action_pressed("leftattack"),
			Input.is_action_pressed("upattack"),
			Input.is_action_pressed("downattack"),
		]
		
	for i in range(len(input)):
		new_input[i] = input[i] && !prev_input[i]
		
func interact():
	
	#SPACE OUT TWO IDLE CHARACTERS
	if intangibility_frame == 0:
		var i = 1
		for player in Globals.players:
			if !(i == playernumber):
				if ["idle", "run"].has(nextstate):
					if ["idle", "run"].has(player.state):
						var otherpos = player.get_position()
						var mypos = get_position()
						if abs(mypos.x - otherpos.x) < 80 && abs(mypos.y - otherpos.y) < 16:
							if nextstate == "idle":
								if mypos.x > otherpos.x:
									motion.x += ACCEL/2
								else:
									motion.x -= ACCEL/2
							elif nextstate == "run":
								if mypos.x > otherpos.x:
									motion.x += ACCEL
								else:
									motion.x -= ACCEL
								motion.x = (motion.x + player.motion.x)/2.0
					
					
					
				for h in player.hitboxes:
					if !(h.players_to_ignore.has(playernumber)) && !(h.startframe == Globals.FRAME):
						var them = player.get_position()
						var me = get_position() + hurtboxoffset
						var htl = h.topleft
						var hbr = h.bottomright
						var hcenter = Vector2((htl.x+hbr.x)/2,(htl.y+hbr.y)/2)
						var hsize = Vector2(abs(htl.x-hbr.x)/2, abs(htl.y-hbr.y)/2)
						var xdist = abs(me.x - (them.x + (hcenter.x*player.d)))
						var ydist = abs(me.y - (them.y + hcenter.y))
						if  xdist < (hurtboxsize.x + hsize.x) && ydist < (hurtboxsize.y + hsize.y):
							if state == "shield" && frame > 1:
								shieldattack(player, h)
							else:
								behurt(player, h)
			i += 1
	
		for projectile in Globals.projectiles:
			for h in projectile.hitboxes:
				if !(h.players_to_ignore.has(playernumber)):
					var them = projectile.get_position()
					var me = get_position() + hurtboxoffset
					var htl = h.topleft
					var hbr = h.bottomright
					var hcenter = Vector2((htl.x+hbr.x)/2,(htl.y+hbr.y)/2)
					var hsize = Vector2(abs(htl.x-hbr.x)/2, abs(htl.y-hbr.y)/2)
					var xdist = abs(me.x - (them.x + (hcenter.x*projectile.d)))
					var ydist = abs(me.y - (them.y + hcenter.y))
					if  xdist < (hurtboxsize.x + hsize.x) && ydist < (hurtboxsize.y + hsize.y):
						if state == "shield" && frame > 1:
							shieldattack(projectile, h)
						else:
							behurt(projectile, h)
func behurt(player, h):
	h.players_to_ignore.append(playernumber)
	damage += h.damage
	if h.hitstun:
		state = "hitstun"
		if player.d == 1:
			launch_direction = h.hitdirection
		else:
			launch_direction = 180-h.hitdirection
		frame = 0
		stage = 0
		has_airdodge = true
		motion = Vector2(0,0)
		launch_knockback = damage * 30 * h.knockback + h.constknockback
		if launch_direction%360 < 90 || launch_direction%360 > 270:
			d = -1
		else:
			d = 1
		
	visualstun(player, h)
	
func shieldattack(player, h):
	h.players_to_ignore.append(playernumber)
	state = "shieldstun"
	shield_size -= h.damage * 10
	
	visualstun(player, h)
	
func visualstun(player, h):
	stun_length = int(20+damage/10)
	var hitlength = int(h.stun + damage/20)
	if hitlength > impact_frame:
		impact_frame = hitlength
	if hitlength > player.impact_frame:
		player.impact_frame = hitlength
	player.connected = true
	Globals.IMPACTFRAME = hitlength

func respectedge():
	if ["idle", "roll", "spotdodge", "shield", "land", "neutralground", "sideground", "upground", "downground", "neutralspecial", "sidespecial", "downspecial", "knockeddown", "runend", "turnaround"].has(state):
		for ledge in Globals.LEDGES:
			respectparticularedge(ledge)
		for ledge in Globals.PLATFORMLEDGES:
			respectparticularedge(ledge)
		
func respectparticularedge(ledge):
	if ((ledge[1] * (x - ledge[0].x) < 16) && 
		(-ledge[1] * (x - ledge[0].x) < 16) &&
		(-ledge[1] * motion.x >= 0) &&
		abs(y + 64 - ledge[0].y) < 2):
			
		if ledge[1] * (x - ledge[0].x) > 0:
			motion = Vector2(0,0)
			set_position(Vector2((ledge[0].x+ledge[1]*0 + x)/2, ledge[0].y-64))
			on_floor = true
		else:
			motion = Vector2(0,0)
			set_position(Vector2((ledge[0].x-ledge[1]*0 + x)/2, ledge[0].y-64))
			on_floor = false


func hitbox(life, topleft, bottomright, hdamage, hitdirection, knockback, constknockback, stun, hitstun=true):
	var hbox = HITBOX.instance()
	hbox.life = life
	hbox.topleft = topleft
	hbox.bottomright = bottomright
	hbox.damage = hdamage
	hbox.hitdirection = hitdirection
	hbox.knockback = knockback
	hbox.constknockback = constknockback
	hbox.stun = stun
	hbox.players_to_ignore = []
	hbox.visible = Globals.SHOWHITBOXES
	hbox.hitstun = hitstun
	hbox.startframe = Globals.FRAME
	hitboxes.append(hbox)
	add_child(hbox)


func beFrame(aframe):
	$AnimationPlayer.stop()
	$Sprite.frame = aframe

func updateDirection():
	$Sprite.scale.x = d

func playerEffects():
	skin = skin % 8
	$Shield.visible = state == "shield" && frame > 1
	$Shield.scale.x = shield_size/SHIELDTIME
	$Shield.scale.y = shield_size/SHIELDTIME
	
	$Hurtbox.visible = Globals.SHOWHITBOXES
	
	Mat.set_shader_param("invincibility", invincibility_frame)
	Mat.set_shader_param("intangibility", intangibility_frame)
	Mat.set_shader_param("skin", skin)
# ALL CHARACTER-SPECIFIC STUFF SHOULD GO HERE!!!!!

func drawPlayer():
	pass
		
func neutralspecial():
	movement()

func sidespecial():
	movement()
	
func upspecial():
	movement()

func downspecial():
	movement()

func neutralground():
	movement()

func sideground():
	movement()

func downground():
	movement()
	
func neutralair():
	movement()
	
func forwardair():
	movement()
	
func backair():
	movement()

func upair():
	movement()

func downair():
	movement()
