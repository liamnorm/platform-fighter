extends KinematicBody2D

const SPEED = 3000

var frame = 0
var player = 0
var motion = Vector2(0,0)
var d = 1

var UP = Vector2(0,-1)

func _ready():
	pass # Replace with function body.


func _physics_process(_delta):
	
	motion = Vector2(d*SPEED, 0)
	
	if frame > 60:
		queue_free()
		
	motion = move_and_slide(motion, UP)
	frame += 1
	
func start():
	pass
	
