extends Node

var OPTIONS = {
	"AudioVolume":{
		"type":"int",
		#"choices":[10,20,30,40,50,60,70,80,90,100], #this isn't used at all lol
		"default":100
	},
	"SFXVolume":{
		"type":"int",
		#"choices":[10,20,30,40,50,60,70,80,90,100],
		"default":100
	},
	"isFullscreen":{
		"type":"bool",
		"default":false,
		pc_only=true
	},
	"language":{
		"type":"list",
		"choices":["en","es","kr","ja","zh"],
		"localizeKey":"Language",
		"default":"en"
	},
	"textSpeed":{
		"type":"list",
		"choices":[10,20,30,40,50,60,70,80,90,100],
		"localizeKey":"TextSpeed",
		"default":80
	},
	#No need to save this
	#"autoRead":{
	#	"type":"bool",
	#	"default":false
	#}
}

# The name of the next cutscene to load from Cutscene/ or GameData/Cutscene
# if we're using the "cutscene from file" scene
var nextCutscene:String="cutscene1Data.txt"
var gameResolution:Vector2
var SCREEN_CENTER:Vector2
var SCREEN_CENTER_X:int
var SCREEN_CENTER_Y:int

class Chapter:
	var title:String
	var desc:String
	var parts:Array

var chapterDatabase = {}
var database = {}

#SAVE DATA
func get_save_directory(fName:String)->String:
	match OS.get_name():
		"Windows","X11","macOS":
			if OS.has_feature("standalone"):
				return OS.get_executable_path().get_base_dir()+"/"+fName+".json"
	#If not compiled or if the platform doesn't allow writing to the game's current directory
	return "user://"+fName+".json"

var playerHadSystemData:bool=false
var playerData={
	"avatarsUnlocked":[0],
	"CGunlock":[0],
	"musicUnlock":["none"]
}
func load_system_data()->bool:
	var save_game = File.new()
	if not save_game.file_exists(get_save_directory('systemData')):
		for option in OPTIONS:
			OPTIONS[option]['value'] = OPTIONS[option]['default']
		return false
	else:
		save_game.open(get_save_directory('systemData'), File.READ)
		var dataToLoad=parse_json(save_game.get_as_text())
		#TODO: what if an option gets removed?
		for option in OPTIONS:
			if option in dataToLoad['options']:
				OPTIONS[option]['value'] = dataToLoad['options'][option]
			else:
				OPTIONS[option]['value'] = OPTIONS[option]['default']
		playerData=dataToLoad['playerData']
		save_game.close()
		print("System save data loaded.")
		return true
		
func save_system_data()->bool:
	var save_game = File.new()
	var ok = save_game.open(get_save_directory('systemData'),File.WRITE)
	if ok != OK:
		printerr("Warning: could not create file for writing! ERROR ", ok)
		return false
	var dataToSave = {
		"options":{},
		"playerdata":playerData
	}
	for option in OPTIONS:
		dataToSave['options'][option]=OPTIONS[option]['value']
	save_game.store_line(to_json(dataToSave))
	save_game.close()
	print("Saved to "+get_save_directory('systemData'))
	return true

func _ready():
	gameResolution = get_viewport().get_visible_rect().size
# warning-ignore:narrowing_conversion
	SCREEN_CENTER_X = gameResolution.x/2
# warning-ignore:narrowing_conversion
	SCREEN_CENTER_Y = gameResolution.y/2
	SCREEN_CENTER=Vector2(SCREEN_CENTER_X,SCREEN_CENTER_Y)
	
	var f = File.new()
	var ok = f.open("res://ggz-portrait-db.json",File.READ)
	if ok != OK:
		printerr("Failed to open portrait database")
	else:
		database=parse_json(f.get_as_text())
		print("Loaded database. "+String(database.size())+" entries.")
	f.close()
	
	ok = f.open("res://ch-sel-db.tsv",File.READ)
	if ok != OK:
		printerr("failed to open chapter database! And now everything will break...")
	else:
		var lastChapter = "No Grouping!!"
		while !f.eof_reached():
			var line:String = f.get_line().strip_edges()
			if line.begins_with("--"):
				lastChapter=line.substr(2,line.length())
				chapterDatabase[lastChapter]=[]
			elif !line.empty():
				var keys = line.split("\t",true)
				var chapter = Chapter.new()
				chapter.title=keys[0]
				if keys.size() > 1:
					chapter.desc=keys[1]
				else:
					chapter.desc=""
				if keys.size() > 2:
					chapter.parts=keys[2].split(",",true)
				else:
					chapter.parts=[]
				chapterDatabase[lastChapter].append(chapter)
	load_system_data()


var wasFullscreen:bool = false

func _input(_event):
	if Input.is_action_just_pressed("Fullscreen"):
		wasFullscreen=!wasFullscreen
		set_fullscreen(wasFullscreen)

func set_fullscreen(b):
	if b:
		OS.set_window_fullscreen(true)
	else:
		OS.set_window_fullscreen(false)
		OS.window_size = gameResolution
		OS.center_window()

func set_audio_levels():
	# Audio starts at -60db (silent) and ends at 0db (max).
	# So the 0~100 volume is scaled to 0~80 then subtracted by 80 to
	# determine what to put the volume level at.
	
	var audios = {
		#The number corresponds to the position in default_bus_layout
		2:Globals.OPTIONS['AudioVolume']['value'],
		1:Globals.OPTIONS['SFXVolume']['value'],
		#3:Globals.OPTIONS['VoiceVolume']['value']
	}
	for d in audios:
		var realVolumeLevel = audios[d]*.3-30
		#print(realVolumeLevel)
		if realVolumeLevel == -30:
			#instead of setting it to -80 just mute the bus to free up CPU
			AudioServer.set_bus_mute(d,true);
		else:
			AudioServer.set_bus_volume_db(d,realVolumeLevel)
			AudioServer.set_bus_mute(d,false)

func get_matching_files(path,fname):
	#var files = []
	var dir = Directory.new()
	print("Opening "+path)
	var ok = dir.open(path)
	if ok != OK:
		printerr("Warning: could not open directory: ERROR ", ok)
		return null
	#print(dir.get_current_dir())
	dir.list_dir_begin(false,true)

	while true:
		var file = dir.get_next()
		#print(file)
		if file == "":
			dir.list_dir_end()
			return null
		elif file.begins_with(fname):
			print("Found file:"+file)
			#print("Return "+path+file)
			dir.list_dir_end()
			return path+file
