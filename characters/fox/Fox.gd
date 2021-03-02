extends "res://characters/Player.gd"

onready var LASER = preload("res://projectiles/laser/Projectile.tscn")

var new_laser

var direction

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
	
	hurtboxsize = Vector2(40,58)
	hurtboxoffset = Vector2(0,12)
	

func laser():
	fallcap(on_floor)
	match stage:
		0:
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
			if frame == 2:
				var laser = LASER.instance()
				laser.position = get_position() + Vector2(d*220,-14)
				laser.d = d
				laser.frame = 0
				laser.player = playernumber
				get_tree().get_root().add_child(laser)
				Globals.projectiles.append(laser)
				laser.start()
				
			if new_input[4]:
				new_laser = true
			
			if frame > 7 && new_laser:
				new_laser = false
				stage = 1
				frame = 0
				
			if frame > 16:
				stage+= 1
				frame = 0
		2:
			buffer(on_floor)
			if frame > 5:
				if (on_floor):
					be("idle")
				else:
					be("jump")
					
func neutralspecial():
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
			motion.x = d * 10000
			motion.y = 0
			# zoop
			
			if frame > 3:
				var endspeed = 1600
				if (input[0] && d == 1) || (input[1] && d == -1):
					endspeed = 2600
				if (input[0] && d == -1) || (input[1] && d == 1):
					endspeed = 1000
				motion.x = d * endspeed
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
			in_fast_fall = false
			fallcap(on_floor)
			motion = Vector2(0,0)
			if frame == 1:
				direction = Vector2(0,-1)
			
			if frame %3 == 0:
				#hitbox(1, Vector2(-48,-48), Vector2(48, 48), 1, -100, 0, 0, 1, 3)
				hitbox([
					{"del":0, 
					"len":1, 
					"t":-48, 
					"b":48, 
					"l":-48, 
					"r":48, 
					"dam":1, 
					"dir":-100, 
					"kb":.5, 
					"ckb":0, 
					"hs":1, 
					"ss":3}
					])
			
			if input[2]:
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
				if d == 1:
					launchd = int(direction.angle()/3.14*180) 
				else:
					if int(direction.angle()/3.14*180) % 360 <= 180:
						launchd = 180 - int(direction.angle()/3.14*180)
					else:
						launchd = -180 + int(direction.angle()/3.14*180)
				hitbox([
					{"del":0, 
					"len":10, 
					"t":-48, 
					"b":48, 
					"l":-48, 
					"r":48, 
					"dam":13, 
					"dir":launchd, 
					"kb":1, 
					"ckb":0, 
					"hs":4, 
					"ss":25}
					])
			motion = 1600 * direction
			if frame > 21:
				if direction == Vector2(0,-1):
					motion.y = -700
				stage+= 1
				frame = 0
			ledgesnap()
		2:
			movement()
			ledgesnap()
			if updatefloorstate():
				be("land")

func downspecial():
	in_fast_fall = false
	match stage:
		0:
			motion.y = lerp(motion.y, pow(frame-10, 2)/1.0, 0.9)
			fallcap(on_floor)
			
			if !input[4]:
				buffer(on_floor)
				if (on_floor):
					be("idle")
				else:
					be("jump")
		1:
			pass
		2:
			pass

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
					"dir":-35, 
					"kb":0.05, 
					"ckb":100, 
					"hs":1, 
					"ss":0}
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
					"dir":-45, 
					"kb":1, 
					"ckb":0, 
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
	if frame > 24:
		buffer(true)
	if frame > 29:
		if input[0] || input[1]:
			be("run")
		else:
			be("idle")

func neutralair():
	landing_lag = 7
	movement()
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
			"dir":-35, 
			"kb":1, 
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
			"dir":-40, 
			"kb":.7, 
			"ckb":0, 
			"hs":2, 
			"ss":4}
			])
		#hitbox(10, Vector2(-50,-15), Vector2(70, 60), 4, -60, 1, 0, 5, 8)
	if frame > 30:
		if updatefloorstate():
			be("land")
		else:
			be("jump")
		
func forwardair():
	landing_lag = 17
	movement()
	if frame == 12:
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
	if frame == 16:
		pass
		#hitbox(3, Vector2(-20,-5), Vector2(85, 64), 4, 80, 1, 0, 4, 5)
	if frame > 43:
		if updatefloorstate():
			be("land")
		else:
			be("jump")

func backair():
	landing_lag = 9
	movement()
	if frame == 10:
		#hitbox(9, Vector2(-110,10), Vector2(0, 60), 10, -145, 1.2, 0, 6, 10
		hitbox([
			{"del":0, 
			"len":9, 
			"t":10, 
			"b":60, 
			"l":-110, 
			"r":0, 
			"dam":10, 
			"dir":-145, 
			"kb":1.1, 
			"ckb":0, 
			"hs":6, 
			"ss":10}
			])
	if frame > 30:
		if updatefloorstate():
			be("land")
		else:
			be("jump")

func upair():
	landing_lag = 7
	movement()
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
			"dir":-88, 
			"kb":.9, 
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
			"kb":.9, 
			"ckb":300, 
			"hs":4, 
			"ss":7}
			])
	if frame > 28:
		if updatefloorstate():
			be("land")
		else:
			be("jump")
			
func downair():
	landing_lag = 13
	movement()
	if (frame % 2 == 1) && frame > 6 && frame < 24:
		#hitbox(9, Vector2(-110,10), Vector2(0, 60), 10, -145, 1.2, 0, 6, 10)
		hitbox([
			{"del":0, 
			"len":1, 
			"t":-0, 
			"b":100, 
			"l":-30, 
			"r":50, 
			"dam":1, 
			"dir":75, 
			"kb":0, 
			"ckb":-3,
			"hs":1, 
			"ss":2}
			])
	if frame > 48:
		if updatefloorstate():
			be("land")
		else:
			be("jump")


func drawPlayer():
	match state:
		"idle":
			beFrame(0+(frame/12)%2)
		"run":
			beFrame(2+((frame-1)/3)%4)
		"runend":
			beFrame(6)
		"turnaround":
			beFrame(4)
		"jumpstart":
			beFrame(7)
		"jump":
			beFrame(8)
		"land":
			beFrame(7)
		"crouch":
			beFrame(6)
		"laser":
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
		"neutralspecial":
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
			else:
				beFrame(ref+7)
		"hitstun":
			beFrame(28)
		"hit":
			ref = 21
			match stage:
				0:
					if frame < 15:
						beFrame(29)
					else:
						beFrame(30)
				1:
					beFrame(9+(frame/3)%4)
		"knockeddown":
			ref = 31
			match stage:
				0:
					beFrame(ref+(frame-1)/6)
				1:
					beFrame(ref+3)
		"shield":
			beFrame(13)
		"roll":
			ref = 14
			if frame < 30:
				beFrame(ref+(frame-1)/2)
			else:
				beFrame(1)
		"spotdodge":
			ref = 71
			if frame < 20 :
				beFrame(ref+((frame-1)/4))
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
