extends "res://projectiles/Projectile.gd"

var GRAVITY = 20
var MAXFALLSPEED = 750
var MAXAIRSPEED = 2000
const TRUEMAXSPEED = 10000

var Mat
var prevcollision = false

func _ready():
	w = get_parent()

func projectilemovement():
	
	var y = get_position().y
	var x = get_position().x
	if (y > w.BOTTOMBLASTZONE || 
	(y < w.TOPBLASTZONE && state == "ooga boofghsa") || 
	abs(x) > w.SIDEBLASTZONE):
		w.projectiles.erase(self)
		queue_free()
	if y < w.TOPBLASTZONE:
		motion.y = 0
		position.y = w.TOPBLASTZONE
	
	match state:
		"hitstun":
			motion = Vector2(0,0)
			if frame > 0:
				motion = Vector2(cos(launch_direction * PI/180), sin(launch_direction * PI/180)) 
				motion *= launch_knockback
				motion += hitter_motion * 0.5
				nextstate = "hit"
				frame = 0
				stage = 0
		"hit":
			if frame > stun_length:
				nextstate = "idle"
				stage = 0
				frame = 0
				
			if motion.length() > LAUNCH_THRESHOLD:
				var effect = EFFECT.instance()
				effect.position = get_position()
				effect.d = d
				effect.myframe = 0
				effect.playernumber = player_who_last_hit_me
				effect.effecttype = "launch"
				w.add_child(effect)
		"reflect":
			if frame > 8:
				nextstate = "hit"
				frame = 0
				stage = 0
		"idle":
			motion.x = clamp(motion.x, -MAXAIRSPEED, MAXAIRSPEED)
			motion.x = lerp(motion.x, 0, .005)
			motion.y = lerp(motion.y, 0, .005)
			
	if holder > 0:
		motion.y += GRAVITY
	
		motion.x = clamp(motion.x, -TRUEMAXSPEED, TRUEMAXSPEED)
		motion.y = clamp(motion.y, -TRUEMAXSPEED, TRUEMAXSPEED)
		
		if prevcollision:
			motion.y = 0
		prevcollision = false
		var collision = move_and_collide(motion*0.0166)
		if collision:
			if (collision.collider.get_node_or_null("Collision") != null):
				if collision.collider.get_node("Collision").one_way_collision:
					if motion.y > 0:
						motion.y = -motion.y
						prevcollision = true
			else:
				if motion.length() > 100:
					motion.y = -.5 * motion.y
					prevcollision = false
				else:
					motion = motion.bounce(collision.normal)
					prevcollision = true
	shieldstun = 11

func start():
	hurtboxsize = Vector2(24,24)
	hurtboxoffset = Vector2(0,0)
	LAUNCH_THRESHOLD = 500
	damage = 0
	shieldstun = 14
	
	#Mat = $Sprite.get_material()
	#Mat.set_shader_param("skin", skin)
	
func drawprojectile():

	$Sprite.rotation += motion.length()/1000
	$Sprite.scale = Vector2(1,1)
	
	#Mat.set_shader_param("outline_col", Color((damage-20)/20.0, 0, 0, 1))
	#Mat.set_shader_param("invincibility", invincibility_frame)
	#Mat.set_shader_param("intangibility", intangibility_frame)
	#Mat.set_shader_param("skin", skin)
	
	var rage = clamp((damage-20)/20.0, 0, 20)
	var randox = (randi() %10 - 5) / 5
	var randoy = (randi() %10 - 5) / 5
	$Sprite.position = Vector2(randox * rage - rage/2, randoy * rage - rage/2)
	
	$Sprite.frame = (frame/15)%2

func respawn(place):
	motion = Vector2(0,0)
	spawnposition = place
	position = place
	d = 0
	damage = 0
