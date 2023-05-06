extends Node

#Hint: use OPTIONS[option]['value'] to access these
var OPTIONS = {
	"AudioVolume":{
		"type":"int",
		#"choices":[10,20,30,40,50,60,70,80,90,100], #this isn't used at all lol
		"default":100
	},
	"SFXVolume":{
		"type":"int",
		#"choices":[10,20,30,40,50,60,70,80,90,100],
		"default":80
	},
	"isFullscreen":{
		"type":"bool",
		"default":false,
		pc_only=true
	},
	"language":{
		"type":"list",
		"choices":["en","ja","ch","pt"],
		"localizeKey":"Language",
		"default":"en"
	},
	#TODO: Making this a list was a very bad idea because
	#the engine doesn't know if it's an int or a list, if
	#we know it's an int we can at least force it
	"textSpeed":{
		"type":"list",
		"choices":[10,20,30,40,50,60,70,80,90,100],
		"localizeKey":"TextSpeed",
		"default":80
	},
	"textStyle":{
		"type":"list",
		"choices":["Serif","Sans Serif"],
		"default":"Sans Serif"
	},
	"bgOpacity":{
		"type":"int",
		#Due to how JSON works this can end up being cast to a float
		#"choices":[0,10,20,30,40,50,60,70,80,90,100],
		"localizeKey":"bgOpacity",
		"default":60
	},
	"skipMode":{
		"type":"list",
		"choices":[false,true],
		"localizeKey":"SkipModes",
		"default":false
	},
	"testOption":{
		"type":"list",
		"choices":["LOOOOONG STRING","Short String","a","b"],
		"default":"a"
	}
	#No need to save this
	#"autoRead":{
	#	"type":"bool",
	#	"default":false
	#}
}
var gameResolution:Vector2
var SCREEN_CENTER:Vector2
var SCREEN_CENTER_X:int
var SCREEN_CENTER_Y:int

class Episode:
	#There is no easy way to get the parent without iterating through the
	#whole dict so put it here too
	var parentChapter:String
	var title:String
	var desc:String
	var parts:Array
	var isSub:bool=false
	
	func _to_string():
		var s = title+":"
		s+="\n\tDescription: "+desc
		s+="\n\tParts: "+String(parts)
		s+="\n\tisSub: "+String(isSub)
		return s
	
	"""
	Example:
		Episode {
			parentChapter = "Chapter 1"
			title = "Significance"
			desc = "Description here"
			parts = ["kyusyo0-3-1", "kyusyo0-3-2", "kyusyo0-3-3"]
			isSub = false
		}
	"""

"""
Typed dict support when?
The structure of chapterDatabase is:
	
chapterDatabase = {
	"Chapter0":[
		Episode,
		Episode,
		Episode
	],
	"Chapter1":[
		Episode,
		...
	]
}
"""
var chapterDatabase = {
	#"No Grouping!!":[]
}
var database = {}

# The name of the next cutscene to load from Cutscene/ or GameData/Cutscene
# if we're using the "cutscene from file" scene
var nextCutscene:String="kyusyo0-1-1.txt"
#This is optional, but if it's present the options screen
#will display the current chapter and description.
var currentEpisodeData:Episode

func get_next_cutscene(curEpisode:Episode,curPart:String):
	if curEpisode==null:
		print("No episode!! No next part to load...")
		return ["",null]
	
	var nextEpisode:Episode
	var nextPart:String=""
	var parts = curEpisode.parts
	for i in range(parts.size()):
		if parts[i]+".txt"==curPart:
			if i+1<parts.size():
				nextPart=parts[i+1]
				print("[Globals] Got new part in same episode: "+nextPart)
			else:
				print("Hit end of episode? "+String(i)+"/"+String(parts.size()))
			break
		else:
			print(parts[i]+"!="+curPart)
	if nextPart!="":
		return [nextPart+".txt",curEpisode]
	else:
		if curEpisode.parentChapter in chapterDatabase:
			var episodes = chapterDatabase[curEpisode.parentChapter]
			for i in range(episodes.size()):
				if episodes[i].title==curEpisode.title:
					if i+1<episodes.size():
						nextEpisode=episodes[i+1]
						if len(nextEpisode.parts)>0:
							nextPart=nextEpisode.parts[0]
							print("[Globals] Found next episode in chapter: "+nextEpisode.title)
							return [nextPart+'.txt',nextEpisode]
						else:
							print("[Globals] Next episode's parts were empty?")
					break
		
		var k = chapterDatabase.keys()
		for i in range(k.size()):
			if k[i]==curEpisode.parentChapter:
				if i+1<k.size():
					var next:Episode = chapterDatabase[k[i+1]][0]
					print("[Globals] Seem to hit the end of this chapter, returning next chapter "+next.parentChapter)
					return [next.parts[0]+".txt",next]
				else:
					print("[Globals] Hit the end of all the episodes, returning to main menu.")
					return ["",null]
	return ["",null]
		
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
	"CGunlock":['CG054_waifu2x_art_noise0_scale_tta_1'],
	"musicUnlock":[],
	'state':false
}
# Is there anywhere better to put this?
var wasUsingAutoMode:bool=false

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
				if OPTIONS[option]['type']=="int":
					OPTIONS[option]['value'] = int(dataToLoad['options'][option])
				else:
					OPTIONS[option]['value'] = dataToLoad['options'][option]
			else:
				OPTIONS[option]['value'] = OPTIONS[option]['default']
		#Hack because json forces float type
		OPTIONS['textSpeed']['value']=int(OPTIONS['textSpeed']['value'])
		if 'playerData' in dataToLoad:
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
		"playerData":playerData
	}
	for option in OPTIONS:
		dataToSave['options'][option]=OPTIONS[option]['value']
	save_game.store_line(to_json(dataToSave))
	save_game.close()
	print("Saved to "+get_save_directory('systemData'))
	return true

func _ready():
	
	gameResolution = get_viewport().get_visible_rect().size
	
	var forcedFullscreen = 0
	for arg in OS.get_cmdline_args():
		print("Cmdline arg: "+arg)
		if arg.find("=") > -1:
			var kv = arg.split("=")
			if kv[0]=="--force-res":
				#print("Found cmdline arg --force-res="+kv[1])
				if kv[1].find("x") > -1:
					var w_h = kv[1].split('x')
					if w_h[0].is_valid_integer() and w_h[1].is_valid_integer():
						var w = int(w_h[0])
						var h = int(w_h[1])
						if w>0 and h>0:
							gameResolution=Vector2(w,h)
							OS.window_size = gameResolution
							OS.center_window()
			elif kv[1]=="--fullscreen":
				if kv[1].to_lower()=="true":
					forcedFullscreen=2
				else:
					forcedFullscreen=1
	
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
		var tmp_startChapter:String = ""
		#var i = 0
		while !f.eof_reached():
			var line:String = f.get_line().strip_edges()
			if line.begins_with("--"):
				lastChapter=line.substr(2,line.length())
				chapterDatabase[lastChapter]=[]
			elif line.begins_with("#"):
				continue
			elif line.begins_with("//VN_START"):
				var l = line.substr(len("//VN_START")+1,line.length())
				if len(l)>0:
					tmp_startChapter=l
			elif line.begins_with("//VN_STOP"):
				continue
			elif !line.empty():
				var keys = line.split("\t",true)
				var episode = Episode.new()
				episode.title=keys[0]
				if keys.size() > 1:
					episode.desc=keys[1]
				else:
					episode.desc=""
				if keys.size() > 2:
					episode.parts=keys[2].split(",",true)
				else:
					episode.parts=[]
				
				if keys.size() > 3:
					episode.isSub=keys[3].to_lower()=='true'
				episode.parentChapter=lastChapter
				chapterDatabase[lastChapter].append(episode)
				
		if tmp_startChapter != "":
			print(tmp_startChapter)
			var keys = tmp_startChapter.split("/",true)
			print(keys)
			currentEpisodeData=chapterDatabase[keys[0]][int(keys[1])]
			nextCutscene=currentEpisodeData.parts[0]+".txt"
			
	playerHadSystemData = load_system_data()
	if playerHadSystemData:
		set_audio_levels()
		INITrans.SetLanguage(OPTIONS["language"]['value'])
	else:
		INITrans.SetLanguage(OPTIONS["language"]['default'])

		
	if forcedFullscreen>0:
		set_fullscreen(forcedFullscreen==2)
	elif playerHadSystemData:
		#It's annoying when I'm debugging
		if !OS.is_debug_build():
			set_fullscreen(OPTIONS['isFullscreen']['value'])
		else:
			print("Fullscreen setting is ignored in debug.")


func _input(_event):
	if Input.is_action_just_pressed("Fullscreen"):
		set_fullscreen(!OS.window_fullscreen)

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

static func deep_copy(v):
	var t = typeof(v)

	if t == TYPE_DICTIONARY:
		var d = {}
		for k in v:
			d[k] = deep_copy(v[k])
		return d

	elif t == TYPE_ARRAY:
		var d = []
		d.resize(len(v))
		for i in range(len(v)):
			d[i] = deep_copy(v[i])
		return d

	elif t == TYPE_OBJECT:
		if v.has_method("duplicate"):
			return v.duplicate()
		else:
			print("Found an object, but I don't know how to copy it!")
			return v

	else:
		# Other types should be fine,
		# they are value types (except poolarrays maybe)
		return v

static func get_matching_files(path,fname):
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

static func get_cutscene_path()->String:
	if not OS.has_feature("console"):
		match OS.get_name():
			"Windows","X11","macOS":
				if OS.has_feature("standalone"):
					return OS.get_executable_path().get_base_dir()+"/GameData/Cutscene/"
	#If not compiled or if the platform doesn't allow writing to the game's current directory
	return "res://Cutscene/Embedded/"

var SCREENS:Dictionary = {
	"ScreenDisclaimer":"res://Screens/BetaDisclaimer.tscn",
	"ScreenTitleMenu":"res://Screens/ScreenTitleMenu/ScreenTitleMenu.tscn",
	"ScreenGallery":"res://Screens/ScreenGallery/ScreenGallery_v2.tscn",
	"ScreenSoundTest":"res://Screens/ScreenSoundTest/ScreenSoundTestV2.tscn",

	"ScreenFirstRun":"res://Screens/ScreenFirstRun.tscn",
	"ScreenWebWarning":"res://Screens/ScreenWebWarning/ScreenWebWarning.tscn",

	"ScreenSelectChapter":"res://Screens/ScreenSelectChapter/TitleScreen.tscn",
	"CutsceneFromFile":"res://Cutscene/CutsceneFromFile.tscn",
	"ScreenProgrammerCredits":"res://Screens/ProgrammerCreditsV3.tscn",

	"ScreenSelectEra":"res://Screens/RetroRemake/EraSelect/ScreenSelectEra.tscn",

	"RR-ScreenTitleMenu":"res://Screens/RetroRemake/RR-ScreenTitleMenu/RR-ScreenTitleMenu.tscn",
	"RR-ScreenSelectChapter":"res://Screens/RetroRemake/RR-ScreenSelectChapter.tscn",
	"RR-CutsceneFromFile":"res://Cutscene/CutsceneFromFile-rr.tscn",
}

func change_screen(tree,screen:String)->void:
	if screen=="Quit":
		tree.quit();
	else:
		tree.change_scene(SCREENS[screen])
