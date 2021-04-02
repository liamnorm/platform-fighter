extends Node2D

var buttonnumber = 0

var Mat
var Mat2

var yellow = Color("ffe300")
var darkblue = Color("26294a")
var black = Color(0,0,0,1)
var white = Color(1,1,1,1)

func _ready():
	lookgood()
	Mat = $P1.get_material()
	Mat2 = $P2.get_material()

func _process(_delta):
	lookgood()
	
func lookgood():
	
	if Globals.CONNECTED:
		visible = true
		position = Vector2(Globals.SCREENX/2, Globals.SCREENY/8)
		position.y += buttonnumber * 64
		if buttonnumber == Globals.SELECTEDROOM:
			$Rect.color = yellow
			$Name1.set("custom_colors/font_color", black)
			$Name2.set("custom_colors/font_color", black)
		else:
			$Rect.color = darkblue
			$Name1.set("custom_colors/font_color", white)
			$Name2.set("custom_colors/font_color", white)
			
			
		$P1.visible = false
		$Name1.text = ""
		if Globals.ROOMS[buttonnumber][0] != null:
			var hostname = Globals.ROOMS[buttonnumber][0]
			if get_parent().player_info.has(hostname):
				if hostname == get_tree().get_network_unique_id():
					$Name1.text = get_parent().my_info[0]
					Mat.set_shader_param("skin", get_parent().my_info[4])
				else:
					$Name1.text = get_parent().player_info[hostname][0]
					Mat.set_shader_param("skin", get_parent().player_info[hostname][4])
				$P1.visible = true
			
		$P2.visible = false
		$Name2.text = ""	
		if Globals.ROOMS[buttonnumber][1] != null:
			var othername = Globals.ROOMS[buttonnumber][0]
			if get_parent().player_info.has(othername):
				if othername == get_tree().get_network_unique_id():
					$Name2.text = get_parent().my_info[0]
					Mat2.set_shader_param("skin", get_parent().my_info[4])
				else:
					$Name2.text = get_parent().player_info[othername][0]
					Mat2.set_shader_param("skin", get_parent().player_info[othername][4])
				$P2.visible = true

	else:
		visible = false
