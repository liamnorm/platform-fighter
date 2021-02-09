extends KinematicBody2D

onready var HITBOX = preload("res://Hitbox.tscn")
var hitboxes = []

var LEDGES

var playernumber = 0
var character = "Fox"
var skin = 0
var controller = 0

var Mat

const UP = Vector2(0, -1)

const SHIELDTIME = 300.0


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
var SPOTDODGEFRAMES = 18
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

var impact_frame = 0
var launch_direction = 0
var launch_knockback = 1
var stun_length = 0
var connected = false

var stock = 3
var first_time_respawning = true
var spawnposition = Vector2(0,-512)

var input =      [false,false,false,false,false,false,false,false]
var new_input =  [false,false,false,false,false,false,false,false]
var prev_input = [false,false,false,false,false,false,false,false]
var input_lengths = [0,0,0,0,0,0,0,0]

var ref = 0

func _ready():
	LEDGES = get_tree().get_root().get_node("World").get("LEDGES")
	drawhurtbox()
	
func _physics_process(_delta):
	
	var paused = get_tree().get_root().get_node("World").get("PAUSED")
	var framechange = Input.is_action_just_pressed("nextframe")
	if ((!paused) || framechange) && impact_frame == 0:
	
		get_input()
		
		if (self.position.y > get_tree().get_root().get_node("World").get("BOTTOMBLASTZONE") || 
			self.position.y < get_tree().get_root().get_node("World").get("TOPBLASTZONE") || 
			abs(self.position.x) > get_tree().get_root().get_node("World").get("SIDEBLASTZONE")):
			respawn(Vector2(0,-512))
		if (Input.is_action_just_pressed("reset")):
			respawn(spawnposition)
		
		if !state == "ledge":
			motion.y += GRAVITY
		
		statebasedaction()
		
		interact()
		
		motion = move_and_slide(motion, UP)
		
		
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
		
	#DRAW
	updateDirection()
	playerEffects()
	drawPlayer()


func statebasedaction():
	match state:
		"idle":
			movement()
			groundoptions()
			if input[0] || input[1]:
				be("run")
			elif input[3]:
				be("crouch")
				
		"run":
			movement()
			if input[0]:
				motion.x += ACCEL
				d = 1
			elif input[1]:
				motion.x -= ACCEL
				d = -1
			elif !(input[0] || input[1]):
				be("idle")
			groundoptions()
		
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
			airoptions()
			
		"land":
			movement()
			buffer(true)
			if frame > 4:
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
		"sideair":
			sideair()
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
				if frame > 300:
					be("jump")
		
		"ledgegetup":
			if frame > 15:
				be("idle")

		"shield":
			movement()
			shield_size -= 2
			if frame > 8:
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
					motion = Vector2(1400,-200)
				elif input[1]:
					motion = Vector2(-1400,-200)
				else:
					pass
			motion.x = lerp(motion.x, 0, .05)
			if frame > 20:
				motion.x = clamp(motion.x, -MAXAIRSPEED, MAXAIRSPEED)
				if motion.y > MAXFALLSPEED:
					motion.y = MAXFALLSPEED
				ledgesnap()
				if frame > 50:
					be("jump")
			else:
				motion.y -= GRAVITY/3
			if updatefloorstate():
				be("land")
					
		"roll":
			var speedmodifier = pow(ROLLFRAMES - abs(frame-(ROLLFRAMES/4)),2)/50
			motion.x = ROLLSPEED * d * speedmodifier
			if frame > ROLLFRAMES:
				motion.x = 0
				if frame == ROLLFRAMES+1:
					d = -d
				buffer(true)
				if frame > ROLLFRAMES+8:
					be("idle")
		"spotdodge":
			movement()
		"hitstun":
			motion = Vector2(0,0)
			if frame > 0:
				motion = Vector2(cos(launch_direction * PI/180), sin(launch_direction * PI/180)) 
				motion *= launch_knockback
				be("hit")
		"hit":
			match stage:
				0:
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
				d = 1
			if buffereddirection == "left":
				d = -1
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
		
		if !nextstate == "jump":
			if input[0]:
				d = 1
			elif input[1]:
				d = -1
		bufferedstate = "none"
		buffereddirection = "none"





func buffer(on_ground):
	buffering = true
	if on_ground:
		groundoptions()
	else:
		airoptions()
	if input[0]:
		buffereddirection = "right"
	elif input[1]:
		buffereddirection = "left"
	else:
		buffereddirection = "none"
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
		if input[3]:
			be("downair")
		elif input[0] || input[1]:
			be("sideair")
		else:
			be("neutralair")
	elif input[6]:
		be("airdodge")
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
		if ["jump", "neutralair", "sideair", "upair", "downair", "airdodge"].has(state):
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

		ledgesnap()
		fallcap(false)
		
func ledgesnap():
	if frames_since_ledge > 30:
		var myx = get_position().x
		for ledge in LEDGES:
			if abs(myx+64*ledge[1]-ledge[0].x) < 64:
				var myy = get_position().y
				if abs(myy-64-ledge[0].y) < 64:
					current_ledge = ledge	
					be("ledge")
		
func fallcap(on_ground):
	updatefloorstate()
	if on_ground:
		if !(state == "run" || state == "jumpstart" || state == "land"):
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
			
func respawn(place):
	if first_time_respawning:
		spawnposition = place
	motion = Vector2(0,0)
	self.position = place
	in_fast_fall = false
	has_double_jump = true
	has_airdodge = true
	on_floor = false
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
			false
		]
		input[0] = get_position().x < LEDGES[0][0].x
		input[1] = get_position().x > LEDGES[1][0].x
		input[2] = abs(get_position().x) > LEDGES[1][0].x && frame % 8 == 0

	else:
		input = [
			Input.is_action_pressed("right"),
			Input.is_action_pressed("left"),
			Input.is_action_pressed("jump"),
			Input.is_action_pressed("down"),
			Input.is_action_pressed("special"),
			Input.is_action_pressed("attack"),
			Input.is_action_pressed("shield"),
			false
		]
		
	for i in range(len(input)):
		new_input[i] = input[i] && !prev_input[i]
		
func interact():
	
	#SPACE OUT TWO IDLE CHARACTERS
	if intangibility_frame == 0:
		var i = 1
		for player in get_tree().get_root().get_node("World").get("players"):
			if !(i == playernumber):
				if ["idle", "run"].has(nextstate):
					if ["idle", "run"].has(player.state):
						var otherpos = player.get_position()
						var mypos = get_position()
						if abs(mypos.x - otherpos.x) < 128 && abs(mypos.y - otherpos.y) < 16:
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
					
					
					
				for h in player.get("hitboxes"):
					var them = player.get_position()
					var me = get_position() + hurtboxoffset
					var htl = h.topleft
					var hbr = h.bottomright
					var hcenter = Vector2((htl.x+hbr.x)/2,(htl.y+hbr.y)/2)
					var hsize = Vector2(abs(htl.x-hbr.x)/2, abs(htl.y-hbr.y)/2)
					var xdist = abs(me.x - (them.x + (hcenter.x*player.d)))
					var ydist = abs(me.y - (them.y + hcenter.y))
					if  xdist < (hurtboxsize.x + hsize.x) && ydist < (hurtboxsize.y + hsize.y):
						state = "hitstun"
						if player.d == 1:
							launch_direction = h.hitdirection
						else:
							launch_direction = 180-h.hitdirection
						frame = 0
						stage = 0
						damage += h.damage
						has_airdodge = true
						motion = Vector2(0,0)
						launch_knockback = damage * 30 * h.knockback + h.constknockback
						if launch_direction%360 < 90 || launch_direction%360 > 270:
							d = -1
						else:
							d = 1
							
						stun_length = 20+damage/10
						var hitlength = h.stun
						if hitlength > impact_frame:
							impact_frame = hitlength
						if hitlength > player.impact_frame:
							player.impact_frame = hitlength
						player.connected = true
						get_tree().get_root().get_node("World").IMPACTFRAME = hitlength
					
			i += 1
	
	

func hitbox(life, topleft, bottomright, hdamage, hitdirection, knockback, constknockback, stun):
	var hbox = HITBOX.instance()
	hbox.life = life
	hbox.topleft = topleft
	hbox.bottomright = bottomright
	hbox.damage = hdamage
	hbox.hitdirection = hitdirection
	hbox.knockback = knockback
	hbox.constknockback = constknockback
	hbox.stun = stun
	hbox.visible = get_tree().get_root().get_node("World").SHOWHITBOXES
	hitboxes.append(hbox)
	add_child(hbox)


func beFrame(aframe):
	$AnimationPlayer.stop()
	$Sprite.frame = aframe

func updateDirection():
	$Sprite.scale.x = d

func playerEffects():
	$Shield.visible = state == "shield"
	$Shield.scale.x = shield_size/SHIELDTIME
	$Shield.scale.y = shield_size/SHIELDTIME
	
	$Hurtbox.visible = get_tree().get_root().get_node("World").get("SHOWHITBOXES")
	
	Mat.set_shader_param("invincibility", invincibility_frame)
	Mat.set_shader_param("intangibility", intangibility_frame)

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

func sideair():
	movement()

func upair():
	movement()

func downair():
	movement()
