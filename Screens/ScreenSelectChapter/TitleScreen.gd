extends Control

onready var database = Globals.chapterDatabase
onready var chapterScrollbar = $MarginContainer/ScrollContainer
onready var chapterActorFrame = $MarginContainer/ScrollContainer/VBoxContainer
#We do a little trolling
onready var missionScrollbar = $ScrollContainer2
onready var missionSelObjs = $ScrollContainer2/VBoxContainer

var curChapterNum:int=1
#This is for gamepad
var curMissionPartNumForGamepad:int=0
var curMissionNumForGamepad:int=0

var biggestMissionNum:int=0

var font = preload("res://Fonts/ChapterListingFont.tres")
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
		n.set("use_parent_material",true)
		n.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		#n.margin_left=1000 #use VBOxContainer margin instead
		#TODO: Translate these
		n.text=String(chapterName)
		#n.set_meta("chapterName",chapterName) #lmao
		n.connect("gui_input",self,"handle_chapter_click",[chapterName])
		c.add_child(n)
	
	var n = Label.new()
	n.name="_"
	n.set("custom_fonts/font",font)
	n.set("mouse_filter",MOUSE_FILTER_IGNORE)
	n.text=" "
	c.add_child(n)
	
	#print(biggestMissionNum)
	for _i in range(biggestMissionNum):
		var m = MSelObj.instance()
		missionSelObjs.add_child(m)
	for m in missionSelObjs.get_children():
		m.connect("button_pressed",self,"handle_btn_press")
		#m.connect("wtf",self,'test2')
	
	# I don't remember what this does
	biggestMissionNum=missionSelObjs.get_child_count() #We're never adding any more so it's fine
	
	if Globals.currentEpisodeData:
		var chName = Globals.currentEpisodeData.parentChapter;
		#Pretty sure this will always be true
		if chName:
			set_new_mission_listing(chName)
	else:
		#Has to be 2 because we hide idx 0...
		set_new_mission_listing(database.keys()[1],2)
	
	#Only show by default if there is a controller plugged in
	$DescrptionF.visible = Input.get_connected_joypads().size() > 0
	#missionSelObjs.queue_sort()

func handle_chapter_click(event:InputEvent,internalName:String):
	if (event is InputEventMouseButton and event.pressed and event.button_index == 1):
		print("Clicked "+internalName)
		$Click.play()
		
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
		var chapterName = chapterActorFrame.get_child(tmpChNum).text
		var chapter:Array = database[chapterName]
		var chLength = chapter.size()
		#var newPos = curMissionNumForGamepad
		
		var prevmSelObj = missionSelObjs.get_child(curMissionNumForGamepad)
		if Input.is_action_just_pressed("ui_down"):
			if curMissionNumForGamepad<chLength-1:
				curMissionNumForGamepad+=1
				#set_all_button_highlights_for_gamepad(curMissionNumForGamepad,0)
		else:
			if curMissionNumForGamepad>0:
				curMissionNumForGamepad-=1
		var mSelObj = missionSelObjs.get_child(curMissionNumForGamepad)
		if curMissionPartNumForGamepad > mSelObj.getNumParts()-1:
			curMissionPartNumForGamepad=mSelObj.getNumParts()-1
		else:
			#Parts are right aligned so we need to do some wacky shit and get the offset from the right side
			var offsetFromRight=prevmSelObj.getNumParts()-curMissionPartNumForGamepad-1
			#print(offsetFromRight)
# warning-ignore:narrowing_conversion
			curMissionPartNumForGamepad=max(mSelObj.getNumParts()-1-offsetFromRight,0)
		print("Cur Mission: "+String(curMissionNumForGamepad)+"."+String(curMissionPartNumForGamepad))
		#print("cur mission part num: "+String(curMissionPartNumForGamepad))
		
		
		$Navigation.play()
		set_all_button_highlights_for_gamepad(curMissionNumForGamepad,curMissionPartNumForGamepad)
		#scrollContainer.scroll_vertical=scrollContainer.scroll_vertical + 60*sc*d
		
		var thisMissionPositionOnScreen = 134*curMissionNumForGamepad-missionScrollbar.scroll_vertical
		#print(thisMissionPositionOnScreen)
		if thisMissionPositionOnScreen > 800:
			#print("Attempting to tween to "+String(thisMissionPositionOnScreen-900+missionScrollbar.scroll_vertical))
			var t:Tween = $Tween
			#var maximum_scroll = missionScrollbar.get_v_scrollbar().max_value
			var scroll_to = min(
				thisMissionPositionOnScreen-800+missionScrollbar.scroll_vertical, 
				missionScrollbar.get_v_scrollbar().max_value
			)
			#print(maximum)
			t.interpolate_property(
				missionScrollbar,
				"scroll_vertical",
				null,
				scroll_to,
				.3,
				Tween.TRANS_CUBIC,
				Tween.EASE_OUT
			)
			t.start()
		elif thisMissionPositionOnScreen < 0:
			#We want to calc the offset needed to scroll back to 0
			
			var t:Tween = $Tween
			t.interpolate_property(missionScrollbar,"scroll_vertical",null,missionScrollbar.scroll_vertical+thisMissionPositionOnScreen,.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
			t.start()
			pass
			#newPos-=1
		#if newPos < 
	elif Input.is_action_just_pressed("ui_left"):
		if curMissionPartNumForGamepad>0:
			curMissionPartNumForGamepad-=1
			$Navigation.play()
			set_all_button_highlights_for_gamepad(curMissionNumForGamepad,curMissionPartNumForGamepad)
			
		#
		#if 
	elif Input.is_action_just_pressed("ui_right"):
		var mSelObj = missionSelObjs.get_child(curMissionNumForGamepad)
		if curMissionPartNumForGamepad<mSelObj.getNumParts()-1:
			curMissionPartNumForGamepad+=1
			$Navigation.play()
			set_all_button_highlights_for_gamepad(curMissionNumForGamepad,curMissionPartNumForGamepad)
	elif Input.is_action_just_pressed("ui_select") or Input.is_action_just_pressed("ui_pause"):
		missionSelObjs.get_child(curMissionNumForGamepad).buttonTrigger(curMissionPartNumForGamepad)
		return
	elif Input.is_action_just_pressed("ui_cancel"):
		$FadeOut.OffCommand("ScreenTitleMenu")
	
	if tmpChNum!=curChapterNum:
		$Click.play()
		curChapterNum=tmpChNum
		#TODO: It will break if chapter names get localized
		set_new_mission_listing(chapterActorFrame.get_child(tmpChNum).text,curChapterNum)

		curMissionPartNumForGamepad=0
		#Calculate mission num here, because some missions can have zero parts
		if (event is InputEventKey) or (event is InputEventJoypadButton):
			#var chapter:Array = database[chapterName]
			for i in range(biggestMissionNum):
				var mSelObj = missionSelObjs.get_child(i)
				if mSelObj.getNumParts() > 0:
					curMissionNumForGamepad=i
					break
			set_all_button_highlights_for_gamepad(curMissionNumForGamepad,curMissionPartNumForGamepad)
				#if i < chLength:
		

# chapterName: The name of the chapter.
# chapterIndex: The index in the database. Mostly used for handling automatic scroll.
func set_new_mission_listing(chapterName:String, chapterIndex:int=-1):
	var nodeName = chapterName.replace(".","")
	
	if chapterIndex < 0:
		for i in range(1,chapterActorFrame.get_child_count()):
			if chapterActorFrame.get_child(i).name==nodeName:
				chapterIndex=i
				#print("Found chapter indexed at "+String(chapterIndex)+" in database (1-indexed)")
				break
	
	#if still < 0 after searching for idx
	if chapterIndex < 0:
		printerr("Failed to find an object named "+nodeName+" in the chapter list ActorFrame.")
		return
	
	curChapterNum = chapterIndex
	
	for n in chapterActorFrame.get_children():
		if n.name!=nodeName:
			n.modulate=Color.slategray
		else:
			n.modulate=Color.white
	
	if !database.has(chapterName):
		return
	var chapter:Array = database[chapterName]
	var chLength = chapter.size()
	#print(chapterName+" "+String(chapterIndex))
	missionScrollbar.scroll_vertical = 0.0
	var t:Tween = $Tween
	t.stop_all()
	
	var chapter_selection_pos_on_screen = 111*(chapterIndex-1) - chapterScrollbar.scroll_vertical
	#print("y pos: "+String(chapter_selection_pos_on_screen))
	if chapter_selection_pos_on_screen > 800:
		t.interpolate_property(chapterScrollbar,"scroll_vertical",null,chapter_selection_pos_on_screen-800+chapterScrollbar.scroll_vertical,.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
		#chapterScrollbar.scroll_vertical
		pass
	if chapter_selection_pos_on_screen < 0:
		t.interpolate_property(chapterScrollbar,"scroll_vertical",null,0,.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	#print("IDX: ",chapterIndex)
	#print("COMPLETED: ",Globals.playerData['completedChapters'][0] & 1<<0)
	for i in range(biggestMissionNum):
		var mSelObj = missionSelObjs.get_child(i)
		if i < chLength:
			mSelObj.visible=true
			
			var isCompleted = Globals.playerData['completedChapters'][chapterIndex-1] & 1<<i
			mSelObj.setEpisode(chapter[i],isCompleted)
#			mSelObj.title.text=chapter[i].title
#			mSelObj.desc.text=chapter[i].desc
#			mSelObj.setNumParts(chapter[i].parts)
			#mSelObj.rect_position.x = i*500
			mSelObj.modulate.a=0.0
			t.interpolate_property(mSelObj,"rect_position:x",500,0,.3,Tween.TRANS_QUAD,Tween.EASE_OUT,i*.1)
			t.interpolate_property(mSelObj,"modulate:a",0,1,.3,Tween.TRANS_QUAD,Tween.EASE_OUT,i*.1)
		else:
			mSelObj.visible=false
	t.start()

func set_all_button_highlights_for_gamepad(missionNum,partNum):
	for i in range(biggestMissionNum):
		var mSelObj = missionSelObjs.get_child(i)
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
		var mSelObj = missionSelObjs.get_child(i)
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
		$BackSound.play()
		$FadeOut.OffCommand("ScreenTitleMenu")

#func _on_AnimationPlayer_animation_finished(anim_name):
#	print("Changing scene!")
#	get_tree().change_scene("res://Cutscene/CutsceneFromFile.tscn")


func _on_BackButton2_gui_input(event):
	if (event is InputEventMouseButton and event.pressed and event.button_index == 1):
		#get_tree().change_scene("res://TitleScreen.tscn")
		$BackSound.play()
		$FadeOut.OffCommand("ScreenTitleMenu")
