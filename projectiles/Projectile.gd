extends KinematicBody2D

onready var HITBOX = preload("res://characters/Hitbox.tscn")
onready var EFFECT = preload("res://resources/ImpactEffect.tscn")

var LIFESPAN = 60

var frame = 0
var stage = 0
var playernumber = 0
var motion = Vector2(0,0)
var d = 1
var hitboxes = []
var state = "idle"
var nextstate = "idle"
var projectiletype = "laser"
var important_to_camera = true
var spawnposition = Vector2(0,-512)
var bounceoffshield = true
var shieldstun = 0
var hitter_motion = Vector2(0,0)
var skin = 0

var holdable = false
var holder = 0

var team = 0

#variables that are required to exist for 
#interaction, but optional
var intangibility_frame = 0
var invincibility_frame = 0
var damage = 0
var launch_direction = 0
var player_who_last_hit_me = 0
var launch_knockback = 0
var LAUNCH_THRESHOLD = 0
var combo = 0
var stun_length = 0
var damage_delt = 0
var rageoffset = Vector2(0,0)

const is_projectile = true

var has_hurtbox = false
var connected = false
var shieldconnected = false
var impact_frame = 0

var hurtboxsize = Vector2(0,0)
var hurtboxoffset = Vector2(0,0)

var players_to_ignore = []

var UP = Vector2(0,-1)

var w

func _ready():
	w = get_parent()
	z_index = 0


func _physics_process(_delta):
	
	var paused = w.PAUSED
	var framechange = Input.is_action_just_pressed("nextframe")
	var intro = w.FRAME < 0
	var slowmo = w.SLOMOFRAME % 2 == 1
	if ((!paused) || framechange) && impact_frame == 0 && !intro && !slowmo:
		
		if player_who_last_hit_me > 0:
			if !(["shield", "shieldstun"].has(w.players[player_who_last_hit_me-1].state)):
				player_who_last_hit_me = 0
		
		projectilemovement()
	
	
		frame += 1
		state = nextstate
		
		invincibility_frame -= 1
		invincibility_frame = max(invincibility_frame, 0)
		intangibility_frame -= 1
		intangibility_frame = max(intangibility_frame, 0)

	impact_frame -= 1
	if impact_frame < 0:
		impact_frame = 0
	
	drawprojectile()
	drawhurtbox()
	
func start():
	pass
	


func hitbox(boxes):
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
	
	hbox.visible = w.SHOWHITBOXES
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
			hbox.startframe.append(w.FRAME + b["del"])
			if hbox.life < b["len"] + b["del"]:
				hbox.life = b["len"] + b["del"]
		else:
			hbox.startframe.append(w.FRAME)
			if hbox.life < b["len"]:
				hbox.life = b["len"]
	hitboxes.append(hbox)
	add_child(hbox)
	
	
func drawhurtbox():
	$Hurtbox.visible = w.SHOWHITBOXES
	$Hurtbox.margin_left = -hurtboxsize.x + hurtboxoffset.x
	$Hurtbox.margin_right = hurtboxsize.x + hurtboxoffset.x
	$Hurtbox.margin_top = -hurtboxsize.y + hurtboxoffset.y
	$Hurtbox.margin_bottom = hurtboxsize.y + hurtboxoffset.y
	
func projectilemovement():
	pass
	
func drawprojectile():
	pass

func respawn(_place):
	w.projectiles.erase(self)
	queue_free()
