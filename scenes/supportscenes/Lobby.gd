extends Node2D

var ip = "127.0.0.1"
var port = 1909
var max_players = 100

var player_info = {}
var my_info = ["BOB", -1, 0, 0, 0]

var roomsused = []
var players_done = {}
var lobbyframe = 0

onready var DAMAGE = preload("res://ui/Damage.tscn")
onready var TAG = preload("res://ui/Tag.tscn")

func _ready():
	print("HELLO!")
	if Globals.ISSERVER:
		print("YOU ARE THE SERVER!!!")
		my_info = []
	else:
		print("YOU ARE A CLIENT!!!")
		
	visible = true
	
	Globals.ONLINE = true
	
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

	if Globals.ISSERVER:
		CreateServer()
	else:
		ConnectToServer()
		
	
func _process(_delta):
	if !Globals.ISSERVER:
		if !Globals.INGAME:
			if Input.is_action_just_pressed("attack"):
				my_info[1] = 0
				var id = get_tree().get_rpc_sender_id()
				rpc_id(id, "register_player", my_info)
				print(my_info)
				
			if Input.is_action_just_pressed("special"):
				if my_info[1] == -1:
					go_back()
				else:
					my_info[1] = -1
					var id = get_tree().get_rpc_sender_id()
					rpc_id(id, "register_player", my_info)
					print(my_info)
			
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
	print("go to menu")
	get_tree().network_peer = null
	var _menu = get_tree().change_scene("res://scenes/supportscenes/Menu.tscn")
	



func _player_connected(id):
	rpc_id(id, "register_player", my_info)
	print("PLAYER CONNECTED " + str(id))
	print(Globals.playerIDs)
	
	
	
	
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
		var world = load("res://scenes/mainscene/World.tscn").instance()
		get_node("/root").add_child(world)
		world.players = []
		world.projectiles = []
		world.PAUSED = true
		
		world.NUM_OF_PLAYERS = 2
		world.STOCKS = 6
		world.TIME = 180
		world.TIMELIMIT = 180
		world.GAMEMODE = "STOCK"
		world.TEAMMODE = false
		world.TEAMATTACK = false
		world.STAGE = 0
		world.TIEBREAKER = 5
		world.CPULEVEL = 3
		world.SCORETOWIN = 5

		# Load my player
		var my_player = preload("res://characters/spacedog/Spacedog.tscn").instance()
		my_player.set_name(str(selfPeerID))
		my_player.set_network_master(selfPeerID)
		get_node("/root/World/").add_child(my_player)
		my_player.respawn(Vector2(0,-256), true)
		my_player.skin = my_info[2]
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
				get_node("/root/World/").add_child(player)
				player.respawn(Vector2(0,-256), true)
				player.skin = player_info[p][2]
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
		Globals.INGAME = true



func server_pre_configure(room):
	
		print("ADDING SCENES...")
	
		var world = load("res://scenes/mainscene/World.tscn").instance()
		get_node("/root").add_child(world)
		world.players = []
		world.projectiles = []

		# Load players
		for p in player_info:
			var player = preload("res://characters/spacedog/Spacedog.tscn").instance()
			player.set_name(str(p))
			player.set_network_master(p)
			get_node("/root/World/").add_child(player)
			player.respawn(Vector2(0,-256), true)
			player.skin = player_info[p][2]
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
	assert(not who in players_done[room]) # Was not added yet
	
	if !players_done.has(room):
		players_done[room] = [who]
	else:
		players_done[room].append(who)

	if players_done[room].size() == 2:
		rpc("post_configure_game")


#CLIENT DOES THIS
remote func post_configure_game():
	# Only the server is allowed to tell a client to unpause
	if 1 == get_tree().get_rpc_sender_id():
		get_tree().get_root().get_node("World").PAUSED = false
