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
		print("[smSound] Warning: No music found for "+custom_music_name)

func load_sound(custom_music_name:String):
	var music = get_custom_sound(custom_music_name) if custom_music_name != "" else null
	if music != null:
		print("[smSound] Attempting to load "+music)
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
	if !OS.has_feature("standalone") or OS.has_feature("console"):
		return Globals.get_closest_file("res://Music/CDAudio/",fname)
	return Globals.get_closest_file(OS.get_executable_path().get_base_dir()+"/Music/",fname)

#TODO: Fix it
func get_custom_sound(fname):
	if true: #!OS.has_feature("standalone") or OS.has_feature("console")
		return Globals.get_closest_file("res://Sounds/",fname)
	return Globals.get_closest_file(OS.get_executable_path().get_base_dir()+"/Sounds/",fname)
