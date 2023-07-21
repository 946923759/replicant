extends Node
#I hate Godot's translation service
#I also hate Godot's non functioning ini parser
enum LanguageType {
	ASCII,
	ACCENTED,
	NON_LATIN
}

var currentLanguage:String="en"
var currentLanguageType:int = LanguageType.ASCII
var translation:Dictionary={}
var font #No point in preloading it when it gets overwritten on init
#var font=preload("res://MM2Font.tres")

static func push_back_from_idx_one(arr,arr2)->Array: #Arrays are passed by reference so there's no need to return them, but whatever
	for i in range(1,arr2.size()):
		arr.push_back(arr2[i])
	return arr

func GetLanguageFile()->String:
	match OS.get_name():
		"Windows","X11","macOS":
			if OS.has_feature("standalone"):
				return OS.get_executable_path().get_base_dir()+"/GameData/Language.tsv"
	return "res://Language.tsv"
#func initBaseLanguage():

static func _getDictionary(path:String)->Dictionary:
	var f = File.new()
	var ok = f.open(path, File.READ)
	if ok != OK:
		printerr("[TranslationMgr] Warning: could not open file for reading! ERROR ", ok)
		printerr(path)
		return Dictionary()
	var d = {'Common':{}}
	var lastCategory:String="Common"
	while !f.eof_reached():
		var line:String = f.get_line().strip_edges()
		if line.begins_with("--"):
			lastCategory=line.substr(2,line.length())
			d[lastCategory]={}
		elif line.begins_with("#"):
			continue
		
		elif !line.empty():
			var keys = line.split("\t",true)
			if keys.size()>1:
				var newArr = push_back_from_idx_one([],keys)
				d[lastCategory][keys[0]]=newArr
			
	f.close() #
	return d
		
func SetLanguage(lang:String)->bool:
	var tmp_translation=_getDictionary(GetLanguageFile())
	currentLanguage=lang
	if !(tmp_translation.has("Common") and tmp_translation["Common"].has('Languages')):
		printerr("[TranslationMgr] Missing Languages key in translation file.")
		return false
	
	var lang_col:int = -1
	var langs = tmp_translation['Common']['Languages']
	for i in range(langs.size()):
		if langs[i]==lang:
			lang_col=i
			break
	if lang_col == -1:
		printerr("[TranslationMgr] Language "+lang+" not found in file, falling back to English.")
		lang_col=0

	
	for category in tmp_translation.keys():
		translation[category]={}
		for k in tmp_translation[category].keys():
			if lang_col >= tmp_translation[category][k].size():
				translation[category][k]=tmp_translation[category][k][0]
			else:
				translation[category][k]=tmp_translation[category][k][lang_col]
				#translation[category][k]=config.get_value()
	print("[TranslationMgr] Loaded "+lang+" translation.")
	print("[TranslationMgr] "+GetString("Common","WindowTitle"))
#	match lang:
#		"en":
#			font=load("res://MM2Font.tres")
#			currentLanguageType=LanguageType.ASCII
#		"es":
#			font=load("res://FallbackPixelFont.tres")
#			currentLanguageType=LanguageType.ACCENTED
#		_:
#			font=load("res://ubuntu-font-family/JP_KR_font.tres")
#			currentLanguageType=LanguageType.NON_LATIN
	
	return true

func GetString(category:String,key:String,warn:bool=true)->String:
	#return key #stub
	
# warning-ignore:unreachable_code
	if translation.size()==0:
		push_error("[TranslationMgr] There is no translation loaded...")
		return key
	elif translation.has(category) and translation[category].has(key):
		return translation[category][key]
	if warn:
		push_warning("[TranslationMgr] There is no translation for ["+category+"] "+key)
	return key

func HasString(category:String,key:String)->bool:
	if translation.size()==0:
		return false
	return translation.has(category) and translation[category].has(key)
		
