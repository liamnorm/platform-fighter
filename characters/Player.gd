extends KinematicBody2D

#stuff to load
onready var HITBOX = preload("res://characters/Hitbox.tscn")
onready var EFFECT = preload("res://resources/ImpactEffect.tscn")
var w

#identifying features
var playernumber = 0
var character = "SPACEDOG"
var skin = 0
var controller = 0
var team = 0
var tag = ""
var playerid = 0 #for server

#shader materials
var Mat
var ShieldMat
var controllercolor

#constants
const UP = Vector2(0, -1)
const SHIELDTIME = 300.0
const LAUNCH_THRESHOLD = 400
const LEDGETIME = 300
const RESPAWN_INVINCIBILITY_FRAMES = 60
const RESPAWN_ANIMATION_FRAMES = 30
const RESPAWN_IDLE_FRAMES = 180
const LEDGE_INTANGIBILITY_FRAMES = 45
const is_projectile = false
const TRUEMAXSPEED = 10000
const FLOATTIME = 60

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
var ROLLSPEED = 400
var ROLLFRAMES = 20
var SPOTDODGEFRAMES = 17
var AIRDODGEFRAMES = 18
var WAVEDASHLENGTH = 14
var DOUBLEJUMPFRAMES = 30
var SHIELDOFFSET = Vector2(0,0)
var HELDCOORDS = []

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
var current_ledge = -1
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
var jump_direction = 0
var in_fast_fall = false
var has_airdodge = true
var shield_size = SHIELDTIME
var prev_shield_size = shield_size
var damage = 0.0
var invincibility_frame = 0
var intangibility_frame = 0
var landing_lag = 0
var neutral_airdodge = false
var wavedash_frame = 0
var respawn_order = -1
var floatframe = FLOATTIME
var float_frame = 0
var floating = false
var totalrollframes = ROLLFRAMES
var totalspotdodgeframes = 0
var rageoffset = Vector2(0,0)
const holder = 0
const holdable = false
var charging = false
var charge_frame = 0
var turning = false
var turnaround_frame = 0
var pushradius = 64

#stale moves
var roll_stale = 0
var spotdodge_stale = 0
var stale_queue = []

#interactions
var impact_frame = 0
var launch_direction = 0
var launch_knockback = 1
var stun_length = 0
var connected = false
var shieldconnected = false
var shield_stun = 0
var player_who_last_hit_me = 0
var shield_physical_size = 0
var hitter_motion = Vector2(0,0)
var heldpos = Vector2(0,0)
var heldobject = null

#scorekeeping
var stock = 5
var spawnposition = Vector2(0,-512)
var defeated = false
var defeattime = 0
var combo = 0
var score = 0


#for inputs
var input =      [false,false,false,false,false,false,false,false,false,false,false,false]
var new_input =  [false,false,false,false,false,false,false,false,false,false,false,false]
var prev_input = [false,false,false,false,false,false,false,false,false,false,false,false]
var input_lengths = [0,0,0,0,0,0,0,0,0,0,0,0]


# computer player
var target = 0

#for animation.
var ref = 0

func _ready():
	w = get_parent()
	
func _physics_process(_delta):
	
	if true:
		
		

		var paused = w.PAUSED
		var framechange = Input.is_action_just_pressed("nextframe")
		var intro = w.FRAME < 0
		var slowmo = w.SLOMOFRAME % 2 != 0
		if ((!paused) || framechange) && !defeated && !intro && !slowmo:
			
			x = get_position().x
			y = get_position().y
			

			get_input()
			
			
			$CollisionShape2D.disabled = false

			if impact_frame == 0:
			
			
				if (y > w.BOTTOMBLASTZONE || 
					(y < w.TOPBLASTZONE && state == "hit") || 
					abs(x) > w.SIDEBLASTZONE):
					if w.GAMEMODE == "STOCK":
						if abs(x) > w.TRIPLEBLASTZONE:
							stock -= 3
							w.TRIPLEKOFRAME = 120
						elif abs(x) > w.DOUBLEBLASTZONE:
							stock -= 2
							w.DOUBLEKOFRAME = 120
						else:
							w.KOFRAME = 120
							stock -= 1
						if w.STOCKS < 0:
							stock = 1
						if stock < 0:
							stock = 0
						if stock > 0:
							respawn(Vector2(0,w.TOPBLASTZONE))
						else:
							defeated = true
							defeattime = w.FRAME
							if w.GAMEENDFRAME == 0:
								w.ELIMINATIONFRAME = 120
								if controller == 0:
									w.ELIMINATEDPLAYER = playernumber
								else:
									w.ELIMINATEDPLAYER = 0
#								var players_left = 0
#								var winner = 0
#								for p in w.players:
#									if !p.defeated:
#										players_left += 1
#										winner = p.playernumber
#								w.DEFEATORDER[playernumber-1] = players_left
#								if players_left < 2:
#									w.GAMEENDFRAME = 1
#									Globals.WINNER = winner
#									Globals.WINNERSKIN = w.players[winner-1].skin
#									Globals.WINNERCHARACTER = w.players[winner-1].character
#									Globals.WINNERCONTROLLER = w.players[winner-1].controller
					elif w.GAMEMODE == "TIME":
						if abs(x) > w.TRIPLEBLASTZONE:
							score -= 3
							w.players[player_who_last_hit_me-1].score += 3
							w.TRIPLEKOFRAME = 120
						elif abs(x) > w.DOUBLEBLASTZONE:
							score -= 2
							w.players[player_who_last_hit_me-1].score += 3
							w.DOUBLEKOFRAME = 120
						else:
							score -= 1
							w.players[player_who_last_hit_me-1].score += 3
							w.KOFRAME = 120
						respawn(Vector2(0,w.TOPBLASTZONE))
					else:
						respawn(Vector2(0,w.TOPBLASTZONE))
					
					playsound("KO")
				
				if !state == "ledge":
					motion.y += GRAVITY
					
				if charging:
					charge_frame += 1
				else:
					charge_frame = 0
				charging = false
				
				if turning:
					turnaround_frame += 1
				else:
					turnaround_frame = 0
				turning = false
				
				statebasedaction()
				
				motion.x = clamp(motion.x, -TRUEMAXSPEED, TRUEMAXSPEED)
				motion.y = clamp(motion.y, -TRUEMAXSPEED, TRUEMAXSPEED)
				
				if (state == "hit" && stage == 0):
					var collision = move_and_collide(motion/60.0)
					if collision:
						if (collision.collider.get_node_or_null("Collision") != null):
							if collision.collider.get_node("Collision").one_way_collision:
								if motion.y > 0:
									motion.y = -motion.y
									motion = motion*0.7
						else:
							if motion.length() > 500:
								if !(motion.length() < 5000 && input[6]):
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
				
				if w.FRAME%2 == 1:
					shield_size += 1
				shield_size = clamp(shield_size, 0, SHIELDTIME)
				shield_physical_size = sqrt(shield_size)*5-10
		
		impact_frame -= 1
		if impact_frame < 1:
			impact_frame = 0
		else:
			if state == "hitstun":
				directionalinput()
		
	if w.ONLINE && w.ISSERVER:
		send_state()


	#DRAW
	updateDirection()
	playerEffects()
	drawPlayer()
	updateheld()
	drawhurtbox()
	
	
	
remote func _set_position(pos):
	position = pos


func statebasedaction():
	match state:
		"idle":
			movement()
			if input[0] || input[1]:
				if !(input[0] && input[1]):
					be("run")
			elif input[3]:
				be("crouch")
			groundoptions()
			
			be_jump_if_in_midair()
				
		"run":
			movement()
			if frame % 7 == 4:
				playsound("WALK" + str(randi()%3))
			if frame == 1:
				if d == 1:
					if input[1] && !input[0]:
						turn(-1)
						frame = 0
						motion.x = -MAXGROUNDSPEED
				else:
					if input[0] && !input[1]:
						turn(1)
						frame = 0
						motion.x = MAXGROUNDSPEED
			elif (input[0] && d == 1 && !input[1]) || (input[1] && d == -1 && !input[0]):
				if frame < 4:
					if motion.x * d < 0:
						frame = 0
					motion.x = d * MAXGROUNDSPEED
				else:
					motion.x += d * ACCEL
				if input[0]:
					turn(1)
				else:
					turn(-1)
			else:
				if !(input[0] || input[1]):
					be("runend")
				else:
					be("turnaround")
			if frame < 4 && input[6]:
				be("roll")
			groundoptions()
			
			be_jump_if_in_midair()
		
		"runend":
			movement()
			buffer(true)
			if input[0] && !input[1]:
				if d == 1:
					be("run")
				else:
					be("turnaround")
			elif input[1] && !input[0]:
				if d == -1:
					be("run")
				else:
					be("turnaround")
			if frame > 10:
				be("idle")
				
			be_jump_if_in_midair()
		
		"turnaround":
			motion.x = lerp(motion.x, 0, .1)
			if frame > 7:
				be("run")
			
			be_jump_if_in_midair()
		
		"jumpstart":
			movement()
			buffer(false)
			has_double_jump = true
			floatframe = FLOATTIME
			float_frame = 0
			floating = false
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
				
			be_jump_if_in_midair()

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
			motion.x = lerp(motion.x, 0, 0.05)
			buffer(true)
			if frame > landing_lag:
				landing_lag = 5
				if input[3]:
					be("crouch")
				else:
					be("idle")
			be_jump_if_in_midair()
		"crouch":
			if !input[3]:
				be("idle")
#			match stage:
#				0:
#					if frame == 1:
#						position += Vector2(0, 10)
#					if frame > 5:
#						stage = 1
#						frame = 0
#				1:
#					if frame > 6:
#						if !input[3]:
#							stage = 2
#							frame = 0
#				2:
#					if frame > 5:
#						be("idle")
			movement()
			groundoptions()
			if input[6]:
				be("spotdodge")
			
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
		
		"extra":
			extra()
		
		"ledge":
			if frame == 1:
				#playsound("LEDGE")
				w.LEDGES[current_ledge][2] = playernumber
			if first_time_at_ledge && frame == 4:
				intangibility_frame = LEDGE_INTANGIBILITY_FRAMES
				first_time_at_ledge = false
			clearhitboxes()
			in_fast_fall = false
			has_double_jump = true
			has_airdodge = true
			floating = false
			floatframe = FLOATTIME
			float_frame = 0
			frames_since_ledge = 0
			snaptoledge()
			
			if w.LEDGES[current_ledge][2] != playernumber:
				motion.y = -JUMPFORCE * 0.5
				motion.x = w.LEDGES[current_ledge][1] * -2000
				be("jump")
			
			elif frame > 15:
				if input[0]:
					if w.LEDGES[current_ledge][1] == 1:
						w.LEDGES[current_ledge][2] = 0
						be("ledgegetup")
					else:
						w.LEDGES[current_ledge][2] = 0
						be("jump")
				elif input[1]:
					if w.LEDGES[current_ledge][1] == -1:
						w.LEDGES[current_ledge][2] = 0
						be("ledgegetup")
					else:
						w.LEDGES[current_ledge][2] = 0
						be("jump")
				elif input[2]:
					motion.y = -JUMPFORCE
					w.LEDGES[current_ledge][2] = 0
					be("jump")
				elif new_input[3]:
					in_fast_fall = false
					w.LEDGES[current_ledge][2] = 0
					be("jump")
				if frame > LEDGETIME:
					w.LEDGES[current_ledge][2] = 0
					be("jump")
		
		"ledgegetup":
			
			motion = Vector2(0,0)
			var ledge_x = w.LEDGES[current_ledge][0].x + w.LEDGES[current_ledge][1] * 0
			var ledge_y = w.LEDGES[current_ledge][0].y + 0
			$CollisionShape2D.disabled = true
			set_position(Vector2(ledge_x, ledge_y))
			
			
			if frame > 18:
				ledge_x = w.LEDGES[current_ledge][0].x + w.LEDGES[current_ledge][1] * 64
				ledge_y = w.LEDGES[current_ledge][0].y - 64
				set_position(Vector2(ledge_x, ledge_y))
				be("idle")

		"shield":
			if frame == 2:
				playsound("SHIELDOPEN")
			movement()
			if floatframe > 0:
				floatframe -= 1
				motion.y = 0
			if motion.y > MAXFALLSPEED:
				motion.y = MAXFALLSPEED
			motion.x = lerp(motion.x, 0, AIRFRICTION)
			shield_size -= 2
			in_fast_fall = false
			prev_shield_size = shield_size
			if frame > 8:
				if updatefloorstate():
					if new_input[2]:
						be("jumpstart")
					elif new_input[0]:
						be("roll")
					elif new_input[1]:
						be("roll")
					elif new_input[3]:
						be("spotdodge")
					elif !input[6]:
						be("outofshield")
				else:
					if (new_input[0] || new_input[1] || new_input[2] || new_input[3]) && has_airdodge:
						be("airdodge")
					elif !input[6]:
						be("outofshield")
			elif frame < 4:
				if updatefloorstate():
					if input[0]:
						be("roll")
					elif input[1]:
						be("roll")
					elif input[3]:
						be("spotdodge")
			if shield_size < 30:
				be("shieldbreak")
		"shieldstun":
			movement()
			shield_size -= 1
			if frame > shield_stun:
				if input[6]:
					be("shield")
					frame = 3
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
			else:
				if frame == 1:
					totalrollframes = ROLLFRAMES+8+roll_stale/100
				var speedmodifier = pow(ROLLFRAMES - abs(frame-(totalrollframes/3)),2)/70
				motion.x = ROLLSPEED * -d * speedmodifier * float(ROLLFRAMES) / totalrollframes
				if frame > totalrollframes - 5:
					motion.x = 0
					buffer(true)
					if frame > totalrollframes:
						roll_stale += 150
						be("idle")
		"spotdodge":
			motion.x = 0
			if frame == 1:
				totalspotdodgeframes = SPOTDODGEFRAMES+8+spotdodge_stale/100
			if frame > totalspotdodgeframes-5:
				buffer(true)
				if frame > totalspotdodgeframes:
					be("idle")
			movement()
		"hitstun":
			motion = Vector2(0,0)
			clearhitboxes()
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
			clearhitboxes()
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
			clearhitboxes()
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
						w.add_child(effect)
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
					if new_input[3] && motion.y > -500 && !in_fast_fall:
						fast_fall()
					if input[6]:
						be("shield")
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
							intangibility_frame = 2
							be("getup")
						if input[4] || input[5]:
							be("getupattack")
					else:
						be("jump")
		"getup":
			if frame == 1:
				intangibility_frame = 20
			if frame > 22:
				be("idle")
		"getupattack":
			getupattack()
				
		"neutralgetup":
			pass
		
		"softland":
			pass
		
		"respawn":
			match stage:
				0:
					if frame == 1:
						var people_respawning = []
						for _i in range(w.NUM_OF_PLAYERS):
							people_respawning.append(false)
						for i in range(w.NUM_OF_PLAYERS):
							if w.players[i].state == "respawn":
								if w.players[i].respawn_order != -1:
									people_respawning[w.players[i].respawn_order] = true
						respawn_order = people_respawning.find(false)
						position.x = respawn_order * 256
					motion = Vector2(0,0)
					var squared = RESPAWN_ANIMATION_FRAMES*RESPAWN_ANIMATION_FRAMES
					var opp = RESPAWN_ANIMATION_FRAMES - frame
					var gradient  = 1 - (opp*opp*1.0)/float(squared)
					invincibility_frame = 2
					position.y = lerp(w.TOPBLASTZONE-256, -512, gradient)
					if frame > RESPAWN_ANIMATION_FRAMES:
						stage = 1
						frame = 0
				1:
					motion = Vector2(0,0)
					motion.y -= GRAVITY
					position.y = -512
					invincibility_frame = 2
					if input.has(true) || frame > RESPAWN_IDLE_FRAMES:
						respawn_order = -1
						invincibility_frame = RESPAWN_INVINCIBILITY_FRAMES
						be("jump")
						if input[3] && !in_fast_fall:
							fast_fall()
						if input[2]:
							doublejump()
						
		"shieldbreak":
			if frame < 2:
				motion = Vector2(0,-JUMPFORCE*1.5)
			else:
				shield_size = SHIELDTIME
			motion.x = 0
			if motion.y > MAXFALLSPEED:
				motion.y = MAXFALLSPEED
			if frame > 30:
				if updatefloorstate():
					be("dizzy")
		"dizzy":
			shield_size = SHIELDTIME
			if new_input.has(true):
				frame += 3
			if !updatefloorstate():
				be("jump")
			if frame > 600:
				be("idle")
				
				
	#FLOATING
	if ((input[7] && floatframe > 0 &&
	!["ledge", "hitstun", "mildstun", "knockeddown", "respawn", "shield", "shieldstun", "shieldbreak", "dizzy", "sidespecial", "upspecial", "downspecial"].has(state))
	&& !(state == "hit" && stage == 0)
	&& !(["neutralair", "forwardair", "backair", "upair", "downair"].has(state) && !floating) #can't start floating if doing aerial
	|| (float_frame > 0 && float_frame < 16)):
		if !floating:
			float_frame = 0
		floating = true
	else:
		floating = false
	if floating:
		if state == "hit":
			be("jump")
		in_fast_fall = false
		motion.y = 0
		floatframe -= 1
		float_frame += 1
		if floatframe <= 0:
			float_frame = 0
			floatframe = 0
			floating = false
	
	#RAGE
	
	var rage = clamp((damage-50)/50.0, 0, 20)
	var randox = (randi() %10 - 5) / 5.0
	var randoy = (randi() %10 - 5) / 5.0
	rageoffset = Vector2(randox * rage - rage/2, randoy * rage - rage/2)
	if charging:
		var chargeoffset = 0
		if charge_frame % 2 == 0:
			chargeoffset = charge_frame
		else:
			chargeoffset = -charge_frame
		chargeoffset = clamp(chargeoffset, -3, 3)
		rageoffset.x += chargeoffset
	hurtboxoffset = rageoffset
	SHIELDOFFSET = rageoffset
	
	
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
				if (collision.collider.get_node_or_null("Collision") != null):
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
		
		if !(["run", "runend", "jump", "jumpstart", "airdodge", "hit", "forwardair", "backair", "upair", "downair", "neutralair"].has(nextstate)):
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
	elif new_input[5]:
		if input[2]:
			be("upground")
			if input[0]:
				buffereddirection = "right"
			else:
				buffereddirection = "left"
		elif input[3]:
			be("downground")
			if input[0]:
				buffereddirection = "right"
			else:
				buffereddirection = "left"
		elif input[0] || input[1]:
			be("sideground")
			if input[0]:
				buffereddirection = "right"
			else:
				buffereddirection = "left"
		else:
			be("neutralground")
	elif new_input[10]:
		be("upground")
	elif new_input[11]:
		be("downground")
	elif new_input[8] || new_input[9]:
		be("sideground")
	elif input[6]:
		if new_input[0] || new_input[1]:
			be("roll")
		if new_input[3]:
			be("spotdodge")
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
	elif new_input[5]:
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
	elif new_input[6]:
		if (new_input[0] || new_input[1] || new_input[2] || new_input[3]) && has_airdodge:
			be("airdodge")
		else:
			be("shield")
	elif new_input[10]:
		be("upair")
	elif new_input[11]:
		be("downair")
	elif new_input[8]:
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
		floatframe = FLOATTIME
		floating = false
		has_airdodge = true
		first_time_at_ledge = true
		if ["jump", "neutralair", "forwardair", "backair", "upair", "downair", "airdodge"].has(state):
			be("land")
	if !is_on_floor() && on_floor == true:
		on_floor = false
		if ["run", "runend", "turnaround", "sideground", "downground", "upground", "neutralground", "idle", "crouch", "land", "roll"].has(state):
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
		
		if new_input[3] && motion.y > -500 && !in_fast_fall:
			fast_fall()
			
		if in_fast_fall && ["jump","upspecial"].has(state):
			set_collision_layer_bit(1, 0)
		else:
			set_collision_layer_bit(1, 1)

		fallcap(false)
		
func ledgesnap():
	if frames_since_ledge > 30 && !floating:
		var myx = get_position().x
		var i = 0
		for ledge in w.LEDGES:
			if abs(myx+32*ledge[1]-ledge[0].x) < 32:
				var myy = get_position().y
				if abs(myy-48-ledge[0].y) < 48:
					current_ledge = i
					be("ledge")
					snaptoledge()
			i += 1
		
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
	
	var effect = EFFECT.instance()
	effect.position = get_position() + Vector2(0, 60)
	effect.d = d
	effect.myframe = 0
	effect.playernumber = playernumber
	effect.effecttype = "doublejump"
	w.add_child(effect)
	
func fast_fall():
	in_fast_fall = true
	var effect = EFFECT.instance()
	effect.position = get_position() + Vector2(d*-60, -20)
	effect.d = d
	effect.myframe = 0
	effect.playernumber = playernumber
	effect.effecttype = "glimmer"
	w.add_child(effect)
	
func throw(throwx, throwy):
	if heldobject != null:
		heldobject.holder = 0
		heldobject.motion = Vector2(throwx * d, throwy)
		heldobject.intangibility_frame = 10
		heldobject = null
	
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
	w = get_parent()
	if first_time_respawning:
		spawnposition = place
		on_floor = true
		self.position = spawnposition
		state = "jump"
		nextstate = "jump"
		stock = w.STOCKS
		score = 0
		respawn_order = -1
	else:
		self.position = Vector2(0,-512)
		on_floor = false
		d = 1
		state = "respawn"
		nextstate = "respawn"

	floating = false
	floatframe = FLOATTIME
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
	damage = 0.0
	
	totalrollframes = ROLLFRAMES
	
	impact_frame = 0
	launch_direction = 0
	stun_length = 0
	hitter_motion = Vector2(0,0)
	
	frame = 0
	stage = 0
	on_floor = false
	
	defeated = false
	
	$CollisionShape2D.disabled = false
	
	
	
	Mat = $Sprite.get_material()
	Mat.set_shader_param("skin", skin)
	ShieldMat = $Shield.get_material()
	ShieldMat.set_shader_param("stun", false)

func drawhurtbox():
	$Hurtbox.margin_left = -hurtboxsize.x + hurtboxoffset.x * d
	$Hurtbox.margin_right = hurtboxsize.x + hurtboxoffset.x * d
	$Hurtbox.margin_top = -hurtboxsize.y + hurtboxoffset.y
	$Hurtbox.margin_bottom = hurtboxsize.y + hurtboxoffset.y
	
	$Shieldbox.margin_left = -shield_physical_size + SHIELDOFFSET.x * d
	$Shieldbox.margin_right = shield_physical_size + SHIELDOFFSET.x * d
	$Shieldbox.margin_top = -shield_physical_size + SHIELDOFFSET.y
	$Shieldbox.margin_bottom = shield_physical_size + SHIELDOFFSET.y


func get_input():
	if !(w.ISSERVER || (w.ONLINE && !name == str(get_tree().get_network_unique_id()))):
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
			
			if w.FRAME < 20 || target == null:
				target = playernumber%w.NUM_OF_PLAYERS
			if w.players[target].defeated || target == playernumber-1:
				target += 1
				target = target%w.NUM_OF_PLAYERS
			var enemyx = w.players[target].get_position().x
			var enemyy = w.players[target].get_position().y
			
			if w.GAMEMODE == "SOCCER":
				enemyx = w.projectiles[0].get_position().x
				enemyy = w.projectiles[0].get_position().y
			
			var offstage = false
			if w.LEDGES.size() > 1:
				offstage = x < w.LEDGES[0][0].x ||  x > w.LEDGES[1][0].x || y > w.LEDGES[0][0].y
			
			#input[6] = true
			if !w.GAMEMODE == "TRAINING":
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
								
					if (abs(x - enemyx) < 64 && abs(y - enemyy) < 64) || state == "upspecial":
						input[2] = true
						input[4] = true
						input[1] = false
						input[0] = false
					
					if abs(x - enemyx) > 192 && randi()%16 == 0:
						input[0] = false
						input[1] = false
						input[2] = false
						input[3] = false
						input[4] = true
								
								
					#defense
					for p in w.players:
						if (p.position - position).length() < 128:
							if ["neutralair", "fordwardair", "backair", "upair", "downair"].has(p.state):
								input[0] = false
								input[1] = false
								input[2] = false
								input[3] = false
								input[6] = true
			
			
			#recovery
			if offstage:
				
				var tl = 0
				if x > 0:
					tl = 1
				var tlp = w.LEDGES[tl][0]
				input[0] = x < tlp.x
				input[1] = x > tlp.x
				
				
				if  y > tlp.y + 64:
					var slope = abs((x-tlp.x)/(y-tlp.y))
					if has_double_jump:
						#double jump
						input[2] = true
					elif ((slope > 0.9 && slope < 1.1) || abs(x-tlp.x) < 64) && !has_double_jump || state == "upspecial":
						#upspecial if diagonal or under ledge
						if abs(x-tlp.x) < 64:
							input[0] = false
							input[1] = false
						input[2] = true
						input[4] = true
				else:
					#sidespecial
					if state == "jump" && abs(x-tlp.x) > 256:
						input[4] = true
						input[2] = false
						
			if state == "ledge":
				if w.LEDGES[current_ledge][1] == 1:
					input[0] = true
				else:
					input[1] = true
			if state == "knockeddown":
				input[2] = true
	#		input = w.players[0].input
	#		var temp = input[0]
	#		input[0] = input[1]
	#		input[1] = temp
	#CPU STUFF!


		elif controller > 0:
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
			if controller <= 3:
				var c = str(controller-1)
				if controller == 1:
					c = ""
				input = [
					Input.is_action_pressed("right" + c),
					Input.is_action_pressed("left" + c),
					Input.is_action_pressed("jump" + c),
					Input.is_action_pressed("down" + c),
					Input.is_action_pressed("special" + c),
					Input.is_action_pressed("attack" + c),
					Input.is_action_pressed("shield" + c),
					Input.is_action_pressed("extra" + c),
					Input.is_action_pressed("rightattack" + c),
					Input.is_action_pressed("leftattack" + c),
					Input.is_action_pressed("upattack" + c),
					Input.is_action_pressed("downattack" + c),
				]
			
		#for when the stick flicks
		if prev_input[0]:
			input[1] = false
		if prev_input[1]:
			input[0] = false
			
		if w.ONLINE && name == str(get_tree().get_network_unique_id()):
			rpc_unreliable_id(1, "_get_input", input)
			pass
		
	for i in range(len(input)):
		new_input[i] = input[i] && !prev_input[i]
	prev_input = input


func respectedge():
	if ["idle", "roll", "spotdodge", "shield", "land", "neutralground", "sideground", "upground", "downground", "neutralspecial", "sidespecial", "downspecial", "knockeddown", "runend", "turnaround"].has(state):
		for ledge in w.LEDGES:
			respectparticularedge(ledge)
		for ledge in w.PLATFORMLEDGES:
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
	hurtboxoffset = Vector2(ox+rageoffset.x*d,oy+rageoffset.y)
	
func clearhitboxes():
	for h in hitboxes:
		h.queue_free()
	hitboxes = []


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
	hbox.d = d
	
	hbox.visible = w.SHOWHITBOXES
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
			hbox.startframe.append(w.FRAME + b["del"])
			if hbox.life < b["len"] + b["del"]:
				hbox.life = b["len"] + b["del"]
		else:
			hbox.startframe.append(w.FRAME)
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
	
	$Sprite.position = rageoffset
	
	if !w.GAMEMODE == "SOCCER":
		controllercolor = Globals.CONTROLLERCOLORS[controller]
	else:
		if team == 0:
			controllercolor = Globals.LEFTCOLOR
		else:
			controllercolor = Globals.RIGHTCOLOR
	
	skin = skin % Globals.NUM_OF_SKINS
	$Shield.visible = (state == "shield" && frame > 1) || state == "shieldstun"
	$Shield.position = Vector2(-144, 152) + SHIELDOFFSET
	ShieldMat.set_shader_param("stun", state == "shieldstun")
	ShieldMat.set_shader_param("size", shield_size)
	ShieldMat.set_shader_param("prevsize", prev_shield_size)
	ShieldMat.set_shader_param("color", controllercolor)

	
	$Hurtbox.visible = w.SHOWHITBOXES
	$Shieldbox.visible = w.SHOWHITBOXES
	
	Mat.set_shader_param("outline_col", Color((damage-50)/100.0, 0, 0, 1))
	Mat.set_shader_param("invincibility", invincibility_frame)
	Mat.set_shader_param("intangibility", intangibility_frame)
	Mat.set_shader_param("skin", skin)
	Mat.set_shader_param("charging", charging)
	
	

func be_jump_if_in_midair():
	if !updatefloorstate():
		be("jump")
		
func turn(dir):
	if !d == dir:
		turning = true
	if turnaround_frame > 2:
		d = dir
	
func snaptoledge():
	d = w.LEDGES[current_ledge][1]
	motion = Vector2(0,0)
	var ledge_x = w.LEDGES[current_ledge][0].x + w.LEDGES[current_ledge][1] * 0
	var ledge_y = w.LEDGES[current_ledge][0].y + 0
	$CollisionShape2D.disabled = true
	clearhitboxes()
	set_position(Vector2(ledge_x, ledge_y))



# ALL CHARACTER-SPECIFIC STUFF SHOULD GO HERE!!!!!

func updateheld():
	if $Sprite.frame < len(HELDCOORDS):
		heldpos = Vector2(-128 + HELDCOORDS[$Sprite.frame][0], -128 + HELDCOORDS[$Sprite.frame][1]) 
	else:
		heldpos = Vector2(-50, -10)

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
	
func extra():
	movement()
	
func getupattack():
	movement()
	
func ledgeattack():
	movement()
	
func playsound(sound):
	if !(Globals.MUTED || w.GAMEENDFRAME > 0):
		get_node("Sounds").get_node(sound).play()



func send_state():
	var sentstate = [
		floor(position.x),
		floor(position.y),
		d,
		Globals.states.find(state),
		stage,
		frame,
		damage,
		stock,
		intangibility_frame,
		invincibility_frame,
		double_jump_frame,
		on_floor,
		combo,
		float_frame,
		shield_size,
		current_ledge,
		floor(motion.x),
		floor(motion.y),
		input
		]
	rpc_unreliable("_get_position", sentstate)
	pass

remote func _get_position(ss):
	position = Vector2(ss[0], ss[1])
	d = ss[2]
	state = Globals.states[ss[3]]
	nextstate = Globals.states[ss[3]]
	stage = ss[4]
	frame = ss[5]
	damage = ss[6]
	stock = ss[7]
	intangibility_frame = ss[8]
	invincibility_frame = ss[9]
	double_jump_frame = ss[10]
	on_floor = ss[11]
	combo = ss[12]
	float_frame = ss[13]
	shield_size = ss[14]
	current_ledge = ss[15]
	motion = Vector2(ss[16], ss[17])
	
	if !name == str(get_tree().get_network_unique_id()):
		input = ss[18]
	
	drawPlayer()
	
remote func _get_input(sentinput):
	if str(get_tree().get_rpc_sender_id()) == name:
		input = sentinput
