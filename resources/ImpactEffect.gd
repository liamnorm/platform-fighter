extends Sprite

onready var BLASTZONE = preload("res://resources/blastzone.png")
onready var IMPACT = preload("res://resources/impact.png")
onready var HIT = preload("res://resources/hit.png")
onready var FOXSIDE = preload("res://characters/spacedog/foxside.png")
onready var EXPLOSION = preload("res://resources/explosion.png")
onready var REFLECT = preload("res://resources/reflect.png")
onready var GLIMMER = preload("res://resources/glimmer.png")

var SPEED = 3000
var LIFESPAN = 15

var myframe = 0
var playernumber = 0
var d = 1
var effecttype = "undefined"
var w
var skin = 0

func _ready():
	w = get_parent()
	draweffect()
	z_index = -1
	
	if effecttype == "foxside":
		material.shader = load("res://characters/spacedog/side.shader")
		material.set_shader_param("skin", skin)
		material.set_shader_param("palette_tex", load("res://characters/spacedog/palette.png"))
		


func _physics_process(_delta):
	
	var paused = w.PAUSED
	var framechange = Input.is_action_just_pressed("nextframe")
	if ((!paused) || framechange):
		
		myframe += 1
		
		if myframe > LIFESPAN:
			queue_free()
			
		
		draweffect()
		
	
func start():
	pass

func draweffect():
	scale = Vector2(d, 1)
	match effecttype:
			"impact":
				vframes = 2
				hframes = 8
				texture = HIT
				LIFESPAN = 40
				frame = myframe / 4 + 2
				if frame > 13:
					frame = 13
			"glimmer":
				vframes = 1
				hframes = 8
				#position = w.players[playernumber-1].position + Vector2(d*-60, -60)
				scale = Vector2(0.5, 0.5)
				texture = GLIMMER
				LIFESPAN = 24
				frame = myframe / 4
				if frame > 7:
					frame = 7
			"foxside":
				vframes = 1
				hframes = 1
				texture = FOXSIDE
				LIFESPAN = 9
				material.set_shader_param("frame", myframe)
				frame = 0
			"launch":
				vframes = 2
				hframes = 8
				texture = IMPACT
				if myframe == 1:
					flip_h = randi() % 2
					flip_v = randi() % 2
					position += Vector2(randi()%60-30, randi()%60-30)
					var b = Globals.CONTROLLERCOLORS[w.players[playernumber-1].controller]
					modulate = Color(b.r+0.9, b.g+0.9, b.b+0.9, 1)
				LIFESPAN = 30
				frame = myframe / 5 + 8
				if frame > 14:
					frame = 14
			"blastzone":
				vframes = 8
				hframes = 1
				texture = BLASTZONE
				LIFESPAN = 15
			"explosion":
				vframes = 2
				hframes = 8
				texture = EXPLOSION
				LIFESPAN = 40
				frame = myframe / 4
			"reflect":
				vframes = 2
				hframes = 4
				texture = REFLECT
				LIFESPAN = 24
				frame = myframe / 4
