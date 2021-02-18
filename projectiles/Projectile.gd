extends KinematicBody2D

onready var HITBOX = preload("res://characters/Hitbox.tscn")

const SPEED = 3000
const LIFESPAN = 60

var frame = 0
var player = 0
var motion = Vector2(0,0)
var d = 1
var hitboxes = []
var state = "projectile"
var projectiletype = "laser"

var connected = false
var impact_frame = 0

var players_to_ignore = []

var UP = Vector2(0,-1)

func _ready():
	pass # Replace with function body.


func _physics_process(_delta):
	
	var paused = Globals.PAUSED
	var framechange = Input.is_action_just_pressed("nextframe")
	if ((!paused) || framechange) && impact_frame == 0:
		

		match projectiletype:
			"laser":
				motion = Vector2(d*SPEED, 0)
			
				if frame == 0:
					hitbox(40, Vector2(-64, -10), Vector2(64, 10), 1, 0, 0, 0, 0, false)
			
				$CollisionShape2D.disabled = true
				motion = move_and_slide(motion, UP)
				
				if connected:
					Globals.projectiles.erase(self)
					queue_free()
				
				
				
		frame += 1
		
		if frame == LIFESPAN:
			Globals.projectiles.erase(self)
		if frame > LIFESPAN:
			queue_free()
			
			
	impact_frame -= 1
	if impact_frame < 0:
		impact_frame = 0
	
func start():
	pass
	


func hitbox(life, topleft, bottomright, hdamage, hitdirection, knockback, constknockback, stun, hitstun=true):
	var hbox = HITBOX.instance()
	hbox.life = life
	hbox.topleft = topleft
	hbox.bottomright = bottomright
	hbox.damage = hdamage
	hbox.hitdirection = hitdirection
	hbox.knockback = knockback
	hbox.constknockback = constknockback
	hbox.stun = stun
	hbox.players_to_ignore = []
	hbox.visible = Globals.SHOWHITBOXES
	hbox.hitstun = hitstun
	hitboxes.append(hbox)
	add_child(hbox)
