extends Control
const MAX_OPTION_NAME_WIDTH=400
const MAX_VALUE_WIDTH=450
const MENU_LEFT_PADDING=40

var options = {
	"resume":{
		type="none"
	},
	"skip":{
		type="none"
	},
	"textSpeed":Globals.OPTIONS['textSpeed'],
	#"language":Globals.OPTIONS['language'],
	"systemOptions":{
		type="submenu",
		submenu="systemOptionsSubmenu"
	},
	"chapterSelect":{
		type="none",
		hasFunc=false
	}
}

	

var font = preload("res://Fonts/OptionsFont.tres")
var existing_children:int=0 #This is dead code, keep it at 0
#var displayedOptions:int=0
onready var desc = $DescrptionF/Description
onready var selectSound = $AudioStreamPlayer

#How not to program
var selection:int = 0
var subMenuSelection:int=0
var isSubMenu:bool=false
var optionsFrame:Control #created on _init()
var systemOptionsSubmenu:Control


onready var arrowTween = $TweenForArrows
func highlightList(optFrame:Control,curSel:int):
	arrowTween.stop_all()
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
				node.get_node("animPlayer").play("arrow")
			else:
				node.get_node("animPlayer").stop(true)
				
				var lArrow = node.get_node("leftArrow")
				var rArrow = node.get_node("rightArrow")
				arrowTween.interpolate_property(lArrow,"rect_position:x",null,800-64*2,.1,Tween.TRANS_CUBIC,Tween.EASE_OUT)
				arrowTween.interpolate_property(rArrow,"rect_position:x",null,800+MAX_VALUE_WIDTH,.1,Tween.TRANS_CUBIC,Tween.EASE_OUT)
				#lArrow.rect_position.x=800-64*2
				#rArrow.rect_position.x=800+MAX_VALUE_WIDTH
	arrowTween.start()
func highlightBool(node,b):
	node.get_node("BoolOff").set("modulate", Color(.5,.5,.5,1) if b else Color(1,1,1,1));
	node.get_node("BoolOn").set("modulate", Color(.5,.5,.5,1) if not b else Color(1,1,1,1));

#SERIOUSLY DOES ANYONE ELSE THINK THIS IS FUCKING STUPID
#func tweenRightArrow(arrowTween,obj):
#	arrowTween.interpolate_property(obj,"rect_position:x",null,obj.rect_position.x+32,.5,Tween.TRANS_CUBIC,Tween.EASE_IN,0)
#	arrowTween.interpolate_property(obj,"rect_position:x",obj.rect_position.x+32,obj.rect_position.x,.5,Tween.TRANS_CUBIC,Tween.EASE_IN,.5)
#func tweenLeftArrow(arrowTween,obj):
#	arrowTween.interpolate_property(obj,"rect_position:x",null,obj.rect_position.x-32,.5,Tween.TRANS_CUBIC,Tween.EASE_IN,0)
#	arrowTween.interpolate_property(obj,"rect_position:x",obj.rect_position.x-32,obj.rect_position.x,.5,Tween.TRANS_CUBIC,Tween.EASE_IN,.5)
#lArrowReverse:bool=false
#rArrowReverse:bool=true
func _on_TweenForArrows_tween_completed(object, key):
	pass
#	print(key)
#	if object.name=="leftArrow":
#		tweenLeftArrow(arrowTween,object)
#	else:
#		tweenRightArrow(arrowTween,object)
	
func updateValue(o:String,optionHolderNode:Control):
	var valNode = optionHolderNode.get_node("Value")
	if optionHolderNode.get_meta("opt_type")=="list":
		var text = String(Globals.OPTIONS[o]['value'])
		#print(text)
		if 'localizeKey' in Globals.OPTIONS[o]:
			text=INITrans.GetString(Globals.OPTIONS[o]['localizeKey'],text)
		#print("Set new text "+text)
		var width2 = font.get_string_size(text).x
		if width2 > MAX_VALUE_WIDTH:
			var scaling = MAX_VALUE_WIDTH/width2
			valNode.rect_scale.x=scaling
		else:
			valNode.rect_scale.x=1.0
		valNode.text=text
	else:
		valNode.text=String(Globals.OPTIONS[o]['value'])

func updateTranslation(refresh:bool=false,t:String=""):
	for f in [optionsFrame,systemOptionsSubmenu]:
		for node in f.get_children():
			if node.has_meta("opt_name"):
				var o = node.get_meta("opt_name")
				var tn = node.get_node("TextActor")
				tn.text=INITrans.GetString("VNOptions",o)
				var width = font.get_string_size(tn.text).x
				if width > MAX_OPTION_NAME_WIDTH:
					var scaling = MAX_OPTION_NAME_WIDTH/width
					tn.rect_scale.x=scaling
				else:
					tn.rect_scale.x=1.0
				
				if node.has_node("Value"):
					updateValue(o,node)
#				#print(width)
			#for nn in node.get_children():
			#	if nn is Label:
			#		nn.set("custom_fonts/font",INITrans.font)

#Fuck your return oriented programming
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
			"text":INITrans.GetString("VNOptions",option),
			"uppercase":false,
		})
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
					"uppercase":true,
					rect_position=Vector2(800,0),
					rect_min_size=Vector2(MAX_VALUE_WIDTH,0),
					align=HALIGN_CENTER
				}))
				optionItem.add_child(Def.Sprite({
					name='leftArrow',
					TextureFromDisk="res://Ext/other_329.png",
					rect_position=Vector2(800-64*2,116/2-64),
					rect_scale=Vector2(2,2),
					flip_h=true
				}))
				optionItem.add_child(Def.Sprite({
					name='rightArrow',
					TextureFromDisk="res://Ext/other_329.png",
					rect_position=Vector2(800+MAX_VALUE_WIDTH,116/2-64),
					rect_scale=Vector2(2,2)
				}))
				var animationPlayer=AnimationPlayer.new()
				animationPlayer.name="animPlayer"
				animationPlayer.add_animation("arrow",arrowAnimation)
				#animationPlayer.autoplay="arrow"
				optionItem.add_child(animationPlayer)
				#optionItem.get_node("Value").connect("gui_input",self,"mouse_input")
			"bool":
				optionItem.add_child(Def.LoadFont(font,{
					"name":"BoolOff",
					"text":"Off",
					"rect_position":Vector2(800,0),
					rect_min_size=Vector2(MAX_VALUE_WIDTH/2,0),
					"uppercase":true,
					align=1
				}))
				optionItem.add_child(Def.LoadFont(font,{
					"name":"BoolOn",
					"text":"On",
					"rect_position":Vector2(800+MAX_VALUE_WIDTH/2,0),
					rect_min_size=Vector2(MAX_VALUE_WIDTH/2,0),
					"uppercase":true,
					align=1
				}))
			_:
				pass
		
		#displayedOptions+=1
		optionItem.add_child(optionNameActor)
		i=i+1
		
		optFrameActor.add_child(optionItem)
		#optionsList.append(option)
	print("Created new menu with "+String(i)+" options")
	#return optFrameActor

func _init():
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
	animation.length=2.0
	
	var leftArrowAnim = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(leftArrowAnim,"leftArrow:rect_position:x")
	animation.track_set_interpolation_type(leftArrowAnim,Animation.INTERPOLATION_CUBIC)
	animation.track_insert_key(leftArrowAnim,0,800-64*2)
	animation.track_insert_key(leftArrowAnim,1,800-64*2-16)
	animation.track_insert_key(leftArrowAnim,2,800-64*2)
	
	var rightArrowAnim = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(rightArrowAnim,"rightArrow:rect_position:x")
	animation.track_set_interpolation_type(rightArrowAnim,Animation.INTERPOLATION_CUBIC)
	animation.track_insert_key(rightArrowAnim,0,800+MAX_VALUE_WIDTH)
	animation.track_insert_key(rightArrowAnim,1,800+MAX_VALUE_WIDTH+16)
	animation.track_insert_key(rightArrowAnim,2,800+MAX_VALUE_WIDTH)
	
	optionsFrame = Control.new()
	optionsFrame.rect_position=Vector2(MENU_LEFT_PADDING,150)
	generateMenu(optionsFrame,options,animation)
	add_child(optionsFrame)
	
	systemOptionsSubmenu = Control.new()
	systemOptionsSubmenu.rect_position=Vector2(MENU_LEFT_PADDING,150)
	#systemOptionsSubmenu
	var systemOptions:Dictionary={}
	for opt in ["AudioVolume","SFXVolume","language"]:
		systemOptions[opt]=Globals.OPTIONS[opt]
	if OS.has_feature("pc"):
		systemOptions['isFullscreen']=Globals.OPTIONS['isFullscreen']
	else:
		systemOptions['goBack']={
			type="return",
			hasFunc=true
		}
	generateMenu(systemOptionsSubmenu,systemOptions,animation)
	add_child(systemOptionsSubmenu)
	#
	
onready var t = $Tween
func _ready():
	updateTranslation()
	OnCommand()
	#realInitPos=position
	pass


func OnCommand():
	highlightList(optionsFrame,selection)
	for i in range(optionsFrame.get_child_count()):
		optionsFrame.get_child(i).modulate.a=0
		t.interpolate_property(optionsFrame.get_child(i),"rect_position:x",
		-300,0,.4,Tween.TRANS_QUAD,Tween.EASE_OUT,i*.05)
		t.interpolate_property(optionsFrame.get_child(i),"modulate:a",
		0,1,.4,Tween.TRANS_QUAD,Tween.EASE_OUT,i*.05)
	t.start()
	pass
	#updateFocus()
	

#func updateFocus():
	
	
func handle_option(optNode:Control,going_right:bool=true):
	var option:String=optNode.get_meta("opt_name")
	match optNode.get_meta("opt_type"):
		"bool":
			Globals.OPTIONS[option]['value']=going_right
			highlightBool(optNode,going_right)
			if option=="isFullscreen":
				Globals.set_fullscreen(going_right)
		"int":
			var val = Globals.OPTIONS[option]['value']
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
					selectSound.play()
			elif val > 0:
				val-=10
				Globals.OPTIONS[option]['value']=val
				optNode.get_node("Value").text=String(val)
				if option=="AudioVolume" or option=="SFXVolume" or option=="VoiceVolume":
					Globals.set_audio_levels()
				selectSound.play()
		"list":
			var val = Globals.OPTIONS[option]['value']
			var idx = Globals.OPTIONS[option]['choices'].find(val,0)
			if going_right:
				if idx < len(Globals.OPTIONS[option]['choices'])-1:
					Globals.OPTIONS[option]['value']=Globals.OPTIONS[option]['choices'][idx+1]
					if option=="language":
						updateTranslation(true,Globals.OPTIONS[option]['value'])
					print(Globals.OPTIONS[option]['value'])
					updateValue(option,optNode)
					selectSound.play()
			elif idx > 0:
				Globals.OPTIONS[option]['value']=Globals.OPTIONS[option]['choices'][idx-1]
				if option=="language":
					updateTranslation(true,Globals.OPTIONS[option]['value'])
				print(Globals.OPTIONS[option]['value'])
				updateValue(option,optNode)
				selectSound.play()


func _input(event):
	var menuSize:int=0
	var curSel=selection
	var curMenu=optionsFrame
	if isSubMenu:
		curSel=subMenuSelection
		menuSize=systemOptionsSubmenu.get_child_count()
		curMenu=systemOptionsSubmenu
	else:
		menuSize=optionsFrame.get_child_count()
	
	if Input.is_action_pressed("ui_down") and curSel < menuSize-1:
		curSel+=1
		highlightList(curMenu,curSel)
		#if selection > 5:
		#	moveListUp()
		selectSound.play()
	elif Input.is_action_pressed("ui_up") and curSel > 0:
		curSel-=1
		highlightList(curMenu,curSel)
		#if selection < 6:
		#	moveListDown()
		selectSound.play()
	elif Input.is_action_pressed("ui_left"):
		var option = curMenu.get_child(curSel)
		handle_option(option,false)
	elif Input.is_action_pressed("ui_right"):
		var option = curMenu.get_child(curSel)
		handle_option(option)
	elif Input.is_action_pressed("ui_select"):
		highlightList(systemOptionsSubmenu,subMenuSelection)
		tweenMainMenuOut();
		isSubMenu=true
		return
	elif Input.is_action_pressed("ui_cancel"):
		tweenMainMenuIn();
		#highlightList(optionsFrame,subMenuSelection)
		isSubMenu=false
		return
		
	if isSubMenu:
		#print("update submenu sel")
		subMenuSelection=curSel
	else:
		selection=curSel
	#elif Input.is_action_pressed("ui_start"):
	#	pass
		


func tweenMainMenuOut():
	#TODO: Remove this shit and replace it with the newer tweens
	
	#First tween out main menu
	var tween = $Tween;
	tween.interpolate_property(optionsFrame, 'rect_position:x',
	null, MENU_LEFT_PADDING-200, .25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	tween.interpolate_property(optionsFrame, 'modulate',
	null, Color(1,1,1,0), .25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	
	#Tween in the submenu
	var property = "rect_position:x"
	
	var subList = systemOptionsSubmenu;
	tween.interpolate_property(subList, property,
	MENU_LEFT_PADDING+200,
	MENU_LEFT_PADDING,
	.25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	tween.interpolate_property(subList, 'modulate:a',
	null, 1.0, .25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	tween.start();

func tweenMainMenuIn():
	
	#Tween the main menu back in
	var tween = $Tween;
	tween.interpolate_property(optionsFrame, 'rect_position:x',
	null, MENU_LEFT_PADDING, .25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	tween.interpolate_property(optionsFrame, 'modulate',
	null, Color(1,1,1,1), .25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	
	
	#Tween the submenu out
	var property = "rect_position:x"
	tween.interpolate_property(systemOptionsSubmenu, property,
	null,
	MENU_LEFT_PADDING+200,
	.25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	tween.interpolate_property(systemOptionsSubmenu, 'modulate:a',
	null, 0.0, .25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	tween.start();

