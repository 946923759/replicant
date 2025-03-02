extends Control

export (String) var PrevScreen = "ScreenSelectChapter"
#export (String) var saveDataKey = "completedChapters"

onready var saveDataKeys = [
	"NO_SAVE",
	"completedChapters",
	"completedRetro",
	"completedReborn"
]
export (int,"NO SAVING","Fire Moth","Retrospective","Reborn") var saveCategory = 1
var cutsceneData:Dictionary

const Def = preload("res://stepmania-compat/StepManiaActors.gd")
#var nightShader = load("res://ParticleEffects/NightShader.tres")
#const nightShader = preload("res://ParticleEffects/NightShader.tres")
#const smSprite = preload("res://stepmania-compat/smSprite.gd")
#const smQuad = preload("res://stepmania-compat/smQuad.gd")

#func Quad(d)->smQuad:
#	var q = smQuad.new()
#	for property in d:
#		q.set(property,d[property])
#	return q


	
	
#func push_back_from_idx_one(arrToFill:Array,arr2:Array)->Array:
#	for i in range(1,arr2.size()):
#		arrToFill.push_back(arr2[i])
#	return arrToFill
	
static func strip_first(arr2:Array)->Array:
	var arrToFill=[]
	for i in range(1,arr2.size()):
		arrToFill.push_back(arr2[i])
	return arrToFill

#This function produces no side effects,
#But it can't be 'static' since the game has to be running
#for the OS var to be available
static func load_cutscene_data(name:String)->Dictionary:
	var f = File.new()
	var path:String
	if "/" in name: #Wait, why is this here?
		path=name
	else:
		path = Globals.get_cutscene_path()+name
		if OS.is_debug_build():
			print("[CutsceneFromFile] Got path "+path+" from file named "+name)
	var ok = f.open(path, File.READ)
	if ok != OK:
		printerr("Warning: could not open "+name+" for reading! ERROR ", ok)
		return Dictionary()
	
	var d = {
		'abs_path':path,
		'CDAudio':"",
		'nsf_fileName':"",
		"nsf_trackNum":0,
		'msg':[]
	}
	while !f.eof_reached():
		#DO NOT STRIP EDGES OR IT WILL BREAK EVERYTHING
		var line = f.get_line() #.strip_edges(false,true)
		#print(line)
		if line.begins_with('#'):
			var meta = line.split("\t",true)
			match meta[0]:
#				#THERE HAS TO BE A BETTER WAY TO DO THIS
#				"#BG":
#					print(line)
#					d['bg']=strip_first(meta)
#				"#NSF_FILENAME":
#					d['nsf_fileName']=line.lstrip("#NSF_FILENAME\t")
#				"#NSF_TRACKNUM":
#					d['nsf_trackNum']=int(line.lstrip("#NSF_TRACKNUM\t"))
#				"#CDAUDIO":
#					d['CDAudio']=line.lstrip("#CDAUDIO\t")
				"#SCREEN":
					d['screen'] = line.trim_prefix("#SCREEN\t")
				"#NEXT":
					d['next']=line.trim_prefix("#NEXT\t")
				"#LANGUAGES":
					#We don't discard the 0th element this time since
					#the columns match the columns in the msg command,
					# ex. #LANGUAGES is column 0, en is column 1, etc
					# and in the msg command "msg" is column 0, column 1
					# matches the meta tag
					d['lang']=meta
				_:
					push_warning("Unknown script metadata tag: "+meta[0])
		elif !line.empty():
			#print(line)
			d['msg'].push_back(line.replace("\\n","\n"))
	f.close()
	return d
	#return parse_json(f.get_as_text())

func _ready():
	$CutscenePlayer.PrevScreen = PrevScreen
	
	for arg in OS.get_cmdline_args():
		print("Cmdline arg: "+arg)
		if arg.find("=") > -1:
			var kv = arg.split("=")
			if kv[0]=="--cutscene":
				Globals.nextCutscene=kv[1]
				print("Set cutscene to "+kv[1])
				break
				
	cutsceneData = load_cutscene_data(Globals.nextCutscene)
	if cutsceneData.size()==0:
		#var e = load("res://savedataError.tscn").instance()
		#e.setNewText("The cutscene failed to load.")
		#add_child(e)
		$CutscenePlayer.init_(['msg|The cutscene failed to load. Most likely the file name is incorrect.\nTried to load '+Globals.nextCutscene],null)
		return
	#$AudioStreamPlayer.load_song(cutsceneData['CDAudio'])
	var msgColumn:int=1
	if "lang" in cutsceneData:
		#print(cutsceneData['lang'])
		for i in range(cutsceneData['lang'].size()):
			var lang = cutsceneData['lang'][i].to_lower()
			if lang == "ch":
				lang = "zh"
			elif lang == "jp":
				lang = "ja"
			#print(cutsceneData['lang'][i].to_lower()+ " == "+INITrans.currentLanguage)
			if lang==INITrans.currentLanguage:
				msgColumn=i
				break
	else:
		print("no language key found in file.")
	print("Loading from column "+String(msgColumn))
	
	if Globals.playerData.has('state') and typeof(Globals.playerData['state']) == TYPE_DICTIONARY and Globals.playerData['state'].empty()==false:
		$CutscenePlayer.init_resume_(cutsceneData['msg'],null,Globals.playerData['state'],"\t",msgColumn)
		#clear out the data
		Globals.playerData['state']=false
	else:
		$CutscenePlayer.init_(cutsceneData['msg'],null,false,"\t",msgColumn)
	
func _input(event):
	if event.is_action("DebugButton1") and event.is_pressed():
		if not cutsceneData['abs_path']:
			return
			
		var p = cutsceneData['abs_path']
		if OS.has_feature("standalone") == false:
			p = p.replace("res://","")
		print("[CutsceneFromFile] system shell is opening "+p)
		if OS.get_name() == "X11":
			OS.execute("xdg-open",[p], false)
			#"Windows","X11","macOS":
			#	if OS.has_feature("standalone"):
			#		return OS.get_executable_path().get_base_dir()+"/GameData/Cutscene/"

			#int execute(path: String, arguments: PoolStringArray, blocking: bool = true, output: Array = [  ], read_stderr: bool = false, open_console: bool = false)
			
	
	#s.hide()

#What is this even doing here?
func set_rect_size():
	for child in $BackgroundHolder.get_children():
		child.set_rect_size()

func _on_CutscenePlayer_cutscene_finished():
	end_cutscene_2()
	return
	
#	var seq := get_tree().create_tween()
#	seq.set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
## warning-ignore:return_value_discarded
#	seq.tween_property($fadeOut,'color:a',1,.5).set_trans(Tween.TRANS_QUAD)
#	seq.connect("finished",self,"end_cutscene_2")
#	pass # Replace with function body.

func end_cutscene_2():
	var needToSave:bool=false
	
	var backgrounds:Control = $CutscenePlayer.backgrounds
	for c in backgrounds.get_children():
		var f = c.get_meta("file_name")
		if f and !(f in Globals.playerData['CGunlock']):
			print_debug("[CutsceneFromFile Save] Unlocked CG "+f)
			Globals.playerData['CGunlock'].append(f)
			needToSave=true
	
	var saveDataKey:String = saveDataKeys[saveCategory]
	var currentDatabase:Dictionary = Globals.chapterDatabase
	if saveCategory==2:
		currentDatabase=Globals.chapterDatabase_RR
	elif saveCategory==3:
		currentDatabase=Globals.chapterDatabase_RE
	
	if saveCategory > 0 and Globals.currentEpisodeData:
		var save_idx = Globals.get_episode_index(currentDatabase, Globals.currentEpisodeData)
		var ch_idx = save_idx[0]
		var ep_idx = save_idx[1]
		if ch_idx >= 0 and ep_idx >= 0:
			#Resize completed chapters array
			while Globals.playerData[saveDataKey].size() <= ch_idx:
				Globals.playerData[saveDataKey].append(0)
			
			var bit = Globals.playerData[saveDataKey][ch_idx]
			if (bit & 1<<ep_idx) == 0:
				needToSave=true
			Globals.playerData[saveDataKey][ch_idx] |= 1<<ep_idx
			
	
	if needToSave:
		#print("[CutsceneFromFile Save] Saved complete state to "+saveDataKey)
		#print(Globals.playerData[saveDataKey])
		Globals.save_system_data()
	
	var tmp = Globals.get_next_cutscene(currentDatabase, Globals.currentEpisodeData,Globals.nextCutscene)
	var nextPart = tmp[0]
	var nextEpisode = tmp[1]
	
	if 'screen' in cutsceneData and cutsceneData['screen'] != "":
		Globals.change_screen(get_tree(),cutsceneData['screen'], self.name)
	elif nextPart!="":
		print("[CutsceneFromFile] Got new part "+nextPart+", with episode "+nextEpisode.title)
		Globals.nextCutscene=nextPart
		Globals.currentEpisodeData=nextEpisode
		get_tree().reload_current_scene()
	else:
		print("[CutsceneFromFile] Didn't get a next part, returning to PrevScreen "+PrevScreen)
		#get_tree().change_scene("res://TitleScreen.tscn")
		Globals.change_screen(get_tree(),PrevScreen, self.name)
