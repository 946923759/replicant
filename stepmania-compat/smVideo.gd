class_name smVideo
extends VideoPlayer

var cover:bool=true

func Center():
	print("smSprite.Center() has been removed")
	return
	#position=Globals.SCREEN_CENTER

func Cover():
	set_rect_size()
	cover=true

#No point, videos cover automatically
func set_rect_size():
	rect_size=Vector2(1920,1080)
	pass
	
func _process(delta):
	if self.is_playing() == false:
		play()
	
	if cover:
		var s = get_viewport().get_visible_rect().size
		if s.y > 1080:
			rect_size=Vector2(s.y*1.777777778,s.y)
			#s.x-rect_size.x
			rect_position.x = (rect_size.x-s.x)/-2
		elif s.x > 1920:
			rect_size=Vector2(s.x,s.x*0.5625)
			rect_position.y = (rect_size.y-s.y)/-2
			
func _ready():
	set_process(false)

func loadFromExternal(path:String):
	var video:VideoStream

	match path.get_extension():
		"webm":
			video = VideoStreamWebm.new()
			video.set_file(path)
		_:
			printerr("Non webm videos are not supported.")
			return false
	self.stream = video
	#set_process(true)
	return true
	
func loadVNBG(sprName:String):
	#loadFromExternal(OS.get_executable_path().get_base_dir()+"/GameData/Cutscene/Backgrounds/"+sprName)
	var f = File.new()
	if OS.has_feature("standalone") and !f.file_exists("res://Backgrounds/"+sprName+".webm"):
		for ext in [".webm"]:
			var path = OS.get_executable_path().get_base_dir()+"/GameData/Backgrounds/"+sprName+ext
			#print("Checking path "+path)
			if f.file_exists(path):
				print_debug("Found external video file at "+path)
				loadFromExternal(path)
				return true
			#else:
		printerr("background video not embedded in pck and no external file found!!")
		return false
	else:
		loadFromExternal("res://Backgrounds/"+sprName+".webm")
		return true

func hideActor(s:float,delay:float=0.0):
	var seq := get_tree().create_tween()
	seq.set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	var p=seq.tween_property(self,'modulate:a',0,s)
	if delay>=0:
		p.set_delay(delay)

func showActor(s:float,delay:float=0.0):
	play()
	set_process(true)
	var seq := get_tree().create_tween()
	seq.set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	var p=seq.tween_property(self,'modulate:a',1,s)
	if delay>=0:
		p.set_delay(delay)
	print("Video is playing!")

func hideShow(s:float,delay:float=0.0):
	var seq := get_tree().create_tween()
	seq.set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	var p=seq.tween_property(self,'modulate:a',0,s/2)
	if delay>=0:
		p.set_delay(delay)
	seq.tween_property(self,'modulate:a',1,s/2)
