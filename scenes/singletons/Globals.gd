extends Node

var NUM_OF_PLAYERS = 2

var playerskins = [0,1,2,3,4,5,6,7,8]

const CONTROLLERCOLORS = [
	Color(.46,.61,.66,1), 
	Color(1,0,.31,1), 
	Color(0,.57,1,1), 
	Color(0.05,1,0,1), 
	Color(1,.93,0,1), 
	Color(1,.6,0,1),
	Color(.3,0,1,1),
	Color(.8,0,1,1),
	Color(0,.86,1,1),
	
	
	]
const NUM_OF_SKINS = 8

const LEDGES = [[Vector2(-640, 256), 1], [Vector2(640, 256), -1]]
var PLATFORMLEDGES = []
const TOPBLASTZONE = -1100
const BOTTOMBLASTZONE = 1300
const SIDEBLASTZONE = 3000
var FRAME = 0

var players
var projectiles

var PAUSED = false

var COMBO = 0

var IMPACTFRAME = 10

var SHOWHITBOXES = false

var SCREENY
var SCREENX


func _process(_delta):
	SCREENX = get_viewport().size.x
	SCREENY = get_viewport().size.y
