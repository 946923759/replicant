extends Control

onready var database = Globals.chapterDatabase
onready var chapterActorFrame = $ScrollContainer/VBoxContainer
#We do a little trolling
onready var mSelObjs = $ScrollContainer2/VBoxContainer

var curChapterNum:int=1
#This is for gamepad
var curMissionPartNumForGamepad:int=0
var curMissionNumForGamepad:int=0

var biggestMissionNum:int=0

var font = preload("res://ChapterListingFont.tres")
var MSelObj = load("res://Screens/ScreenSelectChapter/MSelObj.tscn")

func _ready():
	Globals.wasUsingAutoMode=false
	
	var c = chapterActorFrame
	c.get_child(0).visible=false #Hide "Test" label
	for chapterName in database.keys():
		if database[chapterName].size()==0:
			continue
# warning-ignore:narrowing_conversion
		biggestMissionNum=max(database[chapterName].size(),biggestMissionNum)
		#var chapter:Globals.Chapter = database[chapterName]
		#biggestMissionNum=max(chapter.parts,biggestMissionNum)
		#print(chName)
		var n = Label.new()
		n.name=chapterName
		n.set("custom_fonts/font",font)
		n.set("mouse_filter",1)
		n.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		#n.margin_left=1000 #use VBOxContainer margin instead
		#TODO: Translate these
		n.text=String(chapterName)
		#n.set_meta("chapterName",chapterName) #lmao
		n.connect("gui_input",self,"handle_chapter_click",[chapterName])
		c.add_child(n)
	print(biggestMissionNum)
	for _i in range(biggestMissionNum):
		var m = MSelObj.instance()
		mSelObjs.add_child(m)
	for m in mSelObjs.get_children():
		m.connect("button_pressed",self,"handle_btn_press")
		#m.connect("wtf",self,'test2')
	biggestMissionNum=mSelObjs.get_child_count() #We're never adding any more so it's fine
	
	set_new_mission_listing(database.keys()[1])
	
	#Only show by default if there is a controller plugged in
	$DescrptionF.visible = Input.get_connected_joypads().size() > 0
	#mSelObjs.queue_sort()

func handle_chapter_click(event:InputEvent,internalName:String):
	if (event is InputEventMouseButton and event.pressed and event.button_index == 1):
		print("Clicked "+internalName)
		for i in range(1,chapterActorFrame.get_child_count()):
			if chapterActorFrame.get_child(i).name==internalName:
				curChapterNum=i
				break
		#curChapterNum
		set_new_mission_listing(internalName)

onready var descKB = $DescrptionF/DescKB
onready var descGP = $DescrptionF/DescGP
func _input(event):
	
	descKB.visible=(event is InputEventKey)
	descGP.visible=(event is InputEventJoypadButton)
	$DescrptionF.visible=(event is InputEventKey) or (event is InputEventJoypadButton)
	$BackButton2.visible=!$DescrptionF.visible
	if (event is InputEventScreenTouch) or (event is InputEventMouseMotion) or (event is InputEventMouseButton):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		reset_all_button_highlights_for_touch()
		return
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	var tmpChNum = curChapterNum
	if Input.is_action_just_pressed("ui_page_down"):
		if tmpChNum < chapterActorFrame.get_child_count()-1:
			tmpChNum+=1
	elif Input.is_action_just_pressed("ui_page_up"):
		if tmpChNum > 1:
			tmpChNum-=1
	elif Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("ui_up"):
		var chapterName = chapterActorFrame.get_child(tmpChNum).name
		var chapter:Array = database[chapterName]
		var chLength = chapter.size()
		#var newPos = curMissionNumForGamepad
		
		var prevmSelObj = mSelObjs.get_child(curMissionNumForGamepad)
		if Input.is_action_just_pressed("ui_down"):
			if curMissionNumForGamepad<chLength-1:
				curMissionNumForGamepad+=1
				#set_all_button_highlights_for_gamepad(curMissionNumForGamepad,0)
		else:
			if curMissionNumForGamepad>0:
				curMissionNumForGamepad-=1
		var mSelObj = mSelObjs.get_child(curMissionNumForGamepad)
		if curMissionPartNumForGamepad > mSelObj.getNumParts()-1:
			curMissionPartNumForGamepad=mSelObj.getNumParts()-1
		else:
			#Parts are right aligned so we need to do some wacky shit and get the offset from the right side
			var offsetFromRight=prevmSelObj.getNumParts()-curMissionPartNumForGamepad-1
			print(offsetFromRight)
# warning-ignore:narrowing_conversion
			curMissionPartNumForGamepad=max(mSelObj.getNumParts()-1-offsetFromRight,0)
		print(curMissionPartNumForGamepad)
		
		
		set_all_button_highlights_for_gamepad(curMissionNumForGamepad,curMissionPartNumForGamepad)
			#newPos-=1
		#if newPos < 
	elif Input.is_action_just_pressed("ui_left"):
		if curMissionPartNumForGamepad>0:
			curMissionPartNumForGamepad-=1
			set_all_button_highlights_for_gamepad(curMissionNumForGamepad,curMissionPartNumForGamepad)
			
		#
		#if 
	elif Input.is_action_just_pressed("ui_right"):
		var mSelObj = mSelObjs.get_child(curMissionNumForGamepad)
		if curMissionPartNumForGamepad<mSelObj.getNumParts()-1:
			curMissionPartNumForGamepad+=1
			set_all_button_highlights_for_gamepad(curMissionNumForGamepad,curMissionPartNumForGamepad)
	elif Input.is_action_just_pressed("ui_select") or Input.is_action_just_pressed("ui_pause"):
		mSelObjs.get_child(curMissionNumForGamepad).buttonTrigger(curMissionPartNumForGamepad)
		return
	elif Input.is_action_just_pressed("ui_cancel"):
		$FadeOut.OffCommand("ScreenTitleMenu")
	
	if tmpChNum!=curChapterNum:
		curChapterNum=tmpChNum
		set_new_mission_listing(chapterActorFrame.get_child(tmpChNum).name)

		curMissionPartNumForGamepad=0
		#Calculate mission num here, because some missions can have zero parts
		if (event is InputEventKey) or (event is InputEventJoypadButton):
			#var chapter:Array = database[chapterName]
			for i in range(biggestMissionNum):
				var mSelObj = mSelObjs.get_child(i)
				if mSelObj.getNumParts() > 0:
					curMissionNumForGamepad=i
					break
			set_all_button_highlights_for_gamepad(curMissionNumForGamepad,curMissionPartNumForGamepad)
				#if i < chLength:
		

func set_new_mission_listing(chapterName:String):
	for n in chapterActorFrame.get_children():
		if n.name!=chapterName:
			n.modulate=Color.slategray
		else:
			n.modulate=Color.white
	
	var chapter:Array = database[chapterName]
	var chLength = chapter.size()
	#print(chapter)
	var t:Tween = $Tween
	t.stop_all()
	for i in range(biggestMissionNum):
		var mSelObj = mSelObjs.get_child(i)
		if i < chLength:
			mSelObj.visible=true
			mSelObj.setEpisode(chapter[i])
#			mSelObj.title.text=chapter[i].title
#			mSelObj.desc.text=chapter[i].desc
#			mSelObj.setNumParts(chapter[i].parts)
			#mSelObj.rect_position.x = i*500
			mSelObj.modulate.a=0.0
			t.interpolate_property(mSelObj,"rect_position:x",500,0,.3,Tween.TRANS_QUAD,Tween.EASE_OUT,i*.2)
			t.interpolate_property(mSelObj,"modulate:a",0,1,.3,Tween.TRANS_QUAD,Tween.EASE_OUT,i*.2)
		else:
			mSelObj.visible=false
	t.start()

func set_all_button_highlights_for_gamepad(missionNum,partNum):
	for i in range(biggestMissionNum):
		var mSelObj = mSelObjs.get_child(i)
		if i!=missionNum:
			for c in mSelObj.getPartActorFrame().get_children():
				c.modulate=Color.slategray
		else:
			var af=mSelObj.getPartActorFrame()
			for j in range(af.get_child_count()):
				var btn = af.get_child(j)
				if j!=partNum:
					btn.modulate=Color.slategray
				else:
					btn.modulate=Color.white
					
func reset_all_button_highlights_for_touch():
	for i in range(biggestMissionNum):
		var mSelObj = mSelObjs.get_child(i)
		for c in mSelObj.getPartActorFrame().get_children():
			c.modulate=Color.white
		

func handle_btn_press(vnPlayerDest:String,episodeDest:Globals.Episode):
	print("Handling destination...")
	Globals.nextCutscene=vnPlayerDest+".txt"
	Globals.currentEpisodeData=episodeDest
	#$FadeOut.visible=true
	#print("Tweening....")
	#$AnimationPlayer.play("New Anim")
	#print("lol")
	$FadeOut.OffCommand("CutsceneFromFile")
	
#If Android back button pressed
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		#get_tree().quit();
		$FadeOut.OffCommand("ScreenTitleMenu")

#func _on_AnimationPlayer_animation_finished(anim_name):
#	print("Changing scene!")
#	get_tree().change_scene("res://Cutscene/CutsceneFromFile.tscn")


func _on_BackButton2_gui_input(event):
	if (event is InputEventMouseButton and event.pressed and event.button_index == 1):
		#get_tree().change_scene("res://TitleScreen.tscn")
		$FadeOut.OffCommand("ScreenTitleMenu")
