class_name smSprite
extends TextureRect

func Cover():
	rect_size=Globals.gameResolution
	#Not sure why this works
	rect_pivot_offset=Globals.gameResolution/2.0
	#size_flags_horizontal=1
	stretch_mode=STRETCH_KEEP_ASPECT_COVERED
	expand=true
	
func set_rect_size():
	#print("r")
	#print(get_viewport().get_visible_rect().size)
	rect_size=get_viewport().get_visible_rect().size

func loadFromExternal(path:String):
	var file = File.new()
	var image = Image.new()
	file.open(path, File.READ)
	var buffer = file.get_buffer(file.get_len())

	match path.get_extension():
		"png":
			image.load_png_from_buffer(buffer)
		"jpg":
			image.load_jpg_from_buffer(buffer)
		"webp":
			image.load_webp_from_buffer(buffer)

	file.close()
	image.lock()
	var newTexture = ImageTexture.new()
	newTexture.create_from_image(image)
	texture=newTexture
	
func loadVNBG(sprName:String):
	#loadFromExternal(OS.get_executable_path().get_base_dir()+"/GameData/Cutscene/Backgrounds/"+sprName)
	var f = File.new()
	
	for ext in [".png",".jpg"]:
		if f.file_exists("res://Backgrounds/"+sprName+ext+".import"):
			texture=load("res://Backgrounds/"+sprName+ext)
			#print(sprName+ext)
			return true
	if OS.has_feature("standalone"):
		
		#var found = false
		for ext in [".png",".jpg"]:
			var path = OS.get_executable_path().get_base_dir()+"/GameData/Backgrounds/"+sprName+ext
			#print("Checking path "+path)
			if f.file_exists(path):
				print_debug("Found external image file at "+path)
				var image = Image.new()
				f.open(path, File.READ)
				var buffer = f.get_buffer(f.get_len())
				match path.get_extension():
					"png":
						image.load_png_from_buffer(buffer)
					"jpg":
						image.load_jpg_from_buffer(buffer)

				f.close()
				image.lock()
				var newTexture = ImageTexture.new()
				newTexture.create_from_image(image)
				texture=newTexture
				return true
			#else:
	printerr("background not embedded in pck and no external file found!!")
	return false
	
#func loadVNPortrait(sprName:String):
#	var f = File.new()
#	if OS.has_feature("standalone") and !f.file_exists("res://Cutscene/Portraits/"+sprName+".png.import"):
#		var path = OS.get_executable_path().get_base_dir()+"/GameData/Cutscene/Portraits/"+sprName+".png"
#		#print("Checking path "+path)
#		if f.file_exists(path):
#			print_debug("Found external image file at "+path)
#			var image = Image.new()
#			f.open(path, File.READ)
#			var buffer = f.get_buffer(f.get_len())
#			match path.get_extension():
#				"png":
#					image.load_png_from_buffer(buffer)
#				"jpg":
#					image.load_jpg_from_buffer(buffer)
#
#			f.close()
#			image.lock()
#			var newTexture = ImageTexture.new()
#			newTexture.create_from_image(image)
#			texture=newTexture
#		else:
#			printerr("Portrait not embedded in pck and no external file!!")
#	else:
#		texture=load("res://Cutscene/Portraits/"+sprName+".png")

func hideActor(s:float,delay:float=0.0):
	var seq := get_tree().create_tween()
	seq.set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	var p=seq.tween_property(self,'modulate:a',0,s)
	if delay>=0:
		p.set_delay(delay)

func showActor(s:float,delay:float=0.0):
	var seq := get_tree().create_tween()
	seq.set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	var p=seq.tween_property(self,'modulate:a',1,s)
	if delay>=0:
		p.set_delay(delay)

func hideShow(s:float,delay:float=0.0):
	var seq := get_tree().create_tween()
	seq.set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	var p=seq.tween_property(self,'modulate:a',0,s/2)
	if delay>=0:
		p.set_delay(delay)
	seq.tween_property(self,'modulate:a',1,s/2)

enum TWEEN_STATUS {
	NO_TWEEN,
	TWEEN_RUNNING,
	TWEEN_FINISHED
}

func is_tweening()->bool:
	return get_meta("tweening_state",0) == TWEEN_STATUS.TWEEN_RUNNING

func apply_sm_tween(tweenString) -> float:
	var tw = create_tween()
	return smTween.cmd(tw,self,tweenString) #OH BOY HERE WE GO
