extends KinematicBody2D

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
var ROLLSPEED = 200
var ROLLFRAMES = 20


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

var motion = Vector2()

var d = 1
var has_double_jump = true
var in_fast_fall = false
var shield_size = SHIELDTIME
var damage = 0
var invincibility_frame = 0
var first_time_at_ledge = true

var input =     [false,false,false,false,false,false,false,false]
var new_input = [false,false,false,false,false,false,false,false]
var input_lengths = [0,0,0,0,0,0,0,0]

func _ready():
	LEDGES = get_tree().get_root().get_node("World").get("LEDGES")
	
func _physics_process(_delta):
	
	get_input()
	
	if self.position.y > 1080:
		respawn(Vector2(0,-512))
	
	if !state == "ledge":
		motion.y += GRAVITY
	
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
						be("getup")
					else:
						be("jump")
				elif input[1]:
					if current_ledge[1] == -1:
						ledge_x = current_ledge[0].x + current_ledge[1] * 64
						ledge_y = current_ledge[0].y - 64
						set_position(Vector2(ledge_x, ledge_y))
						be("getup")
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
		
		"getup":
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
			movement()
		"roll":
			var speedmodifier = pow(ROLLFRAMES - abs(frame-(ROLLFRAMES/4)),2)/50
			motion.x = -ROLLSPEED * d * speedmodifier
			if frame > ROLLFRAMES:
				motion.x = 0
				buffer(true)
				if frame > ROLLFRAMES+8:
					be("idle")
		"spotdodge":
			movement()

	motion = move_and_slide(motion, UP)

	if frame > 60 && !(state == "jump") && !input.has(true) && !(state == "ledge"):
		nextstate = "idle"
		
	shield_size += 1
	shield_size = clamp(shield_size, 0, SHIELDTIME)
	
	#DRAW
	frame += 1
	frames_since_ledge += 1
	invincibility_frame -= 1
	invincibility_frame = max(invincibility_frame, 0)
	
	state = nextstate
	
	
	updateDirection()
	playerEffects()
	drawPlayer()






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


func movement():
	if is_on_floor() && on_floor == false:
		on_floor = true
		has_double_jump = true
		first_time_at_ledge = true
		if ["jump", "neutralair", "sideair", "upair", "downair", "airdodge"].has(state):
			be("land")
	if !is_on_floor() && on_floor == true:
		on_floor = false
		if ["run", "idle", "crouch", "land"].has(state):
			be("jump")
	if on_floor:
		if !(state == "run" || state == "jumpstart" || state == "land"):
			motion.x = lerp(motion.x,0,FRICTION)
		motion.x = clamp(motion.x,-MAXGROUNDSPEED,MAXGROUNDSPEED)
	else:
		if input[0]:
			motion.x += AIRACCEL
		elif input[1]:
			motion.x -= AIRACCEL
		else:
			motion.x = lerp(motion.x,0,AIRFRICTION)
			
		if new_input[3]:
			in_fast_fall = true
			motion.y = FASTFALLSPEED

		if in_fast_fall:
			motion.y = FASTFALLSPEED
		else:
			if motion.y > MAXFALLSPEED:
				motion.y = MAXFALLSPEED
		
		if frames_since_ledge > 30:
			var myx = get_position().x
			for ledge in LEDGES:
				if abs(myx+64*ledge[1]-ledge[0].x) < 64:
					var myy = get_position().y
					if abs(myy-64-ledge[0].y) < 64:
						current_ledge = ledge	
						be("ledge")
		
		motion.x = clamp(motion.x,-MAXAIRSPEED,MAXAIRSPEED)
	
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
	motion = Vector2(0,0)
	self.position = place
	in_fast_fall = false
	has_double_jump = true
	on_floor = false
	$Sprite.scale.x = 1
	bufferedstate = "none"
	buffereddirection = "none"
	buffering = false
	invincibility_frame = 180
	first_time_at_ledge = true
	damage = 0
	be("jump")
	
	Mat = $Sprite.get_material()
	Mat.set_shader_param("skin", skin)


func get_input():
	if controller == 0:
		for i in range(6):
			#input_lengths[i]+= 1
			#if i==1:
			#	input[1] = !input[0]
			if (input_lengths[i] > randi()%50 + 30):
				input[i] = !input[i]
				input_lengths[i] = 0
				new_input[i] = true
			else:
				new_input[i] = false
	else:
		new_input = [
			Input.is_action_just_pressed("right"),
			Input.is_action_just_pressed("left"),
			Input.is_action_just_pressed("jump"),
			Input.is_action_just_pressed("down"),
			Input.is_action_just_pressed("special"),
			Input.is_action_just_pressed("attack"),
			Input.is_action_just_pressed("shield"),
			0
		]
		
		input = [
			Input.is_action_pressed("right"),
			Input.is_action_pressed("left"),
			Input.is_action_pressed("jump"),
			Input.is_action_pressed("down"),
			Input.is_action_pressed("special"),
			Input.is_action_pressed("attack"),
			Input.is_action_pressed("shield"),
			0
		]


func beFrame(aframe):
	$AnimationPlayer.stop()
	$Sprite.frame = aframe

func updateDirection():
	if d == 1:
		$Sprite.scale.x = 1
	else:
		$Sprite.scale.x = -1

func playerEffects():
	$Shield.visible = state == "shield"
	$Shield.scale.x = shield_size/SHIELDTIME
	$Shield.scale.y = shield_size/SHIELDTIME
	
	Mat.set_shader_param("invincibility", invincibility_frame)


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
