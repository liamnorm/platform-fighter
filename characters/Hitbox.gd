extends Node2D

const SPEED = 3000

var life = 0
var player = 0
var topleft = []
var bottomright = []
var d = 1
var damage = []
var hitdirection = []
var knockback = []
var constknockback = []
var stun = []
var shieldstun = []
var hitstun = []
var startframe = []
var boxlengths = []

var players_to_ignore = []

var impact_frame = 0

var w


func _ready():
	w = get_parent().get_parent()


func _process(_delta):
	
	
	var paused = w.PAUSED
	var framechange = Input.is_action_just_pressed("nextframe")
	var intro = w.FRAME < 0
	var slowmo = w.SLOMOFRAME % 2 == 1
	if ((!paused) || framechange) && impact_frame == 0 && !intro && !slowmo:
		
		for b in range(len(topleft)):
			var boxname = "Box" + str(b)
			var box = get_node(boxname)
			if d == 1:
				box.margin_left = topleft[b].x * d
				box.margin_right = bottomright[b].x * d
			else:
				box.margin_right = topleft[b].x * d
				box.margin_left = bottomright[b].x * d
			
			box.margin_top = topleft[b].y
			box.margin_bottom = bottomright[b].y
			
			if w.FRAME >= startframe[b] && w.FRAME <= startframe[b] + boxlengths[b]:
				box.visible = true
			else:
				box.visible = false
		
		life -= 1
		
		if ["land", "hit", "mildstun", "hitstun", "knockeddown"].has(get_parent().state):
			get_parent().hitboxes.erase(self)
			queue_free()

		if life < 0:
			get_parent().hitboxes.erase(self)
		if life < -1:
			queue_free()
	
	
func start():
	pass
	
