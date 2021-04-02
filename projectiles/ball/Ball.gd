extends "res://projectiles/Projectile.gd"

var GRAVITY = 20
var MAXFALLSPEED = 750
var MAXAIRSPEED = 2000
const TRUEMAXSPEED = 10000

var Mat

func _ready():
	w = get_parent()

func projectilemovement():
	
	var y = get_position().y
	var x = get_position().x
	if (y > w.BOTTOMBLASTZONE || 
	(y < w.TOPBLASTZONE && state == "ooga boofghsa") || 
	abs(x) > w.SIDEBLASTZONE):
		if w.STAGE == 0 || (w.STAGE == 1 && y > 0):
			if x < -w.TRIPLEBLASTZONE:
				w.RIGHTSCORE += 1
				w.RIGHTSCOREFRAME = 120
				motion = Vector2(0,0)
				damage = 0
				
				if w.RIGHTSCORE > w.SCORETOWIN:
					w.GAMEENDFRAME = 1
					Globals.WINNER = 2
			elif x > w.TRIPLEBLASTZONE:
				w.LEFTSCORE += 1
				w.LEFTSCOREFRAME = 120
				motion = Vector2(0,0)
				damage = 0
				if w.LEFTSCORE > w.SCORETOWIN:
					w.GAMEENDFRAME = 1
					Globals.WINNER = 1
			else:
				pass
		respawn(Vector2(0,w.TOPBLASTZONE))
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
			motion.x = lerp(motion.x, 0, 0)
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
			
	motion.y += GRAVITY
	
	motion.x = clamp(motion.x, -TRUEMAXSPEED, TRUEMAXSPEED)
	motion.y = clamp(motion.y, -TRUEMAXSPEED, TRUEMAXSPEED)
	
	var collision = move_and_collide(motion*0.0166)
	if collision:
		if (collision.collider.get_node_or_null("Collision") != null):
			if collision.collider.get_node("Collision").one_way_collision:
				if motion.y > 0:
					motion.y = -motion.y
					motion = motion*1
		else:
			if motion.length() > 500:
				motion = motion.bounce(collision.normal)
				motion = motion*1
	shieldstun = 14

func start():
	hurtboxsize = Vector2(32,32)
	hurtboxoffset = Vector2(0,0)
	LAUNCH_THRESHOLD = 500
	damage = 0
	shieldstun = 14
	
	Mat = $Sprite.get_material()
	Mat.set_shader_param("skin", skin)
	
func drawprojectile():
#	if state == "hitstun":
#		$Sprite.rotation = motion.angle()
#		var stretch = 1 - (launch_knockback/1000)
#		stretch = clamp(stretch, 0.8, 1)
#		$Sprite.scale = Vector2(stretch,1/stretch)
#	elif state == "hit" && stun_length > 0 && frame != 0:
#		$Sprite.rotation = motion.angle()
#		var stretch = 1 + ((launch_knockback/1000) * (float(stun_length-frame)/stun_length))
#		stretch = clamp(stretch, 1, 1.5)
#		$Sprite.scale = Vector2(stretch,1/stretch)
#	else:
#		$Sprite.rotation += motion.length()/1000
#		$Sprite.scale = Vector2(1,1)
#		$Sprite.rotation = motion.angle()
	$Sprite.rotation += motion.length()/1000
	$Sprite.scale = Vector2(1,1)
	
	Mat.set_shader_param("outline_col", Color((damage-20)/20.0, 0, 0, 1))
	Mat.set_shader_param("invincibility", invincibility_frame)
	Mat.set_shader_param("intangibility", intangibility_frame)
	Mat.set_shader_param("skin", skin)
	
	var rage = clamp((damage-20)/20.0, 0, 20)
	$Sprite.position = Vector2(randi() %2 * rage - rage/2, randi() %2 * rage - rage/2)

func respawn(place):
	spawnposition = place
	position = place
	d = 0
	damage = 0
