extends "res://projectiles/Projectile.gd"

var SPEED = 2500
var MAXSPEED = 5000

var Mat

func _ready():
	Mat = $Sprite.get_material()
	drawprojectile()


func projectilemovement():
			
	if frame == 0:
		hitboxes = []
		hitbox([
			{"del":0, 
			"len":40, 
			"t":-10, 
			"b":10, 
			"l":-110, 
			"r":110, 
			"dam":damage_delt, 
			"dir":0, 
			"kb":0, 
			"ckb":0, 
			"dohs":0,
			"hs":0, 
			"ss":0}
			])
			
	$CollisionShape2D.disabled = true
	intangibility_frame = 1000
	
	if motion.length()>MAXSPEED:
		motion = motion.normalized() * MAXSPEED

	
	if frame > 0:
		motion = move_and_slide(motion, UP)
	
	if connected:
		if state != "reflect":
			w.projectiles.erase(self)
			queue_free()
		
	frame += 1
	
	if frame == LIFESPAN:
		w.projectiles.erase(self)
	if frame > LIFESPAN:
		queue_free()
		
func drawprojectile():
	Mat.set_shader_param("skin", skin)

func start():
	LIFESPAN = 60
	motion = Vector2(d*SPEED, 0)
	important_to_camera = false
	shieldstun = 2
	hurtboxsize = Vector2(110,10)
	hurtboxoffset = Vector2(0,0)
	damage_delt = 2.0
	intangibility_frame = 1000
