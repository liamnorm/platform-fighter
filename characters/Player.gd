extends KinematicBody2D

#stuff to load
onready var HITBOX = preload("res://characters/Hitbox.tscn")
onready var EFFECT = preload("res://resources/ImpactEffect.tscn")

#identifying features
var playernumber = 0
var character = "SPACEDOG"
var skin = 0
var controller = 0

#shader materials
var Mat
var ShieldMat
var controllercolor

#constants
const UP = Vector2(0, -1)
const SHIELDTIME = 300.0
const LAUNCH_THRESHOLD = 400
const LEDGETIME = 300
const RESPAWN_INVINCIBILITY_FRAMES = 180
const RESPAWN_ANIMATION_FRAMES = 60
const RESPAWN_IDLE_FRAMES = 180
const LEDGE_INTANGIBILITY_FRAMES = 45
const is_projectile = false
const TRUEMAXSPEED = 10000

#character-dependent stuff that should basically act as constants
#jumping
var GRAVITY = 70
var MAXFALLSPEED = 1200
var JUMPFORCE = 1500
var DOUBLEJUMPFORCE = 1500
var SHORTJUMPFORCE = 1100

#running
var MAXGROUNDSPEED = 1200
var ACCEL = 256
var FRICTION = 0.5

#other movement stuff
var MAXAIRSPEED = 700
var AIRACCEL = 256
var AIRFRICTION = 0.5
var FASTFALLSPEED = 1400
var ROLLSPEED = 250
var ROLLFRAMES = 20
var SPOTDODGEFRAMES = 17
var AIRDODGEFRAMES = 18
var WAVEDASHLENGTH = 14
var DOUBLEJUMPFRAMES = 30
var SHIELDOFFSET = Vector2(0,0)

#stuff that changes in game
#state and buffered state
var state = "idle"
var nextstate = "idle"
var bufferedstate = "none"
var buffereddirection = "none"
var buffering = false
var frame = 0
var stage = 0
var on_floor = false

#ledge
var current_ledge = null
var frames_since_ledge = 0
var first_time_at_ledge = true
var drop_frame = 0

#hitboxes and hurtbox
var hitboxes = []
var hurtboxsize = Vector2(64,64)
var hurtboxoffset = Vector2(0,0)

#motion
var motion = Vector2()
var x
var y
var d = 1

#misc movement stuff
var double_jump_frame = 0
var has_double_jump = true
var jump_direction
var in_fast_fall = false
var has_airdodge = true
var shield_size = SHIELDTIME
var prev_shield_size = shield_size
var damage = 0
var invincibility_frame = 0
var intangibility_frame = 0
var landing_lag = 0
var neutral_airdodge = false
var wavedash_frame = 0
var respawn_order = -1

#stale moves
var roll_stale = 0

#interactions
var impact_frame = 0
var launch_direction = 0
var launch_knockback = 1
var stun_length = 0
var connected = false
var shield_stun = 0
var player_who_last_hit_me = 0
var shield_physical_size = 0
var hitter_motion = Vector2(0,0)

#scorekeeping
var stock = 3
var spawnposition = Vector2(0,-512)
var defeated = false
var combo = 0
var score = 0


#for inputs
var input =      [false,false,false,false,false,false,false,false,false,false,false,false]
var new_input =  [false,false,false,false,false,false,false,false,false,false,false,false]
var prev_input = [false,false,false,false,false,false,false,false,false,false,false,false]
var input_lengths = [0,0,0,0,0,0,0,0,0,0,0,0]

#for animation.
var ref = 0

func _ready():
	pass
	
func _physics_process(_delta):
	
	var paused = Globals.PAUSED
	var framechange = Input.is_action_just_pressed("nextframe")
	var intro = Globals.FRAME < 0
	var slowmo = Globals.SLOMOFRAME % 2 != 0
	if ((!paused) || framechange) && !defeated && !intro && !slowmo:
		
		x = get_position().x
		y = get_position().y
		get_input()

		if impact_frame == 0:
		
		
			if (y > Globals.BOTTOMBLASTZONE || 
				(y < Globals.TOPBLASTZONE && state == "hit") || 
				abs(x) > Globals.SIDEBLASTZONE):
				if Globals.GAMEMODE == "STOCK":
					if abs(x) > Globals.TRIPLEBLASTZONE:
						stock -= 3
						Globals.TRIPLEKOFRAME = 120
					elif abs(x) > Globals.DOUBLEBLASTZONE:
						stock -= 2
						Globals.DOUBLEKOFRAME = 120
					else:
						Globals.KOFRAME = 120
						stock -= 1
					if stock < 0:
						stock = 0
					if stock > 0:
						respawn(Vector2(0,Globals.TOPBLASTZONE))
					else:
						defeated = true
						var players_left = 0
						var winner = 0
						for p in Globals.players:
							if !p.defeated:
								players_left += 1
								winner = p.playernumber
						if players_left < 2:
							Globals.GAMEENDFRAME = 1
							Globals.WINNER = winner
						Globals.WINNERCHARACTER = Globals.players[winner-1].character
						Globals.WINNERCONTROLLER = Globals.players[winner-1].controller
				elif Globals.GAMEMODE == "TIME":
					if abs(x) > Globals.TRIPLEBLASTZONE:
						score -= 3
						Globals.players[player_who_last_hit_me-1].score += 3
						Globals.TRIPLEKOFRAME = 120
					elif abs(x) > Globals.DOUBLEBLASTZONE:
						score -= 2
						Globals.players[player_who_last_hit_me-1].score += 3
						Globals.DOUBLEKOFRAME = 120
					else:
						score -= 1
						Globals.players[player_who_last_hit_me-1].score += 3
						Globals.KOFRAME = 120
					respawn(Vector2(0,Globals.TOPBLASTZONE))
				else:
					respawn(Vector2(0,Globals.TOPBLASTZONE))
			
			if !state == "ledge":
				motion.y += GRAVITY
			
			statebasedaction()
			
			motion.x = clamp(motion.x, -TRUEMAXSPEED, TRUEMAXSPEED)
			motion.y = clamp(motion.y, -TRUEMAXSPEED, TRUEMAXSPEED)
			
			if (state == "hit" && stage == 0):
				var collision = move_and_collide(motion*0.0166)
				if collision:
					if motion.length() > 500:
						motion = motion.bounce(collision.normal)
						motion = motion*0.7
			else:
				motion = move_and_slide(motion, UP)
			
			respectedge()
			
			
			#FRAME STUFF
			frame += 1
			frames_since_ledge += 1
			invincibility_frame -= 1
			invincibility_frame = max(invincibility_frame, 0)
			intangibility_frame -= 1
			intangibility_frame = max(intangibility_frame, 0)
			wavedash_frame -= 1
			wavedash_frame = clamp(wavedash_frame, 0, WAVEDASHLENGTH)
			
			roll_stale -= 1
			roll_stale = clamp(roll_stale, 0, 2000)
			
			if Globals.FRAME%3 == 1:
				shield_size += 1
			shield_size = clamp(shield_size, 0, SHIELDTIME)
			shield_physical_size = sqrt(shield_size)*5-10
	
	impact_frame -= 1
	if impact_frame < 1:
		impact_frame = 0
	else:
		if state == "hitstun":
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
			if frame > 7:
				be("run")
		
		"jumpstart":
			movement()
			buffer(false)
			has_double_jump = true
			in_fast_fall = false
			if input[0]:
				jump_direction = 1
			elif input[1]:
				jump_direction = -1
			if frame > 4:
				if input[2]:
					motion.y = -JUMPFORCE
					if !(jump_direction == 0):
						motion.x = jump_direction * MAXAIRSPEED
				else:
					motion.y = -SHORTJUMPFORCE
					if !(jump_direction == 0):
						motion.x = jump_direction * 0.5 * MAXAIRSPEED
				be("jump")

		"jump":
			if double_jump_frame > 0:
				double_jump_frame -= 1
			else:
				double_jump_frame = 0
			movement()
			ledgesnap()
			airoptions()
			if updatefloorstate():
				be("land")
			
		"land":
			intangibility_frame = 0
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
			match stage:
				0:
					if frame == 1:
						position += Vector2(0, 10)
					if frame > 5:
						stage = 1
						frame = 0
				1:
					if frame > 6:
						if !input[3]:
							stage = 2
							frame = 0
				2:
					if frame > 5:
						be("idle")
			movement()
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
		"upground":
			upground()
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
				intangibility_frame = LEDGE_INTANGIBILITY_FRAMES
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
					in_fast_fall = false
					be("jump")
				if frame > LEDGETIME:
					be("jump")
		
		"ledgegetup":
			if frame > 15:
				be("idle")

		"shield":
			movement()
			if frame < 20:
				if motion.y > 300:
					motion.y = 300
			motion.x = lerp(motion.x, 0, AIRFRICTION)
			shield_size -= 2
			prev_shield_size = shield_size
			if frame > 8 || frame < 2:
				if updatefloorstate():
					if new_input[0]:
						be("roll")
					elif new_input[1]:
						be("roll")
					elif new_input[3]:
						be("spotdodge")
					elif !input[6]:
						be("outofshield")
				else:
					if (input[0] || input[1] || input[2] || input[3]) && has_airdodge:
						be("airdodge")
					elif !input[6]:
						be("outofshield")
					if motion.y >= 0:
						motion.y -= GRAVITY*0.9
			if shield_size < 30:
				be("shieldbreak")
		"shieldstun":
			movement()
			shield_size -= 1
			if frame > shield_stun:
				if input[6]:
					be("shield")
					frame = 2
				else:
					be("outofshield")
		"outofshield":
			movement()
			buffer(updatefloorstate())
			if frame > 5:
				if updatefloorstate():
					be("idle")
				else:
					be("jump")
		"airdodge":
			in_fast_fall = false
			wavedash_frame = WAVEDASHLENGTH - frame
			has_airdodge = false
			if frame == 1:
				neutral_airdodge = false
				if input[2]:
					motion = Vector2(0,-900)
					if input[0]:
						motion = Vector2(800,-700)
					if input[1]:
						motion = Vector2(-800,-700)
				elif input[3]:
					motion = Vector2(0, 1000)
					if input[0]:
						motion = Vector2(800,800)
					if input[1]:
						motion = Vector2(-800,800)
				elif input[0]:
					motion = Vector2(1000,-200)
				elif input[1]:
					motion = Vector2(-1000,-200)
				else:
					neutral_airdodge = true
					intangibility_frame += 10 
					
			if !neutral_airdodge:
				motion.x = lerp(motion.x, 0, .03)
				if frame > 13:
					motion.x = clamp(motion.x, -MAXAIRSPEED, MAXAIRSPEED)
					if motion.y > MAXFALLSPEED:
						motion.y = MAXFALLSPEED
					ledgesnap()
				else:
					motion.y -= GRAVITY/3
			else:
				movement()
			if frame > 47:
				be("jump")
			if updatefloorstate():
				be("land")
					
		"roll":
			if !updatefloorstate():
				be("jump")
			var speedmodifier = pow(ROLLFRAMES - abs(frame-(ROLLFRAMES/4)),2)/50
			motion.x = ROLLSPEED * -d * speedmodifier
			if frame > ROLLFRAMES:
				motion.x = 0
				buffer(true)
				if frame > ROLLFRAMES+8+roll_stale/100:
					roll_stale += 150
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
				motion += hitter_motion
				if motion.length() <  LAUNCH_THRESHOLD:
					nextstate = "mildstun"
					stage = 0
					frame = 0
				else:
					nextstate = "hit"
					stage = 0
					frame = 0
		"mildstun":
			launchdirectionalinput()
			if updatefloorstate():
				motion = Vector2(cos(launch_direction * PI/180), sin(launch_direction * PI/180)) 
				motion *= launch_knockback
				motion.y = -abs(motion.y)
				motion.x = lerp(motion.x, 0, 0.5)
			motion.y -= GRAVITY
			motion.y = lerp(motion.y, MAXFALLSPEED, .05)
			motion.x = lerp(motion.x, 0, 0.05)
			if input[0]:
				motion.x += AIRACCEL/4
			if input[1]:
				motion.x -= AIRACCEL/4
			if frame > stun_length - 10 && (abs(motion.y) < MAXFALLSPEED && abs(motion.x) < MAXAIRSPEED):
				if updatefloorstate():
					be("idle")
				else:
					be("jump")
				buffer(updatefloorstate())
		"hit":
			match stage:
				0:
					motion.x = lerp(motion.x, 0, 0.05)
					motion.y = lerp(motion.y, 0, 0.05)
					launchdirectionalinput()
					if frame > stun_length && (abs(motion.y) < MAXFALLSPEED && abs(motion.x) < MAXAIRSPEED):
						stage = 1
						frame = 0
						
					if motion.length() > LAUNCH_THRESHOLD*3:
						var effect = EFFECT.instance()
						effect.position = get_position()
						effect.d = d
						effect.myframe = 0
						effect.playernumber = player_who_last_hit_me
						effect.effecttype = "launch"
						get_tree().get_root().add_child(effect)
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
					if new_input[3] && motion.y > -500:
						in_fast_fall = true
					airoptions()
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
					if !updatefloorstate():
						be("jump")
				1:
					if updatefloorstate():
						if input[0] || input[1]:
							be("roll")
						if frame > 300 || input[2] || input[6]:
							be("getup")
						if input[4] || input[5]:
							be("getupattack")
					else:
						be("jump")
		"getup":
			if frame > 10 || input[2]:
				be("idle")
		"getupattack":
			if frame > 30 || input[2]:
				be("idle")
		
		"respawn":
			match stage:
				0:
					if frame == 1:
						var people_respawning = []
						for i in range(Globals.NUM_OF_PLAYERS):
							people_respawning.append(false)
						for i in range(Globals.NUM_OF_PLAYERS):
							if Globals.players[i].state == "respawn":
								if Globals.players[i].respawn_order != -1:
									people_respawning[Globals.players[i].respawn_order] = true
						respawn_order = people_respawning.find(false)
						position.x = respawn_order * 256
					motion = Vector2(0,0)
					var squared = RESPAWN_ANIMATION_FRAMES*RESPAWN_ANIMATION_FRAMES
					var opp = RESPAWN_ANIMATION_FRAMES - frame
					var gradient  = 1 - (opp*opp*1.0)/float(squared)
					invincibility_frame = 2
					position.y = lerp(Globals.TOPBLASTZONE-256, -512, gradient)
					if frame > RESPAWN_ANIMATION_FRAMES:
						stage = 1
						frame = 0
				1:
					motion = Vector2(0,0)
					motion.y -= GRAVITY
					position.y = -512
					invincibility_frame = 2
					respawn_order = -1
					if input.has(true) || frame > RESPAWN_IDLE_FRAMES:
						invincibility_frame = RESPAWN_INVINCIBILITY_FRAMES
						be("jump")
						if input[3]:
							in_fast_fall = true
						if input[2]:
							doublejump()
						
		"shieldbreak":
			if frame < 2:
				motion = Vector2(0,-JUMPFORCE*1.5)
			shield_size = SHIELDTIME
			motion.x = 0
			if motion.y > MAXFALLSPEED:
				motion.y = MAXFALLSPEED
			if frame > 30:
				if updatefloorstate():
					be("dizzy")
		"dizzy":
			if !updatefloorstate():
				be("jump")
			if frame > 450:
				be("idle")
	
	#TEMPORARY FAILSAFE
	if frame > 60 && !input.has(true) && !["ledge", "jump", "hitstun", "hit", "knockeddown", "respawn", "shieldbreak", "dizzy"].has(state):
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
		
		double_jump_frame = 0
		
		if nextstate == "crouch":
			var collision = move_and_collide(Vector2(0,10))
			if collision:
				if (collision.collider.get_node("Collision") != null):
					if collision.collider.get_node("Collision").one_way_collision:
						nextstate = "jump"
						position.y += 10
		
		if nextstate == "jumpstart":
			if input[0]:
				jump_direction = 1
			elif input[1]:
				jump_direction = -1
			else:
				jump_direction = 0
		if nextstate == "roll":
			intangibility_frame = ROLLFRAMES - 8
		if nextstate == "spotdodge":
			intangibility_frame = SPOTDODGEFRAMES - 5
		if nextstate == "airdodge":
			intangibility_frame = AIRDODGEFRAMES
		
		if !(["jump", "jumpstart", "airdodge", "hit", "forwardair", "backair", "upair", "downair", "neutralair"].has(nextstate)):
			if input[0] || input[8]:
				if !nextstate == "roll":
					d = 1
				else:
					d = -1
			elif input[1] || input[9]:
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
		if input[2]:
			be("upground")
		elif input[3]:
			be("downground")
		elif input[0] || input[1]:
			be("sideground")
		else:
			be("neutralground")
	elif input[10]:
		be("upground")
	elif input[11]:
		be("downground")
	elif input[8] || input[9]:
		be("sideground")
	elif input[6]:
		if new_input[0] || new_input[1]:
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
		if (input[0] || input[1] || input[2] || input[3]) && has_airdodge:
			be("airdodge")
		else:
			be("shield")
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
		
		if new_input[3] && motion.y > -500:
			in_fast_fall = true
			
		if in_fast_fall && ["jump","upspecial"].has(state):
			set_collision_layer_bit(1, 0)
		else:
			set_collision_layer_bit(1, 1)

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
		if !(state == "run" || state == "jumpstart" || wavedash_frame > 0):
			motion.x = lerp(motion.x,0,FRICTION)
		motion.x = clamp(motion.x,-MAXGROUNDSPEED,MAXGROUNDSPEED)
		if (["neutralair", "forwardair", "backair", "upair", "downair", "airdodge"].has(state)):
			be("land")
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
	double_jump_frame = DOUBLEJUMPFRAMES
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
	motion = move_and_slide(di*50, UP)
	
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
	motion += di*10
			
func respawn(place, first_time_respawning=false):
	if first_time_respawning:
		spawnposition = place
		on_floor = true
		self.position = spawnposition
		state = "jump"
		nextstate = "jump"
		stock = Globals.STOCKS
		score = 0
		respawn_order = -1
	else:
		self.position = Vector2(0,-512)
		on_floor = false
		d = 1
		state = "respawn"
		nextstate = "respawn"

	motion = Vector2(0,0)
	in_fast_fall = false
	double_jump_frame = 0
	has_double_jump = true
	has_airdodge = true
	shield_stun = 0
	shield_size = SHIELDTIME
	bufferedstate = "none"
	buffereddirection = "none"
	buffering = false
	if !first_time_respawning:
		invincibility_frame = RESPAWN_INVINCIBILITY_FRAMES
	else:
		invincibility_frame = 0
	intangibility_frame = 0
	first_time_at_ledge = true
	drop_frame = 0
	damage = 0
	
	impact_frame = 0
	launch_direction = 0
	stun_length = 0
	hitter_motion = Vector2(0,0)
	
	frame = 0
	stage = 0
	on_floor = false
	
	defeated = false
	
	
	
	Mat = $Sprite.get_material()
	Mat.set_shader_param("skin", skin)
	ShieldMat = $Shield.get_material()
	ShieldMat.set_shader_param("stun", false)

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
		var target = playernumber%Globals.NUM_OF_PLAYERS
		var enemyx = Globals.players[target].get_position().x
		var enemyy = Globals.players[target].get_position().y
		
		if Globals.GAMEMODE == "SOCCER":
			enemyx = Globals.projectiles[0].get_position().x
			enemyy = Globals.projectiles[0].get_position().y
		
		var offstage = x < Globals.LEDGES[0][0].x ||  x > Globals.LEDGES[1][0].x
		
		if false:
			#offense
			if !offstage:
				input[0] = input[0] || x < enemyx - 128
				input[1] = input[1] || x > enemyx + 128
				input[2] = (input[2] || y > enemyy - 128 || frame%60 < 20) && ! frame%60 < 10
				input[3] = input[3] || y < enemyy
				
				if !is_on_floor():
					if x < enemyx:
						if enemyy < y:
							input[10] = true
						else:
							input[8] = true
					else:
						if enemyy < y:
							input[10] = true
						else:
							input[9] = true
							
				#defense
				for p in Globals.players:
					if (p.position - position).length() < 128:
						if ["neutralair", "fordwardair", "backair", "upair", "downair"].has(p.state):
							input[0] = false
							input[1] = false
							input[2] = false
							input[3] = false
							input[6] = true
		
		
		#recovery
		if offstage:
			input[0] = x < Globals.LEDGES[0][0].x
			input[1] = x > Globals.LEDGES[1][0].x
			if  y > Globals.LEDGES[1][0].y + 64:
				if has_double_jump:
					input[2] = true
				if abs(x) < abs(Globals.LEDGES[0][0].x)+1000 && !has_double_jump:
					input[2] = true
					input[4] = true
#		input = Globals.players[0].input
#		var temp = input[0]
#		input[0] = input[1]
#		input[1] = temp


#CPU STUFF



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

func hurtbox(sx,sy,ox,oy):
	hurtboxsize = Vector2(sx,sy)
	hurtboxoffset = Vector2(ox,oy)


func hitbox(boxes):
	var hbox = HITBOX.instance()
	hbox.startframe = []
	hbox.life = 0
	hbox.boxlengths = []
	hbox.topleft = []
	hbox.bottomright = []
	hbox.damage = []
	hbox.hitdirection = []
	hbox.knockback = []
	hbox.constknockback = []
	hbox.stun = []
	hbox.shieldstun = []
	hbox.hitstun = []
	
	hbox.visible = Globals.SHOWHITBOXES
	hbox.players_to_ignore = []
	
	for b in boxes:
		hbox.boxlengths.append(b["len"])
		hbox.topleft.append(Vector2(b["l"], b["t"]))
		hbox.bottomright.append(Vector2(b["r"], b["b"]))
		hbox.damage.append(b["dam"])
		hbox.hitdirection.append(b["dir"])
		if b.has("kb"):
			hbox.knockback.append(b["kb"])
		else:
			hbox.knockback.append(1)
		if b.has("ckb"):
			hbox.constknockback.append(b["ckb"])
		else:
			hbox.constknockback.append(0)
		hbox.stun.append(b["hs"])
		hbox.shieldstun.append(b["ss"])
		if b.has("dohs"):
			hbox.hitstun.append(b["dohs"])
		else:
			hbox.hitstun.append(true)
		if b.has("del"):
			hbox.startframe.append(Globals.FRAME + b["del"])
			if hbox.life < b["len"] + b["del"]:
				hbox.life = b["len"] + b["del"]
		else:
			hbox.startframe.append(Globals.FRAME)
			if hbox.life < b["len"]:
				hbox.life = b["len"]
	hitboxes.append(hbox)
	add_child(hbox)


func beFrame(aframe):
	$Sprite.frame = aframe

func updateDirection():
	$Sprite.scale.x = d

func playerEffects():
	
	visible = !defeated
	
	var rage = clamp((damage-50)/50.0, 0, 20)
	$Sprite.position = Vector2(randi() %2 * rage - rage/2, randi() %2 * rage - rage/2)
	
	controllercolor = Globals.CONTROLLERCOLORS[controller]
	
	skin = skin % 8
	$Shield.visible = (state == "shield" && frame > 1) || state == "shieldstun"
	$Shield.position = Vector2(-144, 152) + SHIELDOFFSET
	ShieldMat.set_shader_param("stun", state == "shieldstun")
	ShieldMat.set_shader_param("size", shield_size)
	ShieldMat.set_shader_param("prevsize", prev_shield_size)
	ShieldMat.set_shader_param("color", controllercolor)

	
	$Hurtbox.visible = Globals.SHOWHITBOXES
	
	Mat.set_shader_param("outline_col", Color((damage-50)/100.0, 0, 0, 1))
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
	
func upground():
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
