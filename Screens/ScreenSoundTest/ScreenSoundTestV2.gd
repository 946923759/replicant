extends "res://Screens/ScreenWithMenuElements.gd"
class_name SoundTest

var musicDatabase=[]
onready var musicActor=$smSound
onready var scContainer=$ScrollContainer
var font = preload("res://Fonts/CondensedFont.tres")

var curSel:int=0
#var curSong

class Music:
	var name_
	var original_name
	var origin
	var description
	var file_name

static func get_music_db_path()->String:
	if not OS.has_feature("console"):
		match OS.get_name():
			"Windows","X11","macOS":
				if OS.has_feature("standalone"):
					return OS.get_executable_path().get_base_dir()+"/GameData/"
	#If not compiled or if the platform doesn't allow writing to the game's current directory
	return "res://Music/"

static func load_music_database() -> Array:
	var musicDB:Array = []
	var f = File.new()
	var ok = f.open(get_music_db_path()+"MUSIC_DATABASE.tsv",File.READ)
	if ok != OK:
		printerr("failed to open music database! And now everything will break...")
	else:
		while !f.eof_reached():
			var line:String = f.get_line().strip_edges()
			if line.begins_with("#") or line.empty():
				continue
			var music = Music.new()
			var keys = line.split("\t",true)
			if len(keys)>=5:
				music.name_=keys[0]
				music.original_name=keys[1]
				music.origin=keys[2]
				music.description=keys[3]
				music.file_name=keys[4]
				musicDB.append(music)
			else:
				printerr("Hey moron, your music database is missing a column.")
				printerr(keys)
	return musicDB

func debug_open_file(f:String):
	if OS.is_debug_build():
		var path = f.trim_prefix("res://")
		if OS.get_name() == "X11":
			OS.execute("xdg-open",[path], false)

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
	musicDatabase = load_music_database()
	
	for m in musicDatabase:
		#var w2 = font.get_string_size(m.name_).x
		
		var optionNameActor = Def.LoadFont(font,{
			"name":"TextActor",
			"text":m.name_,
			"uppercase":false,
			mouse_filter=MOUSE_FILTER_PASS,
			mouse_default_cursor_shape=CURSOR_POINTING_HAND,
			#clip_text=true
			#rect_scale=Vector2(.5,1),
			#rect_min_size=Vector2(0,150)
			#mouse_filter=MOUSE_FILTER_IGNORE
		})
		#optionNameActor.rect_scale=Vector2(min(1.0,scContainer.rect_size.x/w2),1.0)
		optionNameActor.connect("gui_input",self,"text_on_click_wrapper",[m])
		$ScrollContainer/VBoxContainer.add_child(optionNameActor)
#	if $ScrollContainer/VBoxContainer.get_child_count()%6!=0:
#		for i in range(6-$ScrollContainer/VBoxContainer.get_child_count()%6):
#			$ScrollContainer/VBoxContainer.add_child(
#				Def.LoadFont(font,{
#					"name":"TextActor",
#					"uppercase":false,
#					mouse_filter=MOUSE_FILTER_IGNORE,
#				})
#			)
	highlight_text(curSel)
	$NowPlaying/Origin.text=""
	$NowPlaying/Title.text=""

func highlight_text(sel:int):
	var container = $ScrollContainer/VBoxContainer
	#var nowPlaying = $NowPlaying/Title.text
	for i in range(container.get_child_count()):
		var n = container.get_child(i)
		
		if i==sel:
			n.modulate=Color.white
		#elif nowPlaying == musicDatabase[i].original_name:
		#	n.modulate=Color.aqua
		else:
			n.modulate=Color.gray

func get_page_from_sel(sel:int)->int:
	return int(floor(sel/6))
	
func get_current_page()->int:
	return int(round($ScrollContainer.scroll_vertical/$ScrollContainer.rect_size.y))
func num_pages()->int:
	return int(len(musicDatabase)/6)

func tween_to_page(sel:int):
	var t:Tween = $Tween
	var rSize = $ScrollContainer.rect_size.y
	t.interpolate_property($ScrollContainer,"scroll_vertical",null,min(rSize*sel+20,$ScrollContainer/VBoxContainer.rect_size.y),.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	t.start()

func _input(_event):
	var newSel=curSel
	if Input.is_action_just_pressed("ui_select") or Input.is_action_just_pressed("ui_pause"):
		text_on_click(musicDatabase[curSel])
		return
	if Input.is_action_just_pressed("ui_down"):
		if newSel < len(musicDatabase)-1:
			newSel+=1
	elif Input.is_action_just_pressed("ui_up"):
		if newSel > 0:
			newSel-=1
	if newSel!=curSel:
		curSel=newSel
		#print("a")
		highlight_text(curSel)
		if get_current_page()!=get_page_from_sel(curSel):
			tween_to_page(get_page_from_sel(curSel))
		
	if Input.is_action_just_pressed("ui_shift"):
		#print(get_current_page())
		print(get_page_from_sel(curSel))
	if Input.is_action_just_pressed("DebugButton1"):
		debug_open_file(get_music_db_path()+"MUSIC_DATABASE.tsv")
	elif Input.is_action_just_pressed("DebugButton5"): #You can just press F3+2, but ok
		get_tree().reload_current_scene()
	
	#if event is InputEventMouseMotion:
	#	var tmpSel=get_selection_from_mouse_pos(curMenu,event)
	#	if tmpSel!=curSel:
	#		highlightList(curMenu,tmpSel)
	#		curSel=tmpSel

func text_on_click(music:Music):
	for i in range(len(musicDatabase)):
		if musicDatabase[i]==music:
			curSel=i
			highlight_text(curSel)
			break
	musicActor.load_song(music.file_name);
	
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
	
	var t:Tween = $NowPlayingTween
	var tTime:float = 1.0
	t.interpolate_property($NowPlaying/Label3,"rect_position:x",-100,0,tTime,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	t.interpolate_property($NowPlaying/Label3,"modulate:a",0,1,tTime,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	t.interpolate_property($NowPlaying/Title,"rect_position:x",100,0,tTime,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	t.interpolate_property($NowPlaying/Title,"modulate:a",0,1,tTime,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	t.interpolate_property($NowPlaying/Origin,"rect_position:y",225,250,tTime,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	t.interpolate_property($NowPlaying/Origin,"modulate:a",0,1,tTime,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	t.start()

func text_on_click_wrapper(event:InputEvent,music:Music):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		text_on_click(music)

func _on_DownArrow_gui_input(event):
	if (event is InputEventMouseButton and event.pressed and event.button_index == 1):
		var curPage = get_current_page()
		if curPage < num_pages():
			tween_to_page(curPage+1)
		#tween_to_page(1)

func _on_UpArrow_gui_input(event):
	if (event is InputEventMouseButton and event.pressed and event.button_index == 1):
		tween_to_page(0)
