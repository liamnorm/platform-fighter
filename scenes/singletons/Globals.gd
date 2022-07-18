extends Node

var MENU = "MAIN"

#Character select
var playerskins = [0,1,2,3,4,5,6,7,8]
var playerchars = [0,0,0,0,0,0,0,0,0]
var playercontrollers = [1,0,0,0,0,0,0,0]
var playerteams = [0,1,0,1,0,1,0,1]
var chipholder =  [0,0,0,0,0,0,0,0,0]

var chippos = []
var pointpos = []
var playerselected = []
var CSSFRAME = 0
var CSSBACKFRAME = 0


#Menu stuff / options
var SELECTEDMENUBUTTON = 0
var SELECTEDPAUSEMENUBUTTON = 0
var SELECTEDRULE = 0
var SELECTEDROOM = 0
var MUTED = false
var BEES = false
var SETTINGS = "NORMAL"
var SHOWHITBOXES = false

var RULECHOICES = {
	"STAGE": 0,
	"GAME MODE": 0,
	"STOCKS": 0,
	"TIME LIMIT": 5,
	"TIME": 3,
	"TEAMS": 0,
	"TEAM ATTACK": 0,
	"TIEBREAKER": 0,
	"CPU LEVEL": 2,
	"SCORE TO WIN": 4,
	
	"MUSIC": 0,
	"BEES": 1,
	"SETTINGS": 0,
}

#General stuff
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
const LEFTCOLOR = Color("ff0089")
const RIGHTCOLOR = Color("00ffcf")

const LEFTSIDECOLOR = Color("40ff0000")
const RIGHTSIDECOLOR = Color("4000c9ff")
const LEFTGOALCOLOR = Color("40ff0022")
const RIGHTGOALCOLOR = Color("4003fd36")
const DOUBLECOLOR = Color("400022ff")
const TRIPLECOLOR = Color("40ff0022")

const NUM_OF_SKINS = 16

#results
var WINNER = 0
var WINNERCHARACTER = ""
var WINNERCONTROLLER = 0
var WINNERSKIN = 0
var RESULTDATA



#specific to World
var NUM_OF_PLAYERS = 2
var STOCKS = 5
var TIME = 180
var TIMELIMIT = 180
var GAMEMODE = "TRAINING"
var TEAMMODE = false
var TEAMATTACK = false
var STAGE = 0

var TIEBREAKER = 5
var CPULEVEL = 3
var SCORETOWIN = 5


var STAGEDATA = [
	{
		"name": "FINAL DESTINATION",
		
		"TOPBLASTZONE": -1100,
		"BOTTOMBLASTZONE": 1300,
		"SIDEBLASTZONE": 3000,
		"DOUBLEBLASTZONE": 1152,
		"TRIPLEBLASTZONE": 2048,
		"cameraxbound": 2500,
		"camerayupperbound": -800,
		"cameraylowerbound": 1300,
		"spawnpositions":
			[
			Vector2(-384,0),
			Vector2(384,0),
			Vector2(0,192),
			Vector2(0,-192),
			Vector2(-384,192),
			Vector2(384,192),
			Vector2(192,192),
			Vector2(-192,192),
			],
		"ballspawn": Vector2(0, -160),
	
	},
	{
		"name": "SOCCER FIELD",
		
		"TOPBLASTZONE": -1100,
		"BOTTOMBLASTZONE": 800,
		"SIDEBLASTZONE": 3000,
		"DOUBLEBLASTZONE": 1152,
		"TRIPLEBLASTZONE": 2048,
		"cameraxbound": 2500,
		"camerayupperbound": -800,
		"cameraylowerbound": 800,
		
		"spawnpositions":
			[
			Vector2(-384,192),
			Vector2(384,192),
			Vector2(-640,192),
			Vector2(640,192),
			Vector2(-896,192),
			Vector2(896,192),
			Vector2(-1152,192),
			Vector2(1152,192),
			],
			
		
		"ballspawn": Vector2(0, 224),
	},
	{
		"name": "THE VOID",
		
		"TOPBLASTZONE": -1100,
		"BOTTOMBLASTZONE": 800,
		"SIDEBLASTZONE": 3000,
		"DOUBLEBLASTZONE": 1152,
		"TRIPLEBLASTZONE": 2048,
		"cameraxbound": 2500,
		"camerayupperbound": -800,
		"cameraylowerbound": 800,
		
		"spawnpositions":
			[
			Vector2(-384,192),
			Vector2(384,192),
			Vector2(-640,192),
			Vector2(640,192),
			Vector2(-896,192),
			Vector2(896,192),
			Vector2(-1152,192),
			Vector2(1152,192),
			],
			
		
		"ballspawn": Vector2(0, 0),
	}
]


var SCREENY
var SCREENX

var ONLINE = false
var ISSERVER = false
var CONNECTED = false
var INGAME = false
var ROOMS = []

var states = [
	"idle",
	"run",
	"runend",
	"turnaround",
	"jumpstart",
	"jump",
	"land",
	"crouch",
	"neutralspecial",
	"sidespecial",
	"upspecial",
	"downspecial",
	"neutralground",
	"sideground",
	"upground",
	"downground",
	"neutralair",
	"forwardair",
	"backair",
	"upair",
	"downair",
	"extra",
	"ledge",
	"ledgegetup",
	"shield",
	"shieldstun",
	"outofshield",
	"airdodge",
	"roll",
	"spotdodge",
	"hitstun",
	"mildstun",
	"hit",
	"knockeddown",
	"getup",
	"getupattack",
	"neutralgetup",
	"softland",
	"respawn",
	"shieldbreak",
	"dizzy",
]

func _process(_delta):
	SCREENX = get_viewport().size.x
	SCREENY = get_viewport().size.y
