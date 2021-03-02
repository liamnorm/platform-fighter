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
					#hitbox(40, Vector2(-110, -10), Vector2(110, 10), 1, 0, 0, 0, 0, false)
					hitbox([
						{"del":0, 
						"len":40, 
						"t":-10, 
						"b":10, 
						"l":-110, 
						"r":110, 
						"dam":2, 
						"dir":0, 
						"kb":0, 
						"ckb":0, 
						"dohs":0,
						"hs":0, 
						"ss":0}
						])
			
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
	


func hitbox(boxes):
	var i = 0
	var hbox = HITBOX.instance()
	hbox.startframe = []
	hbox.life = 0
	hbox.boxlengths = []
	hbox.topleft = []
	hbox.bottomright = []
	hbox.damage = []
	hbox.hitdirection = []
	hbox.knockback = []
	hbox.constknockback = []
	hbox.stun = []
	hbox.shieldstun = []
	hbox.hitstun = []
	
	hbox.visible = Globals.SHOWHITBOXES
	hbox.players_to_ignore = []
	
	for b in boxes:
		hbox.boxlengths.append(b["len"])
		hbox.topleft.append(Vector2(b["l"], b["t"]))
		hbox.bottomright.append(Vector2(b["r"], b["b"]))
		hbox.damage.append(b["dam"])
		hbox.hitdirection.append(b["dir"])
		if b.has("kb"):
			hbox.knockback.append(b["kb"])
		else:
			hbox.knockback.append(1)
		if b.has("ckb"):
			hbox.constknockback.append(b["ckb"])
		else:
			hbox.constknockback.append(0)
		hbox.stun.append(b["hs"])
		hbox.shieldstun.append(b["ss"])
		if b.has("dohs"):
			hbox.hitstun.append(b["dohs"])
		else:
			hbox.hitstun.append(true)
		if b.has("del"):
			hbox.startframe.append(Globals.FRAME + b["del"])
			if hbox.life < b["len"] + b["del"]:
				hbox.life = b["len"] + b["del"]
		else:
			hbox.startframe.append(Globals.FRAME)
			if hbox.life < b["len"]:
				hbox.life = b["len"]
		i += 1
	hitboxes.append(hbox)
	add_child(hbox)
