extends "res://projectiles/Projectile.gd"

var GRAVITY = 20
var MAXFALLSPEED = 750
var MAXAIRSPEED = 2000
const TRUEMAXSPEED = 10000

func _ready():
	pass

func projectilemovement():
	
	var y = get_position().y
	var x = get_position().x
	if (y > Globals.BOTTOMBLASTZONE || 
	(y < Globals.TOPBLASTZONE && state == "ooga boofghsa") || 
	abs(x) > Globals.SIDEBLASTZONE):
		if x < -Globals.TRIPLEBLASTZONE:
			Globals.RIGHTSCORE += 1
			Globals.RIGHTSCOREFRAME = 120
		elif x > Globals.TRIPLEBLASTZONE:
			Globals.LEFTSCORE += 1
			Globals.LEFTSCOREFRAME = 120
		else:
			pass
		respawn(Vector2(0,Globals.TOPBLASTZONE))
	if y < Globals.TOPBLASTZONE:
		motion.y = 0
		position.y = Globals.TOPBLASTZONE
	
	match state:
		"hitstun":
			motion = Vector2(0,0)
			if frame > 0:
				motion = Vector2(cos(launch_direction * PI/180), sin(launch_direction * PI/180)) 
				motion *= launch_knockback
				nextstate = "hit"
				frame = 0
				stage = 0
		"hit":
			motion.x = lerp(motion.x, 0, .04)
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
				get_tree().get_root().add_child(effect)
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
		motion = motion.bounce(collision.normal)

func start():
	hurtboxsize = Vector2(32,32)
	hurtboxoffset = Vector2(0,0)
	LAUNCH_THRESHOLD = 500
	damage = 0
	shieldstun = 4
	
func drawprojectile():
	$Sprite.rotation += motion.length()/1000

func respawn(place):
	spawnposition = place
	position = place
	motion = Vector2(0,0)
	damage = 0
	d = 0
