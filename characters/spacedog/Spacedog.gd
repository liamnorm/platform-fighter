extends "res://characters/Player.gd"

onready var LASER = preload("res://projectiles/laser/Laser.tscn")
onready var BOMB = preload("res://projectiles/bomb/Bomb.tscn")

var new_laser

var direction = 0

func _ready():
	GRAVITY = 70
	MAXFALLSPEED = 1100
	JUMPFORCE = 1400
	DOUBLEJUMPFORCE = 1400
	SHORTJUMPFORCE = 1000

	MAXGROUNDSPEED = 1200
	ACCEL = 128
	FRICTION = 0.2

	MAXAIRSPEED = 600
	AIRACCEL = 32
	AIRFRICTION = 0.01
	FASTFALLSPEED = 1600
	
	SHIELDOFFSET = Vector2(0,8)
	
	HELDCOORDS = [
		#[61, 164],
		#[55, 154],
		
		#[185, 144],
		#[190, 138],
		
		[82, 156],
		[82, 148],
		
		[92, 148],
		[79, 150],
		[98, 126],
		[99, 147],

		#[188, 102],
		#[199, 135],
		#[191, 138],
		#[180, 137],
		
		#[57, 172],
		#[42, 153],
		#[61, 121],
		#[72, 159],
		
		[83, 167],
		[86, 148],
		
		[90, 148],
		
		[159, 143],
		[128, 172],
		[101, 123],
		[126, 90],
		
		[105, 109],
		
		#roll
		[126, 141],
		[158, 75],
		[118, 71],
		[78, 103],
		[69, 144],
		[113, 174], #handstand
		[187, 175],
		[155, 118],
		[116, 90],
		[79, 126],
		[84, 153],
		[86, 158],
		[86, 153],
		[82, 148],
		
		#hit
		[79, 145],
		[80, 135],
		[105, 125],
		[128, 136],
		[129, 178],
		[131, 143],
		[144, 178],
		
		#laser
		[99, 132],
		[95, 134],
		[76, 126],
		[82, 128],
		[92, 134],
		
		#jab
		[147, 131],
		[108, 123],
		[103, 119],
		[141, 119],
		
		#sideground
		[0, 0],
		[0, 0],
		[0, 0],
		[0, 0],
		[0, 0],
		
		#nair
		[74, 148],
		[174, 122],
		[196, 109],
		[0, 0],
		
		[138, 135],
		[138, 137],
		
	]
	
	hurtbox(40,58,0,12)
	
	

func neutralspecial():
	fallcap(on_floor)
	match stage:
		0:
			if frame == 1:
				playsound("BLASTERSTART")
			if input[0]:
				d = 1
			if input[1]:
				d = -1
			if frame == 0:
				new_laser = false
			if new_input[4]:
				new_laser = true
			if frame > 4:
				stage+= 1
				frame = 0
		1:
			if frame == 1:
				playsound("PEW")
			if frame == 2:
				var laser = LASER.instance()
				laser.position = get_position() + Vector2(d*220,-14)
				laser.d = d
				laser.frame = 0
				laser.playernumber = playernumber
				laser.skin = skin
				w.add_child(laser)
				w.projectiles.append(laser)
				laser.start()
				
				
			if new_input[4]:
				new_laser = true
			
			if frame > 7 && new_laser:
				new_laser = false
				stage = 1
				frame = 0
				
			if frame > 12:
				stage+= 1
				frame = 0
		2:
			buffer(on_floor)
			if frame > 4:
				if (on_floor):
					be("idle")
				else:
					be("jump")
					
func floating():
	in_fast_fall = false
	match stage:
		0:
			if frame > 8:
				motion.y = 0
			fallcap(on_floor)
			
			if frame > 14:
				stage = 1
				frame = 0
		1:
			motion.y = 0
			if input[0]:
				motion.x += 40
			if input[1]:
				motion.x -= 40
			motion.x = lerp(motion.x, 0, 0.01)
			motion.x = clamp(motion.x, -500, 500)
			if !input[4]:
				buffer(on_floor)
				if (on_floor):
					be("idle")
				else:
					be("jump")
		2:
			pass

func sidespecial():
	in_fast_fall = false
	match stage:
		0:
			shieldconnected = false
			fallcap(on_floor)
			if frame > 22:
				#hitbox(4, Vector2(-60,-30), Vector2(34, 30), 8, -85, 1, 0, 3, 11)
				hitbox([
					{"del":0, 
					"len":4, 
					"t":-50, 
					"b":60, 
					"l":-60, 
					"r":34, 
					"dam":8, 
					"dir":-85, 
					"kb":1, 
					"ckb":0, 
					"hs":3, 
					"ss":11}
					])
				stage+= 1
				frame = 0
			motion.y = 0
			motion.x = 0
		1:
			if !shieldconnected:
				motion.x = d * 10000
			else:
				motion.x = 0
			motion.y = 0
			# zoop
			
			var effect = EFFECT.instance()
			effect.position = get_position()
			effect.d = d
			effect.myframe = 0
			effect.playernumber = playernumber
			effect.skin = skin
			effect.effecttype = "foxside"
			w.add_child(effect)
			
			if frame > 3:
				var endspeed = 1600
				if (input[0] && d == 1) || (input[1] && d == -1):
					endspeed = 2600
				if (input[0] && d == -1) || (input[1] && d == 1):
					endspeed = 1000
				if !shieldconnected:
					motion.x = d * endspeed
				else:
					motion.x = 0
				stage+= 1
				frame = 0
		2:
			fallcap(on_floor)
			ledgesnap()
			buffer(on_floor)
			if frame < 5:
				motion.y = 0
			if frame > 22:
				if (on_floor):
					be("idle")
				else:
					be("jump")

func upspecial():
	match stage:
		0:
			shieldconnected = false
			in_fast_fall = false
			fallcap(on_floor)
			motion = Vector2(0,0)
			if frame == 1:
				direction = Vector2(0,-1)
				
				var effect = EFFECT.instance()
				effect.position = get_position()
				effect.d = d
				effect.myframe = 0
				effect.playernumber = playernumber
				effect.skin = skin
				effect.effecttype = "fire"
				w.add_child(effect)
			
			if frame %3 == 0 && frame > 12:
				#hitbox(1, Vector2(-48,-48), Vector2(48, 48), 1, -100, 0, 0, 1, 3)
				var s = 40
				hitbox([
					{"del":0, 
					"len":1, 
					"t":-s, 
					"b":s, 
					"l":-s, 
					"r":s, 
					"dam":1, 
					"dir":-100, 
					"kb":0, 
					"ckb":0, 
					"hs":1, 
					"ss":1}
					])
			
			var c = str(controller-1)
			if controller == 1:
				c = ""
			var up = "jump" + c
			var down = "down" + c
			var right = "right" + c
			var left = "left" + c
			var vert = 0 
			if controller > 0: 
				vert = Input.get_action_strength(down) - Input.get_action_strength(up)
			var hor = 0
			if controller > 0:
				hor = Input.get_action_strength(right) - Input.get_action_strength(left)
			if vert != 0 || hor != 0:
				direction = Vector2(hor, vert)
				direction *= 1/direction.length()
			elif input[2]:
				if input[0]:
					direction = Vector2(0.7,-0.7)
				elif input[1]:
					direction = Vector2(-0.7,-0.7)
				else:
					direction = Vector2(0,-1)
			elif input[3]:
				if input[0]:
					direction = Vector2(0.7,0.7)
				elif input[1]:
					direction = Vector2(-0.7,0.7)
				else:
					direction = Vector2(0,1)
			elif input[0]:
				direction = Vector2(1,0)
			elif input[1]:
				direction = Vector2(-1,0)
				
			
			if frame > 30:
				stage+= 1
				frame = 0
		1:
			
			if frame == 1:
				#FIRE!!
				#hitbox(10, Vector2(-48,-48), Vector2(48, 48), 13, -70, 1, 0, 4, 25)
				var launchd
				var newvect = direction + Vector2(d,1) * 0.1
				var la = int(newvect.angle()/3.14*180) 
				if d == 1:
					launchd = la
				else:
					if la % 360 <= 180:
						launchd = 180 - la
					else:
						launchd = -180 + la
						
				var s = 40
				hitbox([
					{"del":0, 
					"len":5, 
					"t":-s, 
					"b":s, 
					"l":-s, 
					"r":s, 
					"dam":7, 
					"dir":launchd, 
					"kb":1, 
					"ckb":0, 
					"hs":4, 
					"ss":13},
					
					{"del":5, 
					"len":16, 
					"t":-s, 
					"b":s, 
					"l":-s, 
					"r":s, 
					"dam":4, 
					"dir":launchd, 
					"kb":1, 
					"ckb":0, 
					"hs":2, 
					"ss":7}
					])
			if !shieldconnected:
				motion = 1600 * direction
			else:
				motion = Vector2(0,0)
			if frame > 21:
				if motion.y < -700:
					motion.y = -700
				stage+= 1
				frame = 0
			ledgesnap()
		2:
			movement()
			ledgesnap()
			landing_lag = 15
			if updatefloorstate():
				be("land")
				
func downspecial():
	movement()
	if frame == 7:
		var bomb = BOMB.instance()
		bomb.position = get_position() + Vector2(d*0,-14)
		bomb.d = d
		bomb.frame = 0
		bomb.playernumber = playernumber
		bomb.skin = skin
		bomb.holder = playernumber
		bomb.state = "held"
		heldobject = bomb
		w.add_child(bomb)
		w.projectiles.append(bomb)
		bomb.start()
		stage = 2
	if frame > 40:
		if (on_floor):
			be("idle")
		else:
			be("jump")

func neutralground():
	movement()
	match stage:
		0:	
			if frame == 1:
				connected = false
			if frame == 2:
				# jab
				#hitbox(1, Vector2(20,-15), Vector2(100, 15), 1, -35, 0.05, 100, 1, 0)
				hitbox([
					{"del":0, 
					"len":1, 
					"t":-15, 
					"b":15, 
					"l":20, 
					"r":100, 
					"dam":1, 
					"dir":15, 
					"kb":0.05, 
					"ckb":20, 
					"hs":1, 
					"ss":1}
					])
			if frame >= 4:
				if input[5]:
					frame = 0
				else:
					if connected:
						stage = 1
						frame = 0
					else:
						stage = 2
						frame = 0
		1:
			if frame == 4:
				#hitbox(2, Vector2(20,-15), Vector2(120, 40), 5, -45, 1, 0, 3, 8)
				hitbox([
					{"del":0, 
					"len":2, 
					"t":-15, 
					"b":40, 
					"l":20, 
					"r":120, 
					"dam":5, 
					"dir":-35, 
					"kb":.3, 
					"ckb":500, 
					"hs":3, 
					"ss":8}
					])
			if frame > 18:
				stage = 2
				frame = 0
		2:
			buffer(true)
			if frame > 5:
				be("idle")
	be_jump_if_in_midair()


func sideground():
	movement()
	if frame == 7:
		#hitbox(2, Vector2(20,-15), Vector2(120, 40), 6, -45, 1, 0, 5, 9)
		hitbox([
			{"del":0, 
			"len":2, 
			"t":-15, 
			"b":40, 
			"l":20, 
			"r":120, 
			"dam":6, 
			"dir":-45, 
			"kb":1, 
			"ckb":0, 
			"hs":5, 
			"ss":9}
			])
		stage = 2
	if frame > 24:
		buffer(true)
	if frame > 29:
		if input[0] || input[1]:
			be("run")
		else:
			be("idle")
	be_jump_if_in_midair()
			
func upground():
	movement()
	
	if frame == 4:
		hitbox([
			{"del":0, 
			"len":4, 
			"t":-75, 
			"b":50, 
			"l":-60, 
			"r":40, 
			"dam":7, 
			"dir":-85, 
			"kb":.3, 
			"ckb":600, 
			"hs":5, 
			"ss":8},
			
			{"del":4, 
			"len":4, 
			"t":-75, 
			"b":50, 
			"l":-60, 
			"r":30, 
			"dam":5, 
			"dir":-85, 
			"kb":.2, 
			"ckb":500, 
			"hs":2, 
			"ss":4}
			])
		stage = 2
	
	if frame > 14:
		buffer(true)
		
	if frame > 25:
		if input[0] || input[1]:
			be("run")
		else:
			be("idle")
	be_jump_if_in_midair()

func downground():
	getupattack()

func neutralair():
	landing_lag = 4
	movement()
	if frame == 1:
		playsound("VOICE")
	if frame == 4:
		throw(500, -600)

	if frame == 4:
		# nair
		hitbox([
			{"del":0, 
			"len":2, 
			"t":-15, 
			"b":60, 
			"l":-50, 
			"r":70, 
			"dam":7, 
			"dir":-25, 
			"kb":.7, 
			"ckb":0, 
			"hs":5, 
			"ss":8},
			
			{"del":2, 
			"len":16, 
			"t":-10, 
			"b":60, 
			"l":-40, 
			"r":65, 
			"dam":3, 
			"dir":-30, 
			"kb":.7, 
			"ckb":0, 
			"hs":2, 
			"ss":4}
			])
		stage = 2
		#hitbox(10, Vector2(-50,-15), Vector2(70, 60), 4, -60, 1, 0, 5, 8)
	if frame > 20:
		buffer(false)
	if frame > 30:
		if updatefloorstate():
			be("land")
		else:
			be("jump")
		
func forwardair():
	landing_lag = 14
	movement()
	if frame == 1:
		playsound("VOICE")
	elif frame == 12 && (input[5] || input[8] || input[9]):
		frame -= 1
		charging = true
		landing_lag = 12
	if frame == 12:
		throw(2000, -100)
		#FORWARD AERIAL.
		hitbox([
			{"del":3, 
			"len":1, 
			"t":-30, 
			"b":74, 
			"l":20, 
			"r":70, 
			"dam":11, 
			"dir":80, 
			"kb":1, 
			"ckb":0, 
			"hs":12, 
			"ss":15},
			
			{"del":0, 
			"len":2, 
			"t":-50, 
			"b":30, 
			"l":-50, 
			"r":50, 
			"dam":8, 
			"dir":-25, 
			"kb":1, 
			"ckb":0, 
			"hs":7, 
			"ss":12}
			])
		stage = 2
	elif frame > 30:
		buffer(false)
	if frame > 43:
		if updatefloorstate():
			be("land")
		else:
			be("jump")

func backair():
	landing_lag = 9
	movement()
	if frame == 1:
		playsound("VOICE")
	elif frame == 3 && (input[5] || input[8] || input[9]):
		frame -= 1
		charging = true
		landing_lag = 14
	if frame == 10:
		throw(-2000, -200)
		#hitbox(9, Vector2(-110,10), Vector2(0, 60), 10, -145, 1.2, 0, 6, 10
		hitbox([
			{"del":0, 
			"len":9, 
			"t":10, 
			"b":60, 
			"l":-110, 
			"r":0, 
			"dam":10, 
			"dir":-155, 
			"kb":1.1, 
			"ckb":0, 
			"hs":6, 
			"ss":10}
			])
		stage = 2
	if frame > 20:
		buffer(false)
	if frame > 30:
		if updatefloorstate():
			be("land")
		else:
			be("jump")

func upair():
	landing_lag = 4
	movement()
	if frame == 1:
		playsound("VOICE")
	if frame == 3:
		throw(0, -2000)
	if frame == 5:
		#hitbox(9, Vector2(-110,10), Vector2(0, 60), 10, -145, 1.2, 0, 6, 10)
		hitbox([
			{"del":0, 
			"len":3, 
			"t":-50, 
			"b":10, 
			"l":-20, 
			"r":90, 
			"dam":7, 
			"dir":-96, 
			"kb":.5, 
			"ckb":300, 
			"hs":4, 
			"ss":7},
			
			{"del":3, 
			"len":3, 
			"t":-60, 
			"b":20, 
			"l":-70, 
			"r":70, 
			"dam":7, 
			"dir":-88, 
			"kb":.5, 
			"ckb":300, 
			"hs":4, 
			"ss":7}
			])
		stage = 2
	if frame > 14:
		buffer(false)
	if frame > 24:
		if updatefloorstate():
			be("land")
		else:
			be("jump")
			
func downair():
	landing_lag = 11
	movement()
	if frame == 1:
		playsound("VOICE")
	if (frame % 2 == 1) && frame > 6 && frame < 24:
		#hitbox(9, Vector2(-110,10), Vector2(0, 60), 10, -145, 1.2, 0, 6, 10)
		hitbox([
			{"del":0, 
			"len":1, 
			"t":-0, 
			"b":80, 
			"l":-30, 
			"r":50, 
			"dam":1, 
			"dir":75, 
			"kb":.3, 
			"ckb":-300,
			"hs":1, 
			"ss":1}
			])
		stage = 2
	if frame > 30:
		buffer(false)
	if frame > 39:
		if updatefloorstate():
			be("land")
		else:
			be("jump")

func getupattack():
	
	if frame == 14:
		hitbox([
			{"del":0, 
			"len":2, 
			"t":0, 
			"b":70, 
			"l":-110, 
			"r":-50, 
			"dam":4, 
			"dir":-155, 
			"kb":.3, 
			"ckb":400,
			"hs":8, 
			"ss":6}
			])
	if frame == 20:
		hitbox([
			{"del":0, 
			"len":2, 
			"t":0, 
			"b":70, 
			"l":40, 
			"r":120, 
			"dam":4, 
			"dir":-45, 
			"kb":.3, 
			"ckb":350,
			"hs":7, 
			"ss":6}
			])
	if frame > 30:
		be("idle")


func drawPlayer():
	match state:
		"idle":
			beFrame(0+(frame/12)%2)
			hurtbox(40,54,0,10)
		"run":
			beFrame(2+((frame-1)/3)%4)
			hurtbox(40,58,0,12)
		"runend":
			beFrame(0)
			hurtbox(40,58,0,12)
		"turnaround":
			beFrame(4)
			hurtbox(40,58,0,12)
		"jumpstart":
			beFrame(7)
			hurtbox(40,54,0,14)
		"jump":
			if floating:
				ref = 90
				if float_frame < 16:
					beFrame(ref+(float_frame-1)/3)
				else:
					beFrame(ref+5)
			elif double_jump_frame > 0:
				beFrame(9+(frame/3)%4)
				hurtbox(40,40,0,0)
			else:
				beFrame(8)
				hurtbox(50,44,0,6)
		"land":
			beFrame(7)
			hurtbox(40,54,0,14)
		"crouch":
			beFrame(6)
			hurtbox(64,32,0,32)
#			ref = 115
#			match stage:
#				0:
#					if frame < 4:
#						beFrame(ref)
#						hurtbox(64,32,0,32)
#					else:
#						beFrame(ref+1)
#						hurtbox(64,32,0,32)
#				1:
#					beFrame(6)
#					hurtbox(64,32,0,32)
#				2:
#					if frame < 4:
#						beFrame(ref+1)
#						hurtbox(64,32,0,32)
#					else:
#						beFrame(ref)
#						hurtbox(64,32,0,32)
		"neutralspecial":
			ref = 35
			match stage:
				0:
					beFrame(ref+4)
				1:
					if frame < 5:
						beFrame(ref+0)
					elif frame < 9:
						beFrame(ref+2)
					elif frame < 15:
						beFrame(ref+3)
					else:
						beFrame(6)
				2:
					beFrame(6)
			hurtbox(40,54,0,10)
		"floating":
			ref = 90
			match stage:
				0:
					beFrame(ref+(frame-1)/3)
				1:
					beFrame(ref+5)
		"sidespecial":
			ref = 76
			if stage == 0:
				if frame < 10:
					beFrame(ref+(frame+3)/5)
				else: 
					if frame%8 < 4:
						beFrame(ref+3)
					else:
						beFrame(ref+4)
			elif stage == 1:
				beFrame(ref+3)
		"upspecial":
			beFrame(9+(frame/3)%4)
			hurtbox(40,40,0,0)
		
		"neutralground":
			ref = 40
			match stage:
				0:
					beFrame(ref+(frame-1)/1)
				1:
					beFrame(ref+3+(frame-1)/3)
				2:
					beFrame(6)
					
		"unusedsideground":
			ref = 49
			if frame < 5:
				beFrame(ref)
			elif frame < 16:
				beFrame(ref+1)
			elif frame < 18:
				beFrame(ref+2)
			elif frame < 20:
				beFrame(ref+3)
			else:
				beFrame(8)
		"sideground":
			ref = 40
			if frame < 24:
				beFrame(ref+2+(frame-1)/4)
			else:
				beFrame(1)
		
		"upground":
			ref = 117
			if frame < 3:
				beFrame(ref)
			elif frame < 5:
				beFrame(ref+1)
			elif frame < 20:
				beFrame(ref+2+(frame-5)/4)
			else:
				beFrame(1)
				
		"downground":
			ref = 152
			beFrame(ref+(frame/3))
		
		"neutralair":
			ref = 49
			if frame < 5:
				beFrame(ref)
			elif frame < 16:
				beFrame(ref+1)
			elif frame < 18:
				beFrame(ref+2)
			elif frame < 20:
				beFrame(ref+3)
			else:
				beFrame(8)
			hurtbox(40,54,0,10)
		"forwardair":
			ref = 55
			if frame < 19:
				beFrame(ref+(frame-1)/3)
			elif frame < 38:
				beFrame(ref+7)
			elif frame < 41:
				beFrame(ref+8)
			else:
				beFrame(ref+9)
		"backair":
			ref = 65
			if frame < 9:
				beFrame(ref+(frame-1)/5)
			elif frame == 9:
				beFrame(ref+2)
			elif frame < 19:
				beFrame(ref+3)
			elif frame < 24:
				beFrame(ref+4)
			else:
				beFrame(ref+5)
		"upair":
			ref = 81
			if frame < 30:
				beFrame(ref+(frame-1)/3)
		"downair":
			ref = 106
			if frame < 7:
				beFrame(ref+(frame-1)/2)
			elif frame < 30:
				beFrame(ref+3+((frame-1)/2)%4)
			elif frame < 35:
				beFrame(ref+7)
			else:
				beFrame(ref+8)
		"hitstun":
			beFrame(28)
			hurtbox(44,54,0,8)
		"hit":
			ref = 21
			match stage:
				0:
					if frame < 15:
						beFrame(29)
					else:
						beFrame(30)
					hurtbox(54,40,0,12)
				1:
					if floating:
						ref = 90
						if float_frame < 16:
							beFrame(ref+(float_frame-1)/3)
						else:
							beFrame(ref+5)
					else:
						ref = 131
						var s = [0, 1, 3, 4, 6, 7, 1, 2, 4, 5, 7, 0, 2, 3, 5, 6]
						beFrame(ref+(s[(frame/3)%16]))
		"knockeddown":
			ref = 31
			match stage:
				0:
					beFrame(ref+(frame-1)/6)
				1:
					beFrame(ref+3)
			hurtbox(64,24,0,40)
		"shield":
			beFrame(13)
		"roll":
			ref = 14
			if frame < totalrollframes-8:
				beFrame(ref+(float(frame)/(totalrollframes-8) * 14))
			else:
				beFrame(1)
		"spotdodge":
			ref = 71
			if frame < totalspotdodgeframes-8:
				beFrame(ref+(float(frame)/(totalspotdodgeframes-8) * 5))
			else:
				beFrame(1)
		"airdodge":
			ref = 96
			if frame < 9:
				beFrame(ref+((frame-1)/4))
			elif frame < 17:
				beFrame(ref+2)
			elif frame < 23:
				beFrame(ref+3)
			else:
				beFrame(ref+4+((frame-24)/6))
		"ledge":
			ref = 53
			beFrame(ref+(frame/12)%2)
			hurtbox(35,45,-30,48)
		"ledgegetup":
			ref = 124
			beFrame(ref+(frame/3))
		
		"respawn":
			beFrame(0)
			
		"dizzy":
			ref = 139
			beFrame(ref+(frame/12)%7)
		
		"shieldbreak":
			ref = 131
			var s = [0, 1, 3, 4, 6, 7, 1, 2, 4, 5, 7, 0, 2, 3, 5, 6]
			beFrame(ref+(s[(frame/3)%16]))
		"getup":
			ref = 146
			beFrame(ref+((frame-1)/4))
		"getupattack":
			ref = 152
			beFrame(ref+(frame/3))
			





