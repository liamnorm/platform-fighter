extends Node

const NUM_OF_PLAYERS = 4

const LEDGES = [[Vector2(-640, 256), 1], [Vector2(640, 256), -1]]
var PLATFORMLEDGES = []
const TOPBLASTZONE = -1080
const BOTTOMBLASTZONE = 1440
const SIDEBLASTZONE = 1728
var FRAME = 0

var players
var projectiles

var PAUSED = false

var IMPACTFRAME = 10

var SHOWHITBOXES = false


func _process(delta):
	FRAME += 1
