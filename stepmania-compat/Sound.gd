class_name smSound
extends AudioStreamPlayer

#const ExternalAudio = preload("res://stepmania-compat/GDScriptAudioImport.gd")
var t:Tween

func _init():
	t=Tween.new()
	self.add_child(t)

func load_song(custom_music_name:String, autoplay=true):
	print("[smSound] begin checking paths for a song named "+custom_music_name)
	var music = get_custom_music(custom_music_name) if custom_music_name != "" else null
	if music:
		print("[smSound] Attempting to load music track "+music)
		if music.ends_with(".import"):
			self.stream = load(music.replace('.import', ''))
		else:
			self.stream = ExternalAudio.loadfile(music)
		if autoplay:
			self.play()
			t.remove_all()
			self.volume_db=0.0
	else:
		print("[smSound] Warning: No music found for "+custom_music_name)

func load_sound(custom_music_name:String):
	var music = get_custom_sound(custom_music_name) if custom_music_name != "" else null
	if music:
		print("[smSound] Attempting to load sound effect "+music)
		if music.ends_with(".import"):
			self.stream = load(music.replace('.import', ''))
		else:
			self.stream = ExternalAudio.loadfile(music,false)
	else:
		print("[smSound] Warning: No sound effect found for "+custom_music_name)
		

func fade_music(time:float=3.0):
	if time <=0:
		stop_music()
	else:
		t.interpolate_property(self,"volume_db",null,-35,time)
		t.interpolate_property(self,"playing",null,false,0.0,Tween.TRANS_LINEAR,Tween.EASE_IN,time)
		t.start()
		
func stop_music():
	self.stop()
		
func pause_music():
	self.playing=false

func get_custom_music(fname):
	# Godot bug https://github.com/godotengine/godot/issues/87274
	# ...And we include music in external .pcks anyways
	if Globals.installedPacks > 0:
		for fType in [".mp3",".ogg"]:
			var fullPathAndName = "res://Music/CDAudio/"+fname+fType
			if ResourceLoader.exists(fullPathAndName):
				print("[smSound] got "+fname+" from a loaded PCK")
				return fullPathAndName + ".import"
		#return null
	
	if !OS.has_feature("standalone") or OS.has_feature("console"):
		return Globals.get_closest_file("res://Music/CDAudio/",fname)
	return Globals.get_closest_file(OS.get_executable_path().get_base_dir()+"/Music/",fname)

#TODO: Fix it
func get_custom_sound(fname):
	if true: #!OS.has_feature("standalone") or OS.has_feature("console")
		return Globals.get_closest_file("res://Sounds/",fname)
	return Globals.get_closest_file(OS.get_executable_path().get_base_dir()+"/Sounds/",fname)
