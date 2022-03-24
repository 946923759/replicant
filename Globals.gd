extends Node

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
		print(file)
		if file == "":
			dir.list_dir_end()
			return null
		elif file.begins_with(fname):
			print("Found file:"+file)
			#print("Return "+path+file)
			dir.list_dir_end()
			return path+file
