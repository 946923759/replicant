extends Node2D

#arrays can't be const since they're passed by reference
var SCREEN_CENTER_X
const IMAGE_CENTER_X = 512 #Size of image/2
var portraitPositions:Array

var lastLoaded: String
var offset: int
var numPortraits:int = 0
var idx: int = -1
var is_active:bool = false
export var is_masked:bool=false

#TODO: zoomx/zoomy will break the zoom level, which should be a multiple of this.
#Tweens need to take into account this value.
var zoom_level:float = 1.0

var portrait_textures:Dictionary={}
var expressions_are_overlays = false
var overlay_offset:Vector2
var cur_expression:String="0" setget set_cur_expression
var mask1 = preload("res://Cutscene/maskBox.png")
var mask2 = preload("res://Cutscene/maskBox2.png")

var numberTex = preload("res://Graphics/groove gauge 1x10.png")
#var activeTex = preload("res://Graphics/spriteActiveDebug.png")

#TODO: PortraitManager tween is all we really need, right?
var tween:Tween
var blendAdd:Light2D
#onready var tween = Tween.new()

func set_cur_expression(e:String):
	if !portrait_textures.has(e):
		if e!="0":
			printerr("Portrait "+String(lastLoaded)+" doesn't have an expression at "+String(e)+"!! "+String(portrait_textures.keys()))
	else:
		cur_expression=e
		update()

func _draw():
	if !portrait_textures.has(cur_expression):
		return
	elif portrait_textures.size()==0 or !is_instance_valid(portrait_textures[cur_expression]):
		#print("No texture present at idx "+String(cur_expression)+".")
		return
	if is_masked:
		draw_texture(mask1,Vector2(-196,14))
		if expressions_are_overlays and cur_expression != "0":
			draw_texture_rect_region(portrait_textures["0"],
				Rect2(-319/2,26,319,457), #Destination
				Rect2(IMAGE_CENTER_X-319/2,0,319,457) #Source
			)
			draw_texture_rect_region(
				portrait_textures[cur_expression],
				Rect2(
					IMAGE_CENTER_X-319/2+overlay_offset.x,
					26+overlay_offset.y,
					256,
					256
				),
				Rect2(0,0,256,256)
			)
			#draw_texture(portrait_textures[cur_expression],Vector2(-IMAGE_CENTER_X,0)+overlay_offset)

		else:
			draw_texture_rect_region(portrait_textures[cur_expression],
				Rect2(-319/2,26,319,457),
				Rect2(IMAGE_CENTER_X-319/2,0,319,457)
			)
		#I'm pretty sure this isn't a normal overlay because it's not that blue in gfl.
		#There's also the whole distortion thing but I don't know how that's done (Is it a shader?).
		draw_texture(mask2,Vector2(-319/2,25),Color(1,1,1,.8))
	elif expressions_are_overlays and cur_expression != "0":
		draw_texture(portrait_textures["0"],Vector2(-IMAGE_CENTER_X,0))
		draw_texture(portrait_textures[cur_expression],Vector2(-IMAGE_CENTER_X,0)+overlay_offset)
	else:
		draw_texture(portrait_textures[cur_expression],Vector2(-IMAGE_CENTER_X,0))
		
	if OS.is_debug_build(): #
		draw_texture_rect_region(numberTex,
			Rect2(0,0,31,24),
			Rect2(0,24*idx,31,24)
		)
		#Texture, dest, source
		#var xOff = int(is_active)*16
		#draw_texture_rect_region(activeTex,
		#	Rect2(0,64,16*4,8*4),
		#	Rect2(xOff,0,16,8)
		#)
		
	

func _ready():
	#add_child(tween)
	#tween=$Tween
	tween = Tween.new()
	add_child(tween)
	
	#blendAdd = Light2D.new()
	#blendAdd.texture = load("res://Cutscene/VN MaskOverlay (stretch).png")
	
	#I don't know how to do it....
	#var b = load("res://Cutscene/BlendAddLoop.tscn")
	#blendAdd = b.instance()
	#add_child(blendAdd)
	update_portrait_positions(float(get_viewport().get_visible_rect().size.x))

#TODO: This isn't correct, it will break after applying a tween.
func calc_portrait_position() -> float:
	return portraitPositions[numPortraits-1][idx]+offset*100

func update_portrait_positions(SCREEN_WIDTH:float):
	SCREEN_CENTER_X = SCREEN_WIDTH/2.0
	var SCREEN_RATIO = SCREEN_WIDTH/1920
	#For loops? where we're going we don't need for loops
	portraitPositions = [
		[SCREEN_CENTER_X],
		[SCREEN_CENTER_X-300*SCREEN_RATIO,SCREEN_CENTER_X+300*SCREEN_RATIO], #separation of 600px
		[SCREEN_CENTER_X-400*SCREEN_RATIO,SCREEN_CENTER_X,SCREEN_CENTER_X+400*SCREEN_RATIO], #400px...
		[SCREEN_CENTER_X-450*SCREEN_RATIO,SCREEN_CENTER_X-150*SCREEN_RATIO,SCREEN_CENTER_X+150*SCREEN_RATIO,SCREEN_CENTER_X+450*SCREEN_RATIO], #300px...
		[SCREEN_CENTER_X-600*SCREEN_RATIO,SCREEN_CENTER_X-300*SCREEN_RATIO,SCREEN_CENTER_X,SCREEN_CENTER_X+300*SCREEN_RATIO,SCREEN_CENTER_X+600*SCREEN_RATIO] #300px
	]
	
	if is_active:
		position.x=calc_portrait_position()

#
func position_portrait(idx_:int,isMasked:bool,_offset:int,numPortraits_:int):
	#return false
	print("curPortrait is "+lastLoaded)
	if _offset==null:
		offset=0
	else:
		offset = _offset
		_offset*=100
	
	#self._offset = _offset;
	self.idx=idx_; #Needed for dim/hl to function
	self.numPortraits=numPortraits_
	assert(numPortraits>0,"Attempting to position portraits when none are displayed")
	
	
	print("idx: "+String(idx)+" numPortraits: "+String(numPortraits)+ " offset: "+String(_offset))
	if is_active:
		#Trace(portraitPositions[numPortraits][idx])
		#Trace(portraitPositions[numPortraits][idx]+self.offset)
		
		#self.actor:stoptweening():decelerate(.2):x(portraitPositions[numPortraits][idx]+self.offset)
		tween.remove_all()
		tween.interpolate_property(self,
			'position:x',
			null,
			portraitPositions[numPortraits-1][idx]+_offset,
			.5, Tween.TRANS_QUAD, Tween.EASE_OUT
		);
		tween.start();
		return
	
	is_active = true #Because dimming will make invisible portraits visible...
	#assert(fileName)
	#self.actor:Load(THEME:GetPathB("StoryArea","overlay/"..fileName));
	#self.actor:stoptweening():diffusealpha(0);
	#self.set_modulate(Color(1,1,1,0))
	
	#self.actor:z(offset);
	
	
	
	assert(len(portraitPositions)>numPortraits-1, "portraitPositions doesn't go up to "+String(numPortraits))
	assert(portraitPositions[numPortraits-1][idx],"Tried to position a portrait at "+String(idx)+" but there's only "+String(numPortraits)+" currently displayed")
	
	is_masked=isMasked

	#Need to update if we're changing mask
	#This update call doesn't seem to work properly for displaying
	#the idx, I'm not sure why
	update() 

	#Because this makes way too much sense right
	#Fuck godot the tweens suck complete ass
	#self.actor:x(portraitPositions[numPortraits][idx]+self.offset+100):decelerate(.2):x(portraitPositions[numPortraits][idx]+self.offset):diffusealpha(1)
	var endPosition = portraitPositions[numPortraits-1][idx]+_offset
	#var endPosition= SCREEN_CENTER_X
	print("End position "+String(endPosition))
	#offset.x = endPosition+100 if endPosition <= SCREEN_CENTER_X else endPosition-100
	#position.x = 0.0
	#modulate.a=1.0
	#print(offset)
	#print(modulate)
	tween.remove_all()
	if false: #Does not work properly yet. Tween probably is the wrong way to do it and it needs to be done with manual drawing
		position.x=endPosition
		tween.interpolate_property(self,
			'scale:y',
			0,
			1,
			.5, Tween.TRANS_QUAD, Tween.EASE_OUT
		);
	else:
		tween.interpolate_property(self,
			'position:x',
			#null,
			endPosition+100 if endPosition <= SCREEN_CENTER_X else endPosition-100,
			endPosition,
			.5, Tween.TRANS_QUAD, Tween.EASE_OUT
		);
	tween.interpolate_property(self,
		'modulate:a',
		0.0,
		1.0,
		.5, Tween.TRANS_QUAD, Tween.EASE_OUT
	);
	tween.start();


func stoptweening():
	tween.remove_all()
	if is_active:
		modulate.a=1.0
		position.x = calc_portrait_position()
	else:
		modulate.a=0.0

#What if I want to remove portraits without a tween? Or add portraits without a tween?
func stop():
	#return
	tween.remove_all()
	tween.interpolate_property(self,
		'position:x',
		null,
		self.get_position().x + 100 if self.get_position().x >= SCREEN_CENTER_X else self.get_position().x - 100,
		.5, Tween.TRANS_SINE, Tween.EASE_IN
	);
	tween.interpolate_property(self,
		'modulate:a',
		null,
		0.0,
		.5, Tween.TRANS_QUAD, Tween.EASE_IN
	);
	tween.start();
	is_active=false
	idx=-1
	update()
	
func dim():
	tween.interpolate_property(self,
		'modulate',
		null,
		Color(.5,.5,.5,1),
		.3
	);
	tween.start();

func undim():
	if !is_active:
		print("Portrait was asked to highlight, but it's not active?")
		print("idx: "+String(idx)+" offset: "+String(offset))
		return
	tween.interpolate_property(self,
		'modulate',
		null,
		Color(1,1,1,1),
		.3
	);
	tween.start();

func is_tweening()->bool:
	return tween.is_active()
	
func apply_sm_tween(tweenString) -> float:
	var tw = get_tree().create_tween()
	return smTween.cmd(tw,self,tweenString) #OH BOY HERE WE GO

func gestalt_set_textures(sprName):
	var matching = Globals.get_closest_file("res://Portraits",sprName)
	if not matching:
		printerr("No texture exists named "+sprName)
		return false
	
	portrait_textures = Dictionary()
	
	var foundDefaultYet:bool=false
	for path in matching:
		if !path.ends_with(".png"):
			continue
		var emotes = path.split(" ",1) 
		
		if emotes.size() >= 2: #Kyuushou normal.png, Kyuushou happy.png, etc
			#Index this portrait like ['normal'] = TEXTURE
			portrait_textures[emotes[1].trim_suffix(".png")] = load(path)
		else: #Kyuushou.png
			if foundDefaultYet:
				printerr("Found image "+path+" without an expression, but there was already another loaded...")
			else:
				#Index in default slot '0'
				portrait_textures['0']=load(path)
				foundDefaultYet = true


func replicant_set_textures(toLoad:Dictionary):
	portrait_textures = Dictionary()
	#portrait_textures.resize(toLoad.size())
	#imageTex=Array()
	#imageTex.resize(toLoad.size())
	for emoteName in toLoad:
		var sprName = toLoad[emoteName].trim_suffix(".png")
		#set_texture(load("res://Cutscene/Portraits/"+sprName+".png"))
		var f = File.new()
		if f.file_exists("res://Portraits/"+sprName+".png.import"):
			portrait_textures[emoteName]=load("res://Portraits/"+sprName+".png")
		elif OS.has_feature("standalone"):
			var path = OS.get_executable_path().get_base_dir()+"/GameData/Portraits/"+sprName+".png"
			#print("Checking path "+path)
			if f.file_exists(path):
				print("Found external image file at "+path)
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

				portrait_textures[emoteName]=ImageTexture.new()
				portrait_textures[emoteName].create_from_image(image);
				#print(portrait_textures[i])
			else:
				printerr("Portrait "+sprName+" not embedded in pck and no external file!! Tried path "+path)
		else:
			printerr("Portrait "+sprName+" not embedded in pck and no external file!!")
			
	expressions_are_overlays = false
	update()

func set_texture_wrapper(sprName):
	lastLoaded=sprName
	cur_expression="0"
	if sprName in Globals.database:
		var toLoad:Array = Globals.database[sprName]
		if toLoad.size() >= 4 or toLoad.size() == 1:
			print("Got textures to load... "+String(toLoad))
			var newDict = {
				"0":toLoad[0]
			}
			if toLoad.size() >= 4:
				# Additional portraits instead of expressions
				for i in range(len(toLoad[3])):
					newDict[String(i+1)]=toLoad[3][i]
			replicant_set_textures(newDict)
			expressions_are_overlays = false
		else:
			print("Got textures to load (overlay)... "+String(toLoad))
			var newDict = {
				"0":toLoad[0]
			}
			for i in range(1,toLoad[1]+1):
				newDict[String(i)]=toLoad[0]+"_"+String(i).pad_zeros(3)
			replicant_set_textures(newDict)
			overlay_offset = toLoad[2]
			expressions_are_overlays = true
			
	else:
		print(sprName+" not in portrait database! Falling back...")
		gestalt_set_textures(sprName)
		expressions_are_overlays = false
