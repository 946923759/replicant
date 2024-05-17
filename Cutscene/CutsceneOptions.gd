extends Control
# warning-ignore:unused_signal
signal options_closed()

const MAX_OPTION_NAME_WIDTH=600
const MAX_VALUE_WIDTH=450
const MENU_LEFT_PADDING=40

var options = {
	"continue":{
		type="none",
		hasFunc=true
	},
	"skip":{
		type="none",
		hasFunc=true
	},
	#"testOption":Globals.OPTIONS['testOption'],
	#"language":Globals.OPTIONS['language'],
	"textOptions":{
		type="submenu",
		submenu="textOptionsSubmenu"
	},
	"systemOptions":{
		type="submenu",
		submenu="systemOptionsSubmenu"
	},
	"reload":{
		type="none",
		hasFunc=true
	},
	"chapterSelect":{
		type="none",
		hasFunc=true
	},
	#"state":{
	#	type='none',
	#	hasFunc=true
	#}
}

var textOptionsSubmenu = {
	"textSpeed":Globals.OPTIONS['textSpeed'],
	"skipMode":Globals.OPTIONS['skipMode'],
	"bgOpacity":Globals.OPTIONS['bgOpacity'],
	"textboxStyle":Globals.OPTIONS['textboxStyle'],
	"skipChoicesToo":Globals.OPTIONS['skipChoicesToo']
}

func action_reload():
	get_tree().change_scene("res://Cutscene/CutsceneFromFile.tscn")

func action_chapterSelect():
	t.stop_all()
	t.interpolate_property($ScreenOut,"color:a",null,1.0,.5)
	t.start()
	#t.connect("tween_completed",self,"screenOut2")
	yield(t,"tween_completed")
	
	if anyOptionWasChanged:
		Globals.save_system_data()
		anyOptionWasChanged=false
	
	var root = get_parent()
	if root:
		print("Found cutscene player")
		Globals.change_screen(get_tree(),root.PrevScreen)
	else:
		Globals.change_screen(get_tree(),"ScreenSelectChapter")

func action_state():
	var root = get_parent()
	if root:
		Globals.playerData['state']=root.dump_state()
		get_tree().change_scene("res://Screens/TestSaveLoad.tscn")

func action_continue():
	OffCommand()

func action_skip():
	
	if anyOptionWasChanged:
		Globals.save_system_data()
		anyOptionWasChanged=false
	#Godot parent checking isn't really that good so just hard code it
	var root = get_tree().get_root().has_node("CutsceneFromFile")
	if root:
		t.interpolate_property($ScreenOut,"color:a",null,1.0,.5)
		t.start()
		get_tree().get_root().get_node("CutsceneFromFile")._on_CutscenePlayer_cutscene_finished()
	else:
		print("No cutscene player found... Assuming that this is debugging")
	#get_parent().end_cutscene()

var font = preload("res://Fonts/OptionsFont.tres")
#var displayedOptions:int=0
#onready var desc = $DescrptionF/Description
onready var selectSound = $AudioStreamPlayer

#How not to program
var mainMenuSelection:int = 0
var subMenuSelection:PoolIntArray = []
var isSubMenu:bool=false
var optionsFrame:Control #created on _init()

var anyOptionWasChanged:bool=false


onready var arrowTween = $ArrowTween
func highlightList(optFrame:Control,curSel:int):
	arrowTween.stop_all()
	if not OS.has_feature("mobile"):
		for node in optFrame.get_children():
			var isSelected=(node.name == "Item"+str(curSel))
			if isSelected:
				node.set("modulate", Color(1,1,1,1));
			else:
				node.set("modulate", Color(.5,.5,.5,1));
				
			if node.has_node("BoolOn"):
				var opt = node.get_meta("opt_name")
				#print(opt)
				highlightBool(node,Globals.OPTIONS[opt]['value'])
			elif node.has_node("Value"):
				if isSelected:
					#node.get_node("animPlayer").play("arrow")
					pass
				else:
					#node.get_node("animPlayer").stop(true)
					
					var lArrow = node.get_node("leftArrow")
					var rArrow = node.get_node("rightArrow")
					arrowTween.interpolate_property(lArrow,"rect_position:x",null,800-64*2,.1,Tween.TRANS_CUBIC,Tween.EASE_OUT)
					arrowTween.interpolate_property(rArrow,"rect_position:x",null,800+MAX_VALUE_WIDTH,.1,Tween.TRANS_CUBIC,Tween.EASE_OUT)
					#lArrow.rect_position.x=800-64*2
					#rArrow.rect_position.x=800+MAX_VALUE_WIDTH
		arrowTween.start()
	else:
		for node in optFrame.get_children():
			node.set("modulate", Color(1,1,1,1));
			if node.has_node("BoolOn"):
				var opt = node.get_meta("opt_name")
				highlightBool(node,Globals.OPTIONS[opt]['value'])
	if curSel!=-1:
		var optName = optFrame.get_child(curSel).get_meta("opt_name")
		assert($DescriptionF)
		for node in $DescriptionF.get_children():
			if node is Label:
				node.visible=(node.name == optName)
		#update_desc_size()
	
func highlightBool(node,b):
	node.get_node("BoolOff").set("modulate", Color(.5,.5,.5,1) if b else Color(1,1,1,1));
	node.get_node("BoolOn").set("modulate", Color(.5,.5,.5,1) if not b else Color(1,1,1,1));

func update_desc_size(desc:Label):
	#return
	#var width = get_viewport().get_visible_rect().size.x-50
	var width = 1920-50
	#print(desc.text)

	var width2 = desc.get("custom_fonts/font").get_string_size(desc.text).x
	if width2 > width:
		#print(width2, " above ",width, ", have to reposition")
		desc.rect_scale.x=width/width2
		#desc.rect_position.x=25*width/width2
		desc.rect_size.x=width2 #For some hilarious reason this doesn't update on its own until the next frame, so do it ourselves.
	else:
		desc.rect_scale.x=1.0
		#desc.rect_position.x=25
		desc.rect_size.x=width
	#print(desc.rect_size.x)
	#print("This desc positioned at ",desc.rect_position.x)
	
func updateValue(o:String,optionHolderNode:Control):
	var valNode = optionHolderNode.get_node("Value")
	if optionHolderNode.get_meta("opt_type")=="list":
		var text = String(Globals.OPTIONS[o]['value'])
		#print(text)
		if 'localizeKey' in Globals.OPTIONS[o]:
			text=INITrans.GetString(Globals.OPTIONS[o]['localizeKey'],text)
		#
		var width2 = font.get_string_size(text).x
		valNode.text=text

		if width2 > MAX_VALUE_WIDTH:
			valNode.rect_size.x=width2
			var scaling = MAX_VALUE_WIDTH/width2
			valNode.rect_scale.x=scaling
			#valNode.set_deferred("rect_scale:x",scaling)
			#print("Calculated width of "+String(width2)+" for str "+text)
			valNode.rect_position.x=800
			#valNode.rect_position.x=800*scaling
			#valNode.rect_size.x=width2
		else:
			#print("NoRescale")
			#valNode.set_deferred("rect_scale:x",1.0)
			valNode.rect_scale.x=1.0
			valNode.rect_position.x=800
			#valNode.rect_size.x=0
			valNode.rect_size.x=MAX_VALUE_WIDTH
		#yield(get_tree(), "idle_frame")
		#print("Scale to "+String(valNode.rect_scale.x)+", dest size is "+String(450.0*valNode.rect_scale.x))
		#print(valNode.rect_position.x)
		#print(valNode.rect_size.x)
			#valNode.rect_size.x=MAX_VALUE_WIDTH
		#print("Set new text "+text)
		#print(valNode.text)
	else:
		valNode.text=String(Globals.OPTIONS[o]['value'])
		#int types never exceed the max text width so this isn't necessary
		#valNode.rect_scale.x=1.0
		#valNode.rect_position.x=800
		#Because min_width was removed... This shouldn't be here
		valNode.rect_size.x=MAX_VALUE_WIDTH

func updateTranslation(_refresh:bool=false):
	var descActorFrame = $DescriptionF
	var descBaseActor = $DescriptionF/DescriptionBase
	
	var menus = [optionsFrame]
	for k in options:
		if options[k]['type']=="submenu":
			print("Trying to obtain "+options[k]['submenu'])
			var n = get_node_or_null(options[k]['submenu'])
			assert(n,"Submenu "+options[k]['submenu']+" doesn't exist!")
			menus.append(n)
	for f in menus:
		for node in f.get_children():
			if node.has_meta("opt_name"):
				var o = node.get_meta("opt_name")
				var tn = node.get_node("TextActor")
				tn.text=INITrans.GetString("Options",o)
				var width = font.get_string_size(tn.text).x
				if width > MAX_OPTION_NAME_WIDTH:
					var scaling = MAX_OPTION_NAME_WIDTH/width
					tn.rect_scale.x=scaling
				else:
					tn.rect_scale.x=1.0
				
				if node.has_node("Value"):
					updateValue(o,node)
				
				var d = descActorFrame.get_node_or_null(o)
				if d:
					d.text = INITrans.GetString("OptionDescriptions",o)
				else:
					d = descBaseActor.duplicate()
					d.name=o
					d.text = INITrans.GetString("OptionDescriptions",o)
					descActorFrame.add_child(d)
				update_desc_size(d)
#				#print(width)
			#for nn in node.get_children():
			#	if nn is Label:
			#		nn.set("custom_fonts/font",INITrans.font)
	#desc.text=INITrans.GetString("OptionDescriptions",optFrame.get_child(curSel).get_meta("opt_name"))
	#update_desc_size()
	#print(get_viewport().get_visible_rect().size.x-50)

#Fuck your return oriented programming
var arrowSprite = preload("res://Ext/other_329.png")
func generateMenu(optFrameActor:Control,optionsDict:Dictionary,arrowAnimation:Animation):
	var i = 0
	for option in optionsDict:
		
		var optionItem = Control.new()
		optionItem.name="Item"+str(i)
		optionItem.set_meta("opt_name",option)
		optionItem.set_meta("opt_type",optionsDict[option]['type'])
		optionItem.rect_position=Vector2(0,i*110)
		optionItem.modulate.a=0
		var optionNameActor = Def.LoadFont(font,{
			"name":"TextActor",
			"text":option,
			"uppercase":false,
			mouse_filter=MOUSE_FILTER_IGNORE
		})
		#optionNameActor.connect("mouse_entered",self,"handle_mouse_entered",[i])
		#print(parent.font.get_string_size(option))
		#print(Globals.OPTIONS[option])
		match optionsDict[option]['type']:
			"int","list":
				#optionItem.add_child(Def.Quad({
				#	rect_position=Vector2(800,0),
				#	color=Color.black,
				#	size=Vector2(MAX_VALUE_WIDTH,116)
				#}))
				optionItem.add_child(Def.LoadFont(font,{
					name="Value",
					#Cannot be set until _ready()
					#text=Globals.OPTIONS[option]['value'],
					#"uppercase":true,
					rect_position=Vector2(800,0),
					#rect_min_size=Vector2(MAX_VALUE_WIDTH,0),
					align=HALIGN_CENTER,
					mouse_filter=MOUSE_FILTER_IGNORE
				}))
				optionItem.add_child(Def.Sprite({
					name='leftArrow',
					#TextureFromDisk="res://Ext/other_329.png",
					rect_position=Vector2(800-64*2,116/2-64),
					rect_scale=Vector2(2,2),
					flip_h=true,
					mouse_filter=MOUSE_FILTER_STOP
				}))
				optionItem.add_child(Def.Sprite({
					name='rightArrow',
					#TextureFromDisk="res://Ext/other_329.png",
					rect_position=Vector2(800+MAX_VALUE_WIDTH,116/2-64),
					rect_scale=Vector2(2,2),
					mouse_filter=MOUSE_FILTER_STOP
				}))
				optionItem.get_child(1).texture=arrowSprite
				optionItem.get_child(2).texture=arrowSprite
				var animationPlayer=AnimationPlayer.new()
				animationPlayer.name="animPlayer"
				animationPlayer.add_animation("arrow",arrowAnimation)
				#animationPlayer.autoplay="arrow"
				optionItem.add_child(animationPlayer)
				
				optionItem.get_child(1).connect("gui_input",self,"handle_mouse_BoolOffOn",[optionItem,false])
				optionItem.get_child(2).connect("gui_input",self,"handle_mouse_BoolOffOn",[optionItem,true])

			"bool":
				optionItem.add_child(Def.LoadFont(font,{
					"name":"BoolOff",
					"text":"Off",
					"rect_position":Vector2(800,0),
					rect_min_size=Vector2(MAX_VALUE_WIDTH/2.0,0),
					"uppercase":true,
					align=1,
					mouse_filter=MOUSE_FILTER_STOP
				}))
				optionItem.add_child(Def.LoadFont(font,{
					"name":"BoolOn",
					"text":"On",
					"rect_position":Vector2(800+MAX_VALUE_WIDTH/2.0,0),
					rect_min_size=Vector2(MAX_VALUE_WIDTH/2.0,0),
					"uppercase":true,
					align=1,
					mouse_filter=MOUSE_FILTER_STOP
				}))
				#self.connect("draw",)
				optionItem.get_child(0).connect("gui_input",self,"handle_mouse_BoolOffOn",[optionItem,false])
				optionItem.get_child(1).connect("gui_input",self,"handle_mouse_BoolOffOn",[optionItem,true])
			_:
				pass
		
		#displayedOptions+=1
		optionItem.add_child(optionNameActor)
		i=i+1
		
		optFrameActor.add_child(optionItem)
		#optionsList.append(option)
	print("[OptionsMenu] Created new menu with "+String(i)+" options")
	#return optFrameActor

func init():
	
	#for k in Globals.OPTIONS:
	#	options[k]=Globals.OPTIONS[k]
	#options["chapterSelect"]={
	#	type="none",
	#	hasFunc=false
	#}
	#existing_children=get_child_count()
	
	#GOD WHY
	var animation:Animation = Animation.new()
	animation.loop=true
	animation.length=0.25
	
	var leftArrowAnim = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(leftArrowAnim,"leftArrow:rect_position:x")
	animation.track_set_interpolation_type(leftArrowAnim,Animation.INTERPOLATION_CUBIC)
	animation.track_insert_key(leftArrowAnim,0,800-64*2)
	animation.track_insert_key(leftArrowAnim,.25/2,800-64*2-8)
	animation.track_insert_key(leftArrowAnim,.25,800-64*2)
	
	var rightArrowAnim = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(rightArrowAnim,"rightArrow:rect_position:x")
	animation.track_set_interpolation_type(rightArrowAnim,Animation.INTERPOLATION_CUBIC)
	animation.track_insert_key(rightArrowAnim,0,800+MAX_VALUE_WIDTH)
	animation.track_insert_key(rightArrowAnim,.25/2,800+MAX_VALUE_WIDTH+8)
	animation.track_insert_key(rightArrowAnim,.25,800+MAX_VALUE_WIDTH)
	
	optionsFrame = Control.new()
	optionsFrame.name="MainMenu"
	optionsFrame.rect_position=Vector2(MENU_LEFT_PADDING,150)
	generateMenu(optionsFrame,options,animation)
	add_child(optionsFrame)
	
	var systemOptionsSubmenu = Control.new()
	systemOptionsSubmenu.name="systemOptionsSubmenu"
	systemOptionsSubmenu.rect_position=Vector2(-999,150)
	systemOptionsSubmenu.modulate.a=0
	var systemOptions:Dictionary={}
	for opt in ["AudioVolume","SFXVolume","language","vibration"]:
		systemOptions[opt]=Globals.OPTIONS[opt]
	if OS.has_feature("pc"):
		systemOptions['isFullscreen']=Globals.OPTIONS['isFullscreen']
	else:
		#Not in global options dict so can't use a func
		systemOptions['goBack']={
			type="go_back"
		}
		textOptionsSubmenu['goBack']={
			type="go_back"
		}
	
	generateMenu(systemOptionsSubmenu,systemOptions,animation)
	add_child(systemOptionsSubmenu)
	
	#TODO: This really shouldn't be hardcoded
	var textMenuActor = Control.new()
	textMenuActor.name="textOptionsSubmenu"
	textMenuActor.rect_position=Vector2(-999,150)
	textMenuActor.modulate.a=0
	generateMenu(textMenuActor,textOptionsSubmenu,animation)
	add_child(textMenuActor)
	
	subMenuSelection.resize(options.size())
	for i in range(subMenuSelection.size()):
		subMenuSelection[i]=0

func _init():
	add_child(Def.Quad({
		color=Color(0,0,0,.8),
		rect_size=Vector2(1920,1080),
		anchor_right=1,
		anchor_bottom=1
	}));
	init()
	
	
onready var t = $Tween
func _ready():
	if Globals.currentEpisodeData != null:
		var e = Globals.currentEpisodeData
		var heading:String = e.parentChapter
		#var epNum:int = 99
		#var partNum:int=99
		
		if e.parentChapter in Globals.chapterDatabase:
			var episodes = Globals.chapterDatabase[e.parentChapter]
			for i in range(episodes.size()):
				if episodes[i].title==e.title:
					heading+="-"+String(i+1)
					if episodes[i].parts.size()>1:
						for j in range(episodes[i].parts.size()):
							if episodes[i].parts[j]==Globals.nextCutscene:
								heading+="-"+String(j+1)
								break
					break
		heading+=": "+e.title
		$EpisodeDisplay/Header.text=heading
		$EpisodeDisplay/Description.text=e.desc
	elif OS.is_debug_build():
		$EpisodeDisplay/Header.text="[DEBUG] No chapter set"
		$EpisodeDisplay/Description.text=""
	else:
		$EpisodeDisplay.visible=false
	
	updateTranslation()
	OnCommand()
	#self.connect("resized",self,"update_desc_size")
	#realInitPos=position
	pass


func OnCommand():
	#print("OnCommand!")
	#t.stop_all()
	t.interpolate_property(self,"modulate:a",0.0,1.0,.5)
	#optionsFrame.modulate.a=1.0
	#optionsFrame.rect_position.x=MENU_LEFT_PADDING-50
	highlightList(optionsFrame,mainMenuSelection)
	for i in range(optionsFrame.get_child_count()):
		optionsFrame.get_child(i).modulate.a=0
		t.interpolate_property(optionsFrame.get_child(i),"rect_position:x",
		-300,0,.4,Tween.TRANS_QUAD,Tween.EASE_OUT,i*.05)
		t.interpolate_property(optionsFrame.get_child(i),"modulate:a",
		0,1,.4,Tween.TRANS_QUAD,Tween.EASE_OUT,i*.05)
	t.start()
	
	
#	for n in systemOptionsSubmenu.get_children():
#		#print(n.get_meta("opt_type"))
#		#breakpoint
#		match n.get_meta("opt_type"):
#			"list","int":
#				n.get_node("leftArrow" ).mouse_filter=MOUSE_FILTER_IGNORE
#				n.get_node("rightArrow").mouse_filter=MOUSE_FILTER_IGNORE
	#yield(t,"tween_completed")
	#tweenMainMenuOut()
	pass
	#updateFocus()
func OffCommand():
	if anyOptionWasChanged:
		Globals.save_system_data()
		anyOptionWasChanged=false
	#t.stop_all()
	var seq = get_tree().create_tween()
	seq.tween_property(self,"modulate:a",0.0,.5)
	seq.set_parallel(true)
	var n = optionsFrame.get_child_count()
	for i in range(n):
		seq.tween_property(optionsFrame.get_child(i),"rect_position:x",
		-300,.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay((n-i)*.05)
		seq.tween_property(optionsFrame.get_child(i),"modulate:a",
		0,.4).set_delay((n-i)*.05)
	
	print("Broadcasting options closed")
	seq.set_parallel(false)
	seq.tween_callback(self,"emit_signal",["options_closed"])
	seq.tween_property(self,"visible",false,0.0)
	#self.visible=false
	pass
#func updateFocus():

func anim_option_value(optNode:Control,going_right:bool):
	selectSound.play()
	if going_right:
		var rArrow = optNode.get_node("rightArrow")
		arrowTween.interpolate_property(rArrow,"rect_position:x",800+MAX_VALUE_WIDTH+16,800+MAX_VALUE_WIDTH,.1,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	else:
		var lArrow = optNode.get_node("leftArrow")
		arrowTween.interpolate_property(lArrow,"rect_position:x",800-64*2-16,800-64*2,.1,Tween.TRANS_CUBIC,Tween.EASE_OUT)
			#lArrow.rect_position.x=800-64*2
			#rArrow.rect_position.x=800+MAX_VALUE_WIDTH
	#print("A")
	arrowTween.start()
	
func handle_option(optNode:Control,going_right:bool=true):
	anyOptionWasChanged=true
	var option:String=optNode.get_meta("opt_name")
	match optNode.get_meta("opt_type"):
		"bool":
			Globals.OPTIONS[option]['value']=going_right
			selectSound.play()
			highlightBool(optNode,going_right)
			if option=="isFullscreen":
				Globals.set_fullscreen(going_right)
			print("[OptionsScreen] Set option "+option+" to "+String(Globals.OPTIONS[option]['value']))
		"int":
			var val:int = int(Globals.OPTIONS[option]['value'])
			print("got value "+String(val))
			if going_right:
				if val < 100:
					val+=10
					Globals.OPTIONS[option]['value']=val
					optNode.get_node("Value").text=String(val)
					if option=="AudioVolume" or option=="SFXVolume" or option=="VoiceVolume":
						#if parent.reinaAudioPlayer.nsf_player != null:
						#	var realVolumeLevel = Globals.OPTIONS['AudioVolume']['value']*.6-60
						#	parent.reinaAudioPlayer.nsf_player.set_volume(realVolumeLevel);
						Globals.set_audio_levels()
					anim_option_value(optNode,going_right)
			elif val > 0:
				val-=10
				Globals.OPTIONS[option]['value']=val
				optNode.get_node("Value").text=String(val)
				if option=="AudioVolume" or option=="SFXVolume" or option=="VoiceVolume":
					Globals.set_audio_levels()
				anim_option_value(optNode,going_right)
		"list":
			var val = Globals.OPTIONS[option]['value']
			var idx = Globals.OPTIONS[option]['choices'].find(val,0)
			if idx==-1 and typeof(val)==TYPE_REAL: #Because of json weirdness
				idx = Globals.OPTIONS[option]['choices'].find(int(val),0)
			#print("[OptionsMenu] found value at idx "+String(idx))
			if idx==-1:
				print("[OptionsMenu] could not find value "+String(val)+" in list")
				#if Globals.OPTIONS[option]['type']
				#print(typeof(val))
				
				print(Globals.OPTIONS[option]['choices'])
			if going_right:
				if idx < len(Globals.OPTIONS[option]['choices'])-1:
					Globals.OPTIONS[option]['value']=Globals.OPTIONS[option]['choices'][idx+1]
					if option=="language":
						INITrans.SetLanguage(Globals.OPTIONS[option]['value'])
						updateTranslation(true)
						#desc.text=INITrans.GetString("OptionDescriptions",option)
						#update_desc_size()
					print("[OptionsMenu] Set option "+option+" to "+String(Globals.OPTIONS[option]['value']))
					updateValue(option,optNode)
					anim_option_value(optNode,going_right)
			elif idx > 0:
				Globals.OPTIONS[option]['value']=Globals.OPTIONS[option]['choices'][idx-1]
				if option=="language":
					INITrans.SetLanguage(Globals.OPTIONS[option]['value'])
					#desc.text=INITrans.GetString("OptionDescriptions",option)
					updateTranslation(true)
					#update_desc_size()
				print("[OptionsMenu] Set option "+option+" to "+String(Globals.OPTIONS[option]['value']))
				updateValue(option,optNode)
				anim_option_value(optNode,going_right)

func get_current_submenu(curSel:int)->Node:
	var curOpt = optionsFrame.get_child(curSel)
	var optName = curOpt.get_meta("opt_name")
	return get_node(options[optName]['submenu'])

func _input(event):
	if not visible:
		return
	var menuSize:int=0
	var curSel:int=mainMenuSelection
	var curMenu=optionsFrame
	if isSubMenu:
		curSel=subMenuSelection[mainMenuSelection]
		curMenu=get_current_submenu(mainMenuSelection)
		menuSize=curMenu.get_child_count()
	else:
		menuSize=optionsFrame.get_child_count()
	
	if Input.is_action_pressed("ui_down"):
		if curSel < menuSize-1:
			curSel+=1
		else: #If at bottom, loop to top
			curSel=0
		highlightList(curMenu,curSel)
		#if selection > 5:
		#	moveListUp()
		selectSound.play()
	elif Input.is_action_pressed("ui_up"):
		if curSel > 0:
			curSel-=1
		else: #if selection is -1 or at top, loop to bottom
			curSel=menuSize-1
		highlightList(curMenu,curSel)
		#if selection < 6:
		#	moveListDown()
		selectSound.play()
	elif Input.is_action_pressed("ui_left"):
		if curSel==-1:
			return
		var option = curMenu.get_child(curSel)
		handle_option(option,false)
		get_tree().set_input_as_handled()
	elif Input.is_action_pressed("ui_right"):
		if curSel==-1:
			return
		var option = curMenu.get_child(curSel)
		handle_option(option)
		get_tree().set_input_as_handled()
	elif Input.is_action_pressed("ui_select") or (event is InputEventMouseButton and event.button_index==1 and event.pressed) or (event is InputEventScreenTouch and event.index==1):
		
		if event is InputEventMouseButton or event is InputEventScreenTouch:
			curSel=get_selection_from_mouse_pos(curMenu,event)
			#if event is InputEventScreenTouch and curSel != -1:
			#	highlightList(curMenu,curSel)
			#Do not handle input if the mouse is in the 'value' side
			if event.position.x > curMenu.rect_global_position.x+MAX_OPTION_NAME_WIDTH:
				#if curSel!=-1:
				#	var curOpt = curMenu.get_child(curSel)
				#	var hasArrows = curOpt.get_meta("opt_type")
				#	if event.position.x > curOpt.
				#	handle_option(curOpt,onOrOff)
				#	get_tree().set_input_as_handled()
				return
			get_tree().set_input_as_handled()
			print("Got selection "+String(curSel)+" from input at "+String(event.position))
			
		if curSel!=-1:
			var curOpt = curMenu.get_child(curSel)
			var optName = curOpt.get_meta("opt_name")
			print("triggering "+optName)
			match curOpt.get_meta("opt_type"):
				"submenu":
					var submenu = get_node(options[optName]['submenu'])
					highlightList(submenu,subMenuSelection[curSel])
					tweenMainMenuOut(curSel);
					mainMenuSelection=curSel
					isSubMenu=true
					return
				"none":
					if optName in options and options[optName]['hasFunc']:
						call("action_"+optName)
				"go_back":
					tweenMainMenuIn();
					highlightList(optionsFrame,mainMenuSelection) #This just updates the description
					isSubMenu=false
				_:
					print("Unhandled option!")
	elif Input.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.button_index==2 and event.pressed):
		handle_back_button()
		return
	elif event is InputEventMouseMotion:
		var tmpSel=get_selection_from_mouse_pos(curMenu,event)
		if tmpSel!=curSel:
			highlightList(curMenu,tmpSel)
			curSel=tmpSel

	#TODO: This only triggers on mouse motion
	if isSubMenu:
		subMenuSelection[mainMenuSelection]=curSel
	else:
		mainMenuSelection=curSel

func handle_back_button():
	if t.is_active(): #Because right clicking opens the options menu and this doesn't take into account that it's been handled...
		return
	if isSubMenu:
		tweenMainMenuIn();
		highlightList(optionsFrame,mainMenuSelection) #This just updates the description
		isSubMenu=false
		#return
	else:
		OffCommand()

func handle_input_accept():
	print("Clicked")
	pass

func handle_mouse_BoolOffOn(event:InputEvent,optionItem:Control,onOrOff:bool):
	#OptionItems don't know if they're visible or not, so check if the menu
	#is currently active
	if (event is InputEventMouseButton and event.button_index==1 and event.pressed): #
		print("[OptionsMenu] Clicked item "+optionItem.get_meta("opt_name"))
		if optionItem.get_parent().modulate.a<.9:
			print("[OptionsMenu] menu not visible, ignore...")
			return
		#print(optionItem.get_parent().name)
		#print(optionItem.get_parent().modulate)
		#breakpoint
		#var curMenu=optionsFrame
		#if isSubMenu:
		#	curMenu=systemOptionsSubmenu
		#var option = curMenu.get_child(selection)
		handle_option(optionItem,onOrOff)
		get_tree().set_input_as_handled()

func get_selection_from_mouse_pos(menuToCheck:Control,event:InputEvent)->int:
	#Good luck. You're going to need it.
	var curSel=-1
	for i in range(menuToCheck.get_child_count()):
		
		var actor = menuToCheck.get_child(i)
		if actor.rect_global_position.y < event.position.y and event.position.y < actor.rect_global_position.y+105:
			#print("Guessed? "+String(i))
			curSel = i
			break
	return curSel

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		handle_back_button()

func tweenMainMenuOut(subMenuToTween:int=2):
	#TODO: Remove this shit and replace it with the newer tweens
	
	#First tween out main menu
	var tween = $Tween;
	tween.interpolate_property(optionsFrame, 'rect_position:x',
	null, MENU_LEFT_PADDING-200, .25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	tween.interpolate_property(optionsFrame, 'modulate',
	null, Color(1,1,1,0), .25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	tween.interpolate_property($GridContainer, 'modulate',
	null, Color(1,1,1,0), .15, Tween.TRANS_QUAD, Tween.EASE_OUT);
	
	#Tween in the submenu
	var property = "rect_position:x"
	
	var subList = get_current_submenu(subMenuToTween);
	tween.interpolate_property(subList, property,
	MENU_LEFT_PADDING+200,
	MENU_LEFT_PADDING,
	.25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	tween.interpolate_property(subList, 'modulate:a',
	null, 1.0, .25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	tween.start();
	#yield(tween,"tween_completed")
	#breakpoint
	
	
#	#Godot, in its infinite wisdom, makes it so pass goes UP, not DOWN
#	#Meaning the language button will cover the main menu text button
#	#So we have to set MOUSE_FILTER to ignore when tweening the menu out
#	for n in systemOptionsSubmenu.get_children():
#		match n.get_meta("opt_type"):
#			"list","int":
#				n.get_node("leftArrow" ).mouse_filter=MOUSE_FILTER_STOP
#				n.get_node("rightArrow").mouse_filter=MOUSE_FILTER_STOP
#	for n in optionsFrame.get_children():
#		match n.get_meta("opt_type"):
#			"list","int":
#				n.get_node("leftArrow" ).mouse_filter=MOUSE_FILTER_IGNORE
#				n.get_node("rightArrow").mouse_filter=MOUSE_FILTER_IGNORE


func tweenMainMenuIn():
	
	#Tween the main menu back in
	var tween = $Tween;
	tween.interpolate_property(optionsFrame, 'rect_position:x',
	null, MENU_LEFT_PADDING, .25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	tween.interpolate_property(optionsFrame, 'modulate',
	null, Color(1,1,1,1), .25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	tween.interpolate_property($GridContainer, 'modulate',
	null, Color(1,1,1,1), .25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	
	
	#Tween the submenu out
	var subMenu = get_current_submenu(mainMenuSelection)
	var property = "rect_position:x"
	tween.interpolate_property(subMenu, property,
	null,
	MENU_LEFT_PADDING+200,
	.25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	tween.interpolate_property(subMenu, 'modulate:a',
	null, 0.0, .25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	tween.start();
	
#	#Godot, in its infinite wisdom, makes it so pass goes UP, not DOWN
#	#Meaning the language button will cover the main menu text button
#	#So we have to set MOUSE_FILTER to ignore when tweening the menu out
#	for n in systemOptionsSubmenu.get_children():
#		match n.get_meta("opt_type"):
#			"list","int":
#				n.get_node("leftArrow" ).mouse_filter=MOUSE_FILTER_IGNORE
#				n.get_node("rightArrow").mouse_filter=MOUSE_FILTER_IGNORE
#	for n in optionsFrame.get_children():
#		match n.get_meta("opt_type"):
#			"list","int":
#				n.get_node("leftArrow" ).mouse_filter=MOUSE_FILTER_STOP
#				n.get_node("rightArrow").mouse_filter=MOUSE_FILTER_STOP
