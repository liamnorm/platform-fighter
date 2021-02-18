extends ColorRect

const SPEED = 3000

var life = 0
var player = 0
var topleft
var bottomright
var d = 1
var damage = 0
var hitdirection = Vector2(0,0)
var knockback = 1
var constknockback = 0
var stun = 0
var players_to_ignore = []
var hitstun = false
var startframe = 0

var impact_frame = 0


func _ready():
	pass # Replace with function body.


func _process(_delta):
	
	var paused = Globals.PAUSED
	var framechange = Input.is_action_just_pressed("nextframe")
	if ((!paused) || framechange) && impact_frame == 0:
		d = get_parent().d
		
		if d == 1:
			margin_left = topleft.x * d
			margin_right = bottomright.x * d
		else:
			margin_right = topleft.x * d
			margin_left = bottomright.x * d
		
		margin_top = topleft.y
		margin_bottom = bottomright.y
		
		life -= 1
		
		if get_parent().state == "land":
			get_parent().hitboxes.erase(self)
			queue_free()

		if life < 0:
			get_parent().hitboxes.erase(self)
		if life < -1:
			queue_free()
	
	
func start():
	pass
	
