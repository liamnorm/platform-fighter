extends Node2D

var ip = "127.0.0.1"
var port = 1909
var max_players = 100

var player_info = {}
var my_info = ["BOB", -1, 0, 0, 3, 0, 5, 180, 5]

var roomsused = []
var players_done = {}
var lobbyframe = 0

var pressframe = 0
var PRESSFRAMES = 10

var roomsshown = 6
var rooms = []

onready var DAMAGE = preload("res://ui/Damage.tscn")
onready var TAG = preload("res://ui/Tag.tscn")

func _ready():
	
	Globals.MENU = "LOBBY"
	
	print("HELLO!")
	if Globals.ISSERVER:
		print("YOU ARE THE SERVER!!!")
		my_info = []
		visible = false
	else:
		print("YOU ARE A CLIENT!!!")
		set_up_my_info()
		set_up_options()
		lookgood()
		
		visible = true
	
	Globals.ONLINE = true
	
	var c
	c = get_tree().connect("network_peer_connected", self, "_player_connected")
	c = get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	c = get_tree().connect("connected_to_server", self, "_connected_ok")
	c = get_tree().connect("connection_failed", self, "_connected_fail")
	c = get_tree().connect("server_disconnected", self, "_server_disconnected")

	if Globals.ISSERVER:
		CreateServer()
	else:
		ConnectToServer()
		
	
func _process(_delta):
	if !Globals.ISSERVER:
		if Globals.CONNECTED:
			if !Globals.INGAME:
				
				Globals.ROOMS = []
				for r in range(roomsshown):
					Globals.ROOMS.append([])
					for _p in range(8):
						Globals.ROOMS[r].append(null)
				
				if my_info[1] > -1:
					Globals.ROOMS[my_info[1]][my_info[2]] = get_tree().get_network_unique_id()
				for p in player_info:
					if !p == 1:
						var proom = player_info[p][1]
						var pnumber = player_info[p][2]
						Globals.ROOMS[proom][pnumber] = p
				
				#button presses
				if pressframe >= PRESSFRAMES:
					if my_info[1] == -1:
						if Input.is_action_just_pressed("down"):
							if Globals.SELECTEDROOM < roomsshown-1:
								Globals.SELECTEDROOM += 1
						if Input.is_action_just_pressed("jump"):
							if Globals.SELECTEDROOM > 0:
								Globals.SELECTEDROOM -= 1
					
					if Input.is_action_just_pressed("attack"):
						my_info[1] = Globals.SELECTEDROOM
						var id = get_tree().get_rpc_sender_id()
						rpc_id(id, "register_player", my_info)
						print(my_info)
						pressframe = 0
						
					if Input.is_action_just_pressed("special"):
						if my_info[1] == -1:
							go_back()
						else:
							my_info[1] = -1
							var id = get_tree().get_rpc_sender_id()
							rpc_id(id, "register_player", my_info)
							print(my_info)
							pressframe = 0
				
				pressframe += 1
				pressframe = clamp(pressframe, 0, PRESSFRAMES)
		else:
			if Input.is_action_just_pressed("special"):
				go_back()
				
		lookgood()
	else:
		visible = false
		checkforfullrooms()
			
	var infotext = ""
	if Globals.ISSERVER:
		infotext += "SERVER\n"
		for p in player_info:
			infotext += str(p) + " " + str(player_info[p]) + "\n"
	else:
		if Globals.CONNECTED:
			infotext = "CLIENT"
		else:
			if lobbyframe < 120:
				infotext = "CONNECTING TO SERVER..."
			else:
				infotext = "SERVER'S PROBABLY DOWN"
		
	$Label.text = infotext
	
	lobbyframe += 1
		

func ConnectToServer():
	player_info = {}
	var network = NetworkedMultiplayerENet.new()
	network.create_client(ip, port)
	get_tree().set_network_peer(network)
	
	
func CreateServer():
	player_info = {}
	var network = NetworkedMultiplayerENet.new()
	network.create_server(port, max_players)
	get_tree().set_network_peer(network)
	
		
func go_back():
	Globals.MENU = "CSS"
	get_tree().network_peer = null
	var _menu = get_tree().change_scene("res://scenes/supportscenes/Menu.tscn")
	queue_free()



func _player_connected(id):
	rpc_id(id, "register_player", my_info)
	print("PLAYER CONNECTED " + str(id))
	
func _player_disconnected(id):
	player_info.erase(id) # Erase player from info.
	print("PLAYER DISCONNECTED " + str(id))


func _connected_ok():
	Globals.CONNECTED = true
	print("connected")

func _server_disconnected():
	Globals.CONNECTED = false
	print("server disconnected")


func _connected_fail():
	print("connect failed")

	
remote func register_player(info):
	# Get the id of the RPC sender.
	var id = get_tree().get_rpc_sender_id()
	# Store the info
	player_info[id] = info
	
	print(player_info)
	
func checkforfullrooms():
	var room = 0
	var player_ids = []
	var peopleinroom = 0
	for p in player_info:
		if player_info[p][1] == room:
			player_ids.append(p)
			peopleinroom += 1
	if peopleinroom == 2 && !roomsused.has(room):
		print("STARTING ROOM...")
		roomsused.append(room)
		rpc_id(player_ids[0], "pre_configure_game")
		rpc_id(player_ids[1], "pre_configure_game")
		server_pre_configure(room)
	

#CLIENT DOES THIS
remote func pre_configure_game():
	
		assert(get_tree().get_rpc_sender_id() == 1)
		print("A GAME STARTED AND I'M IN THE ROOM!")
		var selfPeerID = get_tree().get_network_unique_id()

		# Load world
		var room = my_info[1]
		print(room)
		var world = load("res://scenes/mainscene/World.tscn").instance()
		world.set_name(str(room))
		get_node("/root").add_child(world)
		world.players = []
		world.projectiles = []
		
		world.PAUSED = true
		
		world.NUM_OF_PLAYERS = 2
		world.STOCKS = 6
		world.TIME = 180
		world.GAMEMODE = "STOCK"
		world.TEAMMODE = false
		world.TEAMATTACK = false
		world.STAGE = 0
		world.SCORETOWIN = 5

		# Load my player
		var my_player = preload("res://characters/spacedog/Spacedog.tscn").instance()
		my_player.set_name(str(selfPeerID))
		my_player.set_network_master(selfPeerID)
		get_node("/root/" + str(room) + "/").add_child(my_player)
		my_player.respawn(Vector2(0,-256), true)
		my_player.skin = my_info[4]
		my_player.tag = my_info[0]
		my_player.controller = 1
		my_player.character = "SPACEDOG"
		
		world.players.append(my_player)

		# Load other players
		for p in player_info:
			if !p == 1:
				var player = preload("res://characters/spacedog/Spacedog.tscn").instance()
				player.set_name(str(p))
				player.set_network_master(p)
				get_node("/root/" + str(room) + "/").add_child(player)
				player.respawn(Vector2(0,-256), true)
				player.skin = player_info[p][4]
				player.tag = player_info[p][0]
				player.controller = 2
				player.character = "SPACEDOG"
			
				world.players.append(player)
		
		for i in world.players.size():
			var tag = TAG.instance()
			tag.playernumber = i+1
			tag.controller =  world.players[i].controller
			world.add_child(tag)
			visible = false
			
			var damage_card = DAMAGE.instance()
			damage_card.playernumber = i+1
			damage_card.character = world.players[i].character
			world.get_node("CanvasLayer").add_child(damage_card)

		# Tell server (remember, server is always ID=1) that this peer is done pre-configuring.
		# The server can call get_tree().get_rpc_sender_id() to find out who said they were done.
		rpc_id(1, "done_preconfiguring")
		
		my_info[2] = 2
		#playing the game
		rpc_id(selfPeerID, "register_player", my_info)
		
		Globals.INGAME = true



func server_pre_configure(room):
	
		print("ADDING SCENES...")
		
		var world = load("res://scenes/mainscene/World.tscn").instance()
		world.set_name(str(room))
		get_node("/root").add_child(world)
		world.players = []
		world.projectiles = []
		
		world.NUM_OF_PLAYERS = 2
		

		# Load players
		for p in player_info:
			var player = preload("res://characters/spacedog/Spacedog.tscn").instance()
			player.set_name(str(p))
			player.set_network_master(p)
			get_node("/root/" + str(room) + "/").add_child(player)
			player.respawn(Vector2(0,-256), true)
			player.skin = player_info[p][4]
			player.tag = player_info[p][0]
			player.controller = 0
			player.character = "SPACEDOG"
			
			world.players.append(player)

#SERVER DOES THIS
remote func done_preconfiguring():
	var who = get_tree().get_rpc_sender_id()
	var room = player_info[who][1]
	# Here are some checks you can do, for example
	assert(get_tree().is_network_server())
	assert(who in player_info) # Exists
	
	if !players_done.has(room):
		players_done[room] = [who]
	else:
		players_done[room].append(who)

	if players_done[room].size() == 2:
		rpc("post_configure_game", room)


#CLIENT DOES THIS
remote func post_configure_game(room):
	# Only the server is allowed to tell a client to unpause
	if 1 == get_tree().get_rpc_sender_id() && room == my_info[1]:
		get_tree().get_root().get_node(str(room)).PAUSED = false

func set_up_my_info():
	my_info = ["BOB", -1, 0, 0, 3, 0, 5, 180, 5]
	my_info[4] = Globals.playerskins[0]
	my_info[5] = ["STOCK", "TIME", "SOCCER"].find(Globals.GAMEMODE)
	my_info[6] = Globals.STOCKS
	my_info[7] = Globals.TIME
	my_info[8] = Globals.SCORETOWIN
	print(my_info)

func set_up_options():
	for i in range(roomsshown):
		var button = load("res://ui/RoomOption.tscn").instance()
		button.buttonnumber = i
		add_child(button)
	
func lookgood():
	$Background.margin_right = Globals.SCREENX + 128
	$Background.margin_bottom = Globals.SCREENY + 128
