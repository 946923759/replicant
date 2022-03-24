class_name smSound
extends AudioStreamPlayer

#const ExternalAudio = preload("res://stepmania-compat/GDScriptAudioImport.gd")
var t:Tween

func _init():
	t=Tween.new()
	self.add_child(t)

func load_song(custom_music_name:String,autoplay=true):
	#return
	var music = get_custom_music(custom_music_name) if custom_music_name != "" else null
	if music != null:
		print("Attempting to load "+music)
		if music.ends_with(".import"):
			self.stream = load(music.replace('.import', ''))
		else:
			self.stream = ExternalAudio.loadfile(music)
		if autoplay:
			self.play()
			t.remove_all()
			self.volume_db=0.0
	else:
		print("Warning: No music found for "+custom_music_name)
		

func fade_music(time:float=3.0):
	if time <=0:
		stop_music()
	else:
		t.interpolate_property(self,"volume_db",null,-60,time)
		t.start()
		
func stop_music():
	self.stop()
		
func pause_music():
	pass

func get_custom_music(fname):
	if !OS.has_feature("standalone") or OS.has_feature("console"):
		return Globals.get_matching_files("res://Music/CDAudio/",fname)
	return Globals.get_matching_files(OS.get_executable_path().get_base_dir()+"/CustomMusic/",fname)
