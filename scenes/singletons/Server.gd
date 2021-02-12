extends Node

var network = NetworkedMultiplayerENet.new()
var ip = "127.0.0.1"
#var ip = "145.131.21.160"
var port = 1909

func _ready():
	ConnectToServer()
	
func ConnectToServer():
	network.create_client(ip, port)
	get_tree().set_network_peer(network)
	
	network.connect("connection_failed", self, "_OnConnectionFailed")
	network.connect("connection_succeeded", self, "_OnConnectionSucceeded")
	
func _OnConnectionFailed():
	print("Failed to connect")
		
func _OnConnectionSucceeded():
	print("Successfully connected")

func fetchMovementData(movement, requester):
	rpc_id(1, "fetchMovementData", movement, requester)

func returnMovementData(m_value, requester):
	instance_from_id(requester).SetMovementData(m_value)
