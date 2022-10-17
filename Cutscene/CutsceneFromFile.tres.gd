extends Control

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

func get_cutscene_path()->String:
	if not OS.has_feature("console"):
		match OS.get_name():
			"Windows","X11","macOS":
				if OS.has_feature("standalone"):
					return OS.get_executable_path().get_base_dir()+"/GameData/Cutscene/"
	#If not compiled or if the platform doesn't allow writing to the game's current directory
	return "res://Cutscene/Embedded/"
	
	
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
func load_cutscene_data(name:String)->Dictionary:
	var f = File.new()
	var path:String
	if "/" in name:
		path=name
	else:
		path = get_cutscene_path()+name
		if OS.is_debug_build():
			print("Got path "+path)
	var ok = f.open(path, File.READ)
	if ok != OK:
		printerr("Warning: could not open "+name+" for reading! ERROR ", ok)
		return Dictionary()
	
	var d = {
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
				"#NEXT":
					d['next']=line.lstrip("#NEXT\t")
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
	
	for arg in OS.get_cmdline_args():
		print("Cmdline arg: "+arg)
		if arg.find("=") > -1:
			var kv = arg.split("=")
			if kv[0]=="--cutscene":
				Globals.nextCutscene=kv[1]
				print("Set cutscene to "+kv[1])
				break
				
	cutsceneData = load_cutscene_data(Globals.nextCutscene)
	#if OS.is_debug_build():
	#	cutsceneData = load_cutscene_data("music_test.txt")
		#cutsceneData = load_cutscene_data("test_Midnight112.txt")
	if cutsceneData.size()==0:
		#var e = load("res://savedataError.tscn").instance()
		#e.setNewText("The cutscene failed to load.")
		#add_child(e)
		$CutscenePlayer.init_(['msg|The cutscene failed to load. Most likely the file name is incorrect.'],null)
		return
	#$AudioStreamPlayer.load_song(cutsceneData['CDAudio'])
	var msgColumn:int=1
	if "lang" in cutsceneData:
		#print(cutsceneData['lang'])
		for i in range(cutsceneData['lang'].size()):
			#print(cutsceneData['lang'][i].to_lower()+ " == "+INITrans.currentLanguage)
			if cutsceneData['lang'][i].to_lower()==INITrans.currentLanguage:
				msgColumn=i
				break
	else:
		print("no language key found in file.")
	print("Loading from column "+String(msgColumn))
	$CutscenePlayer.init_(cutsceneData['msg'],null,false,"\t",msgColumn)
	
	
	#s.hide()
func set_rect_size():
	for child in $BackgroundHolder.get_children():
		child.set_rect_size()

func _on_CutscenePlayer_cutscene_finished():
	end_cutscene_2()
	return
	
	var seq := TweenSequence.new(get_tree())
	seq._tween.pause_mode = Node.PAUSE_MODE_PROCESS
# warning-ignore:return_value_discarded
	seq.append($fadeOut,'color:a',1,.5).set_trans(Tween.TRANS_QUAD)
	seq.connect("finished",self,"end_cutscene_2")
	pass # Replace with function body.

func end_cutscene_2():
	var tmp = Globals.get_next_cutscene(Globals.currentEpisodeData,Globals.nextCutscene)
	var nextPart = tmp[0]
	var nextEpisode = tmp[1]
	
	if nextPart!="":
		print("Got new part "+nextPart+", with episode "+nextEpisode.title)
		Globals.nextCutscene=nextPart
		Globals.currentEpisodeData=nextEpisode
		get_tree().reload_current_scene()
	else:
		print("Didn't get a next part, returning to main menu.")
		#get_tree().change_scene("res://TitleScreen.tscn")
		Globals.change_screen(get_tree(),"ScreenSelectChapter")
