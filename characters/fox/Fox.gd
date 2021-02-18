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

	MAXAIRSPEED = 500
	AIRACCEL = 32
	AIRFRICTION = 0.01
	FASTFALLSPEED = 1600
	
	hurtboxsize = Vector2(40,58)
	hurtboxoffset = Vector2(0,12)
	

func neutralspecial():
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
				laser.position = get_position() + Vector2(d*140,-14)
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

func sidespecial():
	in_fast_fall = false
	match stage:
		0:
			fallcap(on_floor)
			if frame > 22:
				stage+= 1
				frame = 0
			motion.y = 0
			motion.x = 0
		1:
			motion.x = d * 10000
			motion.y = 0
			# zoop
			if frame == 1:
				hitbox(3, Vector2(-60,-30), Vector2(34, 30), 8, -85, 1, 0, 0)
			
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
			if frame > 22:
				if (on_floor):
					be("idle")
				else:
					be("jump")

func upspecial():
	in_fast_fall = false
	match stage:
		0:
			fallcap(on_floor)
			motion = Vector2(0,0)
			if frame == 1:
				direction = Vector2(0,-1)
			
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
				hitbox(10, Vector2(-48,-48), Vector2(48, 48), 6, -70, 1, 0, 0)
			motion = 1600 * direction
			if frame > 21:
				if direction == Vector2(0,-1):
					motion.y = -700
				stage+= 1
				frame = 0
			ledgesnap()
		2:
			movement()
			if updatefloorstate():
				be("land")

func downspecial():
	in_fast_fall = false
	match stage:
		0:
			motion.y = lerp(motion.y, pow(frame-10, 2)/1.0, 0.9)
			motion.x = lerp(motion.x, 0, 1)
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
				hitbox(1, Vector2(20,-15), Vector2(100, 15), 0.4, -35, 0.05, 100, 1)
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
				hitbox(2, Vector2(20,-15), Vector2(120, 40), 5, -45, 1, 0, 3)
			if frame > 18:
				stage = 2
				frame = 0
		2:
			buffer(true)
			if frame > 5:
				be("idle")

func unusedsideground():
	movement()
	if frame < 5:
		motion.x = 700 * d
	elif frame < 23:
		motion.x = (23-frame) * 100 * d
	if frame == 10:
		hitbox(2, Vector2(80,-15), Vector2(120, 40), 5, -45, 1, 0, 3)
	if frame > 32:
		buffer(true)
	if frame > 32:
		if input[0] || input[1]:
			be("run")
		else:
			be("idle")

func sideground():
	movement()
	if frame == 7:
		hitbox(2, Vector2(20,-15), Vector2(120, 40), 6, -45, 1, 0, 5)
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
		#hitbox(7, Vector2(-50,15), Vector2(70, 60), 4, -60, 1, 0, 0)
		#hitbox(7, Vector2(-50,-30), Vector2(40, 20), 4, -60, 1, 0, 0)
		hitbox(10, Vector2(-50,-15), Vector2(70, 60), 4, -60, 1, 0, 5)
	if frame > 30:
		if updatefloorstate():
			be("land")
		else:
			be("jump")
		
func forwardair():
	landing_lag = 17
	movement()
	if frame == 15:
		#FORWARD AERIAL.
		hitbox(1, Vector2(-20,-30), Vector2(90, 74), 11, 80, 1, 0, 12)
	if frame == 16:
		pass
		#hitbox(3, Vector2(-20,-5), Vector2(85, 64), 4, 80, 1, 0, 4)
	if frame > 43:
		if updatefloorstate():
			be("land")
		else:
			be("jump")

func backair():
	movement()
	if frame == 10:
		#FORWARD AERIAL.
		hitbox(9, Vector2(-110,10), Vector2(0, 60), 7, -135, 1, 0, 6)
	if frame > 30:
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
		"upspecial":
			beFrame(9+(frame/3)%4)
			
		"downspecial":
			beFrame(13)
		
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
				beFrame(ref+5)
		"spotdodge":
			ref = 71
			beFrame(ref+(frame/4))
		"ledge":
			ref = 53
			beFrame(ref+(frame/12)%2)
