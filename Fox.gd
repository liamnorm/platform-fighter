extends "res://Player.gd"

onready var LASER = preload("res://projectiles/laser/Projectile.tscn")

func _ready():
	GRAVITY = 70
	MAXFALLSPEED = 1200
	JUMPFORCE = 1300
	DOUBLEJUMPFORCE = 1300
	SHORTJUMPFORCE = 1000

	MAXGROUNDSPEED = 1200
	ACCEL = 256
	FRICTION = 0.5

	MAXAIRSPEED = 700
	AIRACCEL = 64
	AIRFRICTION = 0.5
	FASTFALLSPEED = 1400
	
var laser

func neutralspecial():
	movement()
	match stage:
		0:
			if frame > 2:
				stage+= 1
				frame = 0
		1:
			if frame%12 == 2:
				laser = LASER.instance()
				laser.position = get_position() + Vector2(d*140,-14)
				laser.d = d
				laser.frame = 0
				laser.player = playernumber
				get_tree().get_root().add_child(laser)
				laser.start()
			if (frame > 0 && frame%16 == 0) && !input[4]:
				stage+= 1
				frame = 0
		2:
			buffer(on_floor)
			if frame > 8:
				if (on_floor):
					be("idle")
				else:
					be("jump")

func sidespecial():
	match stage:
		0:
			movement()
			if frame > 22:
				stage+= 1
				frame = 0
			motion.y = 0
			motion.x = 0
		1:
			motion.x = d * 7000
			motion.y = 0
			
			if frame > 4:
				motion.x = d * 1000
				stage+= 1
				frame = 0
		2:
			movement()
			buffer(on_floor)
			if frame > 27:
				if (on_floor):
					be("idle")
				else:
					be("jump")








func drawPlayer():
	match state:
		"idle":
			$AnimationPlayer.play("Idle")
		"run":
			$AnimationPlayer.play("Walk")
		"jumpstart":
			beFrame(7)
		"jump":
			beFrame(8)
		"land":
			beFrame(7)
		"crouch":
			beFrame(6)
		"neutralspecial":
			match stage:
				0:
					beFrame(8)
				1:
					$AnimationPlayer.play("NeutralSpecial")
				2:
					beFrame(6)
		"roll":
			beFrame(6)
