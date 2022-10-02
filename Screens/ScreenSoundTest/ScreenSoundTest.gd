extends Control

var musicDatabase=[]
onready var musicActor=$smSound
onready var scContainer=$ScrollContainer
var font = preload("res://Fonts/OptionsFont.tres")

class Music:
	var name_
	var original_name
	var origin
	var description
	var fileName

func get_db_path()->String:
	if not OS.has_feature("console"):
		match OS.get_name():
			"Windows","X11","macOS":
				if OS.has_feature("standalone"):
					return OS.get_executable_path().get_base_dir()+"/GameData/"
	#If not compiled or if the platform doesn't allow writing to the game's current directory
	return "res://Music/"

func _ready():
	#var listPos = $ScrollContainer.rect_position
	$UpArrow.rect_position=Vector2(
		scContainer.rect_position.x+scContainer.rect_size.x/2+64,
		scContainer.rect_position.y
	)
	$DownArrow.rect_position=Vector2(
		scContainer.rect_position.x+scContainer.rect_size.x/2-64,
		scContainer.rect_position.y+scContainer.rect_size.y
	)
	
	var f = File.new()
	var ok = f.open(get_db_path()+"MUSIC_DATABASE.tsv",File.READ)
	if ok != OK:
		printerr("failed to open chapter database! And now everything will break...")
	else:
		while !f.eof_reached():
			var line:String = f.get_line().strip_edges()
			if line.begins_with("#") or line.empty():
				continue
			var music = Music.new()
			var keys = line.split("\t",true)
			music.name_=keys[0]
			music.original_name=keys[1]
			music.origin=keys[2]
			music.description=keys[3]
			music.fileName=keys[4]
			musicDatabase.append(music)
	
	for m in musicDatabase:
		var w2 = font.get_string_size(m.name_).x
		
		var optionNameActor = Def.LoadFont(font,{
			"name":"TextActor",
			"text":m.name_,
			"uppercase":false,
			mouse_filter=MOUSE_FILTER_STOP,
			mouse_default_cursor_shape=CURSOR_POINTING_HAND,
			#clip_text=true
			#rect_scale=
			#rect_min_size=Vector2(0,150)
			#mouse_filter=MOUSE_FILTER_IGNORE
		})
		#optionNameActor.rect_scale=Vector2(min(1.0,scContainer.rect_size.x/w2),1.0)
		optionNameActor.connect("gui_input",self,"text_on_click_wrapper",[m])
		$ScrollContainer/VBoxContainer.add_child(optionNameActor)

func text_on_click(music:Music):
	musicActor.load_song(music.fileName);
	
	var width = get_viewport().get_visible_rect().size.x/2-100
	#print(desc.text)
	$NowPlaying/Origin.text=music.origin
	
	var desc = $NowPlaying/Title
	desc.text=music.original_name
	var width2 = desc.get("custom_fonts/font").get_string_size(music.original_name).x
	#print(width)
	#print(width2)
	if width2 > width:
		desc.rect_scale.x=width/width2
		#desc.rect_position.x=25*width/width2
		#desc.rect_size.x=width2 #For some hilarious reason this doesn't update on its own until the next frame, so do it ourselves.
		print(desc.rect_scale.x)
	else:
		desc.rect_scale.x=1.0
		#desc.rect_position.x=25
		#desc.rect_size.x=width
		pass
	#print(desc.rect_scale.x)
	var origin = $NowPlaying/Origin
	width2 = origin.get("custom_fonts/font").get_string_size(origin.text).x
	origin.rect_scale.x=min(1.0,width/width2)

func text_on_click_wrapper(event:InputEvent,music:Music):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		text_on_click(music)


func _on_BackButton_gui_input(event):
	if (event is InputEventMouseButton and event.pressed and event.button_index == 1):
		get_tree().change_scene("res://TitleScreen.tscn")
