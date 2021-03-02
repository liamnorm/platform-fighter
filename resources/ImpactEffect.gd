extends Sprite

var SPEED = 3000
var LIFESPAN = 15

var myframe = 0
var player = 0
var d = 1
var effecttype = "undefined"


func _ready():
	pass # Replace with function body.


func _physics_process(_delta):
	
	var paused = Globals.PAUSED
	var framechange = Input.is_action_just_pressed("nextframe")
	if ((!paused) || framechange):
		
		myframe += 1
		
		if myframe > LIFESPAN:
			queue_free()
			
		
		match effecttype:
			"impact":
				LIFESPAN = 15
				frame = myframe / 3
				if frame > 5:
					frame = 5
			"foxsidespecial":
				pass
			"launch":
				if myframe == 1:
					flip_h = randi() % 2
					flip_v = randi() % 2
					position += Vector2(randi()%60-30, randi()%60-30)
					var b = Globals.CONTROLLERCOLORS[Globals.players[player-1].controller]
					modulate = Color(b.r+0.9, b.g+0.9, b.b+0.9, 1)
				LIFESPAN = 30
				frame = myframe / 5 + 8
				if frame > 14:
					frame = 14
		
	
func start():
	pass
