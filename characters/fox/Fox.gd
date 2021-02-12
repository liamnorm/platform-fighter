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
			motion.x = d * 7000
			motion.y = 0
			hitbox(2, Vector2(-64,-64), Vector2(64, 64), 8, -85, 1, 0, 0)
			
			if frame > 4:
				motion.x = d * 1000
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
			motion = 1500 * direction
			if frame > 19:
				motion.y = -500
				stage+= 1
				frame = 0
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
			if frame == 4:
				hitbox(2, Vector2(50,-15), Vector2(100, 15), 2, -60, 0.02, 0, 0)
			if frame >= 9:
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
				hitbox(2, Vector2(80,-15), Vector2(120, 40), 5, -45, 1, 0, 3)
			if frame > 18:
				stage = 2
				frame = 0
		2:
			buffer(true)
			if frame > 5:
				be("idle")

func drawPlayer():
	match state:
		"idle":
			beFrame(0+(frame/12)%2)
		"run":
			beFrame(2+((frame-1)/3)%4)
		"jumpstart":
			beFrame(7)
		"jump":
			beFrame(8)
		"land":
			beFrame(7)
		"crouch":
			beFrame(6)
		"neutralspecial":
			ref = 27
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
			ref = 32
			match stage:
				0:
					beFrame(ref+(frame-1)/4)
				1:
					beFrame(ref+3+(frame-1)/3)
				2:
					beFrame(6)
					
		"hitstun":
			beFrame(20)
		"hit":
			match stage:
				0:
					if frame < 15:
						beFrame(21)
					else:
						beFrame(22)
				1:
					beFrame(9+(frame/3)%4)
		"knockeddown":
			match stage:
				0:
					beFrame(23+(frame-1)/6)
				1:
					beFrame(26)
		"shield":
			beFrame(13)
		"roll":
			if frame < 18:
				beFrame(14+frame/3)
			else:
				beFrame(0)
