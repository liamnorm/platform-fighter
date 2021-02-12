extends ColorRect

const SPEED = 3000

var life = 0
var player = 0
var topleft = Vector2(0,0)
var bottomright = Vector2(0,0)
var d = 1
var damage = 0
var hitdirection = Vector2(0,0)
var knockback = 1
var constknockback = 0
var stun = 0


func _ready():
	pass # Replace with function body.


func _process(_delta):
	
	d = get_parent().get("d")
	
	if d == 1:
		margin_left = topleft.x * d
		margin_right = bottomright.x * d
	else:
		margin_right = topleft.x * d
		margin_left = bottomright.x * d
	
	margin_top = topleft.y
	margin_bottom = bottomright.y
	
	life -= 1
	
	if life < 1:
		get_parent().get("hitboxes").erase(self)
	if life < 0:
		queue_free()
	
	
func start():
	pass
	
