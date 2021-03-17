extends Node2D

var playernumber = 0
var SCREENX = 1920
var SCREENY = 1080
var P = 8
var xspeed = 0.008
var yspeed = 0.01
var pos = Vector2(0,0)
var heldplayer = 0
var player_to_hold

var Mat

func start(i):
	playernumber = i
	Mat = $Sprite.get_material()
	heldplayer = playernumber
	if Input.get_connected_joypads().has(playernumber-1) || playernumber == 1:
		if Globals. playercontrollers[playernumber-1] > 0:
			Globals.chipholder[playernumber-1] = playernumber
	else:
		Globals.chipholder[playernumber-1] = 0

func _ready():
	display()

func _process(_delta):
	controls()
	display()
	
func display():
	if Globals.playerselected[heldplayer-1]:
		$Sprite.frame = 3
		if canselect():
			$Sprite.frame = 2
	else:
		$Sprite.frame = (Globals.CSSFRAME/10)%2
	var pointing = false
	if overlappingadd():
		pointing = true
	if overlappingslate():
		pointing = true
	if pointing:
		$Sprite.frame = 3
	Mat.set_shader_param("color", Globals.CONTROLLERCOLORS[Globals.playercontrollers[heldplayer-1]])
	visible = (
		(playernumber == 1) || 
		Input.get_connected_joypads().has(playernumber-1))
	
	
	pos = Globals.pointpos[playernumber-1]
	position = Vector2(
		pos.x * Globals.SCREENX,
		pos.y * Globals.SCREENY + 32)
		
func controls():
	var input = [false,false,false,false,false,false]
	var c = str(playernumber-1)
	if c == "0":
		input = [
			Input.is_action_pressed("right"),
			Input.is_action_pressed("left"),
			Input.is_action_pressed("jump"),
			Input.is_action_pressed("down"),
			Input.is_action_just_pressed("attack"),
			Input.is_action_just_pressed("special")
		]
	else:
		input = [
			Input.is_action_pressed("right" + c),
			Input.is_action_pressed("left" + c),
			Input.is_action_pressed("jump" + c),
			Input.is_action_pressed("down"+ c),
			Input.is_action_just_pressed("attack" + c),
			Input.is_action_just_pressed("special" + c)
		]
	
	if input[0]:
		pos.x += xspeed
		
	if input[1]:
		pos.x -= xspeed
		
	if input[2]:
		pos.y -= yspeed
		
	if input[3]:
		pos.y += yspeed
		

	if !Globals.playerselected[heldplayer-1]:
		if !overlappingslate():
			if input[4]:
				if Globals.playerchars[heldplayer-1] >= 0:
					Globals.playerselected[heldplayer-1] = true
					Globals.chipholder[heldplayer-1] = 0
					Globals.chippos[heldplayer-1] = pos + Vector2(-0.01,-0.05)
	else:
		if input[5]:
			heldplayer = playernumber
			Globals.chipholder[playernumber-1] = playernumber
			Globals.playerselected[heldplayer-1] = false
		
		elif input[4]:
			if canselect():
				heldplayer = player_to_hold
				Globals.playerselected[heldplayer-1] = false
				Globals.chipholder[heldplayer-1] = playernumber
	
	if Globals.chipholder.has(playernumber):
		Globals.playerchars[heldplayer-1] = -1
		if abs(pos.x-.5)<.1 && abs(pos.y-.25)<.2:
			Globals.playerchars[heldplayer-1] = 0
	
	pos.x = clamp(pos.x,0,1)
	pos.y = clamp(pos.y,0,1)
	
	if pos.y > 0.5:
		var selectedslate = floor(pos.x * Globals.NUM_OF_PLAYERS)
		if input[4]:
			if position.y > Globals.SCREENY - 32:
				#human or computer
				if Globals.playercontrollers[selectedslate] > 0:
					Globals.playercontrollers[selectedslate] = 0
				else:
					for i in range(8):
						if !Globals.playercontrollers.has(i+1):
							Globals.playercontrollers[selectedslate] = i+1
							break
			else:
				#change skin
				if Globals.playercontrollers[selectedslate] == playernumber || Globals.playercontrollers[selectedslate] == 0:
					Globals.playerskins[selectedslate] += 1
					Globals.playerskins[selectedslate] = Globals.playerskins[selectedslate] % 8
	
	if overlappingadd():
		if input[4]:
			if position.x > Globals.SCREENX - 96:
				Globals.NUM_OF_PLAYERS -= 1
			else:
				Globals.NUM_OF_PLAYERS += 1
		Globals.NUM_OF_PLAYERS = clamp(Globals.NUM_OF_PLAYERS, 2, 8)

	Globals.pointpos[playernumber-1] = pos

func overlappingadd():
	return position.x > Globals.SCREENX - 256 && position.y < Globals.SCREENY/2 + 32 && position.y > Globals.SCREENY/2 - 96

func overlappingslate():
	return pos.y > 0.5

func canselect():
	for i in range(Globals.NUM_OF_PLAYERS):
		if (Globals.chippos[i]- pos).length() < 0.07 && (Globals.playercontrollers[i] == playernumber || Globals.playercontrollers[i] == 0):
			player_to_hold = i+1
			return true
			
	return false
