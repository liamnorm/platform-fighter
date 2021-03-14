extends Node

var NUM_OF_PLAYERS = 8

var STOCKS = 4
var TIME = 120

var GAMEMODE = "STOCK"

var SELECTEDMENUBUTTON = 0

var MUTED = true

var playerskins = [0,1,2,3,4,5,6,7,8]
var playerchars = [0,0,0,0,0,0,0,0,0]
var playercontrollers = [1,2,0,0,0,0,0,0]
var chipholder =  [0,0,0,0,0,0,0,0,0]

var chippos = []
var pointpos = []
var playerselected = []
var CSSFRAME = 0

var characternames = ["SPACEDOG", "TODD"]
var characterdirectories = {-1:"", 0:"spacedog", 1:"todd"}


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
	
var LEFTSIDECOLOR = Color("40ff0000")
var RIGHTSIDECOLOR = Color("4000c9ff")
var LEFTGOALCOLOR = Color("40ff0022")
var RIGHTGOALCOLOR = Color("4003fd36")
var DOUBLECOLOR = Color("400022ff")
var TRIPLECOLOR = Color("40ff0022")
		
		
const NUM_OF_SKINS = 8

const LEDGES = [[Vector2(-640, 256), 1], [Vector2(640, 256), -1]]
var PLATFORMLEDGES = []
const TOPBLASTZONE = -1100
const BOTTOMBLASTZONE = 1300
const SIDEBLASTZONE = 3000
const DOUBLEBLASTZONE = 1152
const TRIPLEBLASTZONE = 2048

var RIGHTSCORE = 0
var LEFTSCORE = 0

var GAMEENDFRAME = 0
var SLOMOFRAME = 0
var KOFRAME = 0
var DOUBLEKOFRAME = 0
var TRIPLEKOFRAME = 0
var LEFTSCOREFRAME = 0
var RIGHTSCOREFRAME = 0
var WINNER = 0
var WINNERCONTROLLER = 0
var WINNERCHARACTER = ""
var DEFEATORDER = []
var ELIMINATIONFRAME = 0
var ELIMINATEDPLAYER = 0

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
