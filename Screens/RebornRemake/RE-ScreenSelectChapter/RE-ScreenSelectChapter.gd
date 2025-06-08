extends "res://Screens/ScreenWithMenuElements.gd"

const SCREEN_WIDTH = 1920
const STARTING_CHAPTER = 1

const NUM_CHAPTERS:int=6
#const NUM_PARTS:int = 2
onready var NUM_PARTS:int = $ActorFrame_PartSelect.get_child_count()

var chapterSelection:int = STARTING_CHAPTER
var partSelection:int = 0

enum PAGE {
	AREA,
	STAGE
}
var current_page = PAGE.AREA

#class Episode:
#	#There is no easy way to get the parent without iterating through the
#	#whole dict so put it here too
#	var parentChapter:String
#	var title:String
#	var desc:String
#	var parts:Array
#	var isSub:bool=false

onready var chapterFrame = $ActorFrame_AreaSelect
onready var stageFrame = $ActorFrame_PartSelect
onready var t = $Tween
var tw:SceneTreeTween

var sso = preload("res://Screens/RebornRemake/RE-ScreenSelectChapter/RE-StageSelectObj.tscn")

func repositionFrame(sel:int, tweenTime:float=.5):
	chapterFrame.get_child(sel).rect_scale=Vector2(1,1)
	#$Label.text= "Position: "+String(sel)+" rect_scale: "
	var txt = "Position: "+String(sel)
	txt+= "\n"+String(chapterFrame.get_child(sel).rect_scale)
	$DebugLabel.text=txt
	
	t.remove_all()
	if tweenTime>0.0:
		t.interpolate_property(chapterFrame,"rect_position:x",null,-SCREEN_WIDTH*sel,tweenTime,Tween.TRANS_CUBIC,Tween.EASE_OUT)
		t.start()
	else:
		chapterFrame.rect_position.x = -SCREEN_WIDTH*sel
	#for c in chapterFrame.get_children():
	#	c.rect_scale=Vector2(1,1)
	#chapterFrame.position.x=
	
func set_chapter_selection(new_sel:int, tweenTime:float=.5):
	#chapterFrame.get_child(chapterSelection).rect_scale=Vector2(1,1)
	
	if new_sel>=NUM_CHAPTERS:
		chapterSelection=0
	elif new_sel < 0:
		chapterSelection=NUM_CHAPTERS-1
	else:
		chapterSelection=new_sel
	
	#chapterFrame.get_child(chapterSelection)
	repositionFrame(chapterSelection, tweenTime)
	
func set_part_selection(new_sel:int, tweenTime:float=.5, force_visible:bool=true):
	if new_sel>=NUM_PARTS:
		partSelection=0
	elif new_sel<0:
		partSelection=NUM_PARTS-1
	else:
		partSelection=new_sel

	if force_visible:
		stageFrame.visible=true
		stageFrame.modulate.a=1.0
		var selObj = stageFrame.get_child(partSelection)
		if selObj:
			selObj.modulate.a=1.0
			selObj.rect_scale=Vector2(1.0,1.0)
		#for c in chapterFrame.get_children():
		##	c.rect_scale=Vector2(1,1)
	$DebugLabel.text= "Part Position: "+String(partSelection)+"\n"+String(stageFrame.modulate)+"\nVisible: "+String(stageFrame.visible)
	t.remove_all()
	t.interpolate_property(stageFrame,"rect_position:x",null,-SCREEN_WIDTH*partSelection,tweenTime,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	t.start()

func handle_RR_icon_click(event,sender):
	if event is InputEventMouseButton and event.button_index == 1:
		if event.pressed:
			#print("Clicked")
			print("Sender is "+sender.name)
			var dest = sender.name.rsplit(">",false,1)
			print("Splits are "+String(dest))
			if dest.size()<2 or dest[1].is_valid_integer() == false:
				printerr("Destination invalid! Cannot enter page")
				return
			$ConfirmSound.play()
			#emit_signal("clicked")
			
			print("Navigating to inner page "+dest[1])
			current_page=PAGE.STAGE
			var cur_page = chapterFrame.get_node("Page"+String(chapterSelection))
			#var dest_page = stageFrame.get_node("0>Chapter1-1")
			if int(dest[1])>=stageFrame.get_child_count():
				printerr("Button referenced more than there are pages (Hint: pages are 0-indexed!)")
				return
			var dest_page = stageFrame.get_child(int(dest[1]))
			print("Dest page is "+dest_page.name)
			
			set_part_selection(int(dest[1]), 0.0)
			var senderCenterPos:Vector2 = sender.rect_position+ (sender.rect_size/2*sender.rect_scale) #-sender.rect_scale
			#print("Object center is "+String(sender.rect_position)+"+"+String(sender.rect_size/2)+"x"+String(sender.rect_scale)+"="+String(senderCenterPos))
			#Bizarrely, the more off center it is, the more the rect center gets offset towards the center.
			#print(rect_size)
			var SCREEN_CENTER = rect_size/2
			var offsetRatio = (senderCenterPos-SCREEN_CENTER)*.1
			#print(offsetRatio)
			#senderCenterPos
			cur_page.rect_pivot_offset=senderCenterPos+offsetRatio
			dest_page.rect_pivot_offset=senderCenterPos+offsetRatio
			
			#if true:
			#	dest_page.rect_scale = Vector2(.1,.1)
			#	return
			
			var newTween:SceneTreeTween = tw
			if newTween:
				newTween.kill()
			newTween = get_tree().create_tween()
			tw = newTween
			newTween.tween_property(stageFrame,"visible",true,0.0) #.set_delay(.25)
			newTween.tween_property(stageFrame,"modulate:a",1.0,0.0)

			#newTween.set_speed_scale(.25)
			newTween.set_parallel()
			newTween.tween_property(cur_page,"rect_scale",Vector2(5,5),.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			#newTween.tween_property(stageFrame)
			#newTween.tween_property(dest_page,"")


			newTween.tween_property(dest_page,"rect_scale",Vector2(1,1),.42).from(Vector2(0,0)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			newTween.tween_property(stageFrame,"modulate:a",1.0,.65) #.from(0.0)
			
			#newTween.tween_property(stageFrame,"visible",true,0.0).set_delay(.66)
			#newTween.tween_property(stageFrame,"modulate:a",1.0,0.0).set_delay(.66)
			newTween.tween_property(cur_page,"rect_scale",Vector2(1,1),0.0).set_delay(.66)
			#Globals.nextCutscene=sender.episode.parts[0]+".txt"
			#Globals.currentEpisodeData=sender.episode
			#$FadeOut.visible=true
			#print("Tweening....")
			#$AnimationPlayer.play("New Anim")
			#print("lol")
			#OffCommandNextScreen("RR-CutsceneFromFile")
			
			pass

func find_ep_from_part_name(n):
	for k in Globals.chapterDatabase_RE:
		print(k)
		for episode in Globals.chapterDatabase_RE[k]:
			if episode.parts[0]==n:
				#print("episode")
				return episode
			#else:
			#	print(episode.parts[0])
	return null

func handle_RE_stage_click(event, _sender, partNum):
	if event is InputEventMouseButton and event.button_index == 1:
		if event.pressed:
			print("Clicked "+partNum+", handling destination...")

			Globals.currentEpisodeData=find_ep_from_part_name(partNum)
			Globals.nextCutscene=partNum+".txt"

			$ConfirmSound.play()
			OffCommandNextScreen("RE-CutsceneFromFile")

func input_go_back():
	if current_page==PAGE.STAGE:
		var dest_page:Control = stageFrame.get_child(partSelection)
		var parentChapterNum = dest_page.name.split(">",false,1)
		var cur_page:Control = chapterFrame.get_node("Page"+parentChapterNum[0])
		print("Going back to page... "+parentChapterNum[0])
		set_chapter_selection(int(parentChapterNum[0]), 0.0)
		#set_chapter_selection()
		#var chapterOpenObject = chapterFrame.get_child(int(parentChapterNum[0])+1)

		#var senderCenterPos:Vector2 = cur_page.rect_position+cur_page.rect_size/2 #-Vector2(1920,0) #-sender.rect_scale
		var senderCenterPos:Vector2 = rect_size/2
		print("Rect screen position is "+String(senderCenterPos))
		cur_page.rect_pivot_offset=senderCenterPos
		dest_page.rect_pivot_offset=senderCenterPos
		
		var newTween:SceneTreeTween = tw
		if newTween:
			newTween.kill()
		newTween = get_tree().create_tween()
		tw = newTween
		
		newTween.set_parallel()
		newTween.tween_property(cur_page,"rect_scale",Vector2(1,1),.55).from(Vector2(5,5)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		#newTween.tween_property(stageFrame)
		#newTween.tween_property(dest_page,"")
		newTween.tween_property(dest_page,"rect_scale",Vector2(0,0),.52).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		newTween.tween_property(stageFrame,"modulate:a",0.0,1)
		newTween.set_parallel(false)
		newTween.tween_property(stageFrame,"visible",false,0.0) #.set_delay(.65) #.set_delay(.25)
		newTween.tween_property(dest_page,"rect_scale",Vector2(1,1),0.0) #.set_delay(.65) #.set_delay(.25)
		current_page=PAGE.AREA
	else:
		OffCommandPrevScreen()
		
func _ready():
	$DebugLabel.visible=OS.is_debug_build()
	stageFrame.visible=false
	stageFrame.rect_position=Vector2(0,0)
	repositionFrame(chapterSelection, 0.0)
	
	#if OS.is_debug_build():
	if Globals.chapterDatabase_RE.empty():
		Globals.chapterDatabase_RE=Globals.load_database("Screens/RebornRemake/RE-ScreenSelectChapter/re_db.tsv")
	elif Globals.currentEpisodeData:
		print("[RE-ScreenSelectChapter] Player had previously read an episode")
		print(Globals.currentEpisodeData._to_string())
	#var test = get_node("ActorFrame_AreaSelect/Page1/RE-1>0")
	#test.connect("gui_input",self,"handle_RR_icon_click",[test])
	
	#for i in range(1,)
	#var lastChatperIdx = 0
	#var lastStageIdx = 0
	
	#var tmp_PageIdx = 0
	for page_ActorFrame in chapterFrame.get_children():
		for i in range(1,page_ActorFrame.get_child_count()):
			var clickToStageSelectObject = page_ActorFrame.get_child(i)
			if clickToStageSelectObject is Control:
				clickToStageSelectObject.mouse_default_cursor_shape = CURSOR_POINTING_HAND
				clickToStageSelectObject.connect("gui_input",self,"handle_RR_icon_click",[clickToStageSelectObject])
		#tmp_PageIdx+=1
	
	var tmp_PageIdx = 0
	for page_ActorFrame in stageFrame.get_children():
		page_ActorFrame.rect_position.x = SCREEN_WIDTH*tmp_PageIdx
		
		
		var splits = page_ActorFrame.name.rsplit(">",false,1)
		var splits2 = splits[1].split("-",false,1)
		
		var whatChapterAreWeOn:String = splits2[0]
		#if Globals.currentEpisodeData:
		#	if Globals.currentEpisodeData.parentChapter==whatChapterAreWeOn:
		#		
		#print(whatChapterAreWeOn)
		
		for obj in page_ActorFrame.get_children():
			#print(obj.get_class())
			if obj.get_class()=="Control":
				
				var tmp = Globals.get_episode_index_2(
					Globals.chapterDatabase_RE,
					whatChapterAreWeOn,
					obj.label
				)
				if tmp[0] >= 0 and tmp[1] >= 0 and tmp[0] < Globals.playerData['completedReborn'].size():
					obj.completed = Globals.playerData['completedReborn'][tmp[0]] & 1<<tmp[1]
				
				#var ep = Globals.Episode.new()
				#ep.parentChapter=chapterActor.name
				#ep.title=obj.name
				#ep.desc=obj.name #Doesn't matter since translation engine will put the real name
				#ep.parts=find_episode_parts(obj.name)
				#ep.isSub=("S" in obj.name)
				
				#retroRemake_database[chapterActor.name].append(ep)
				#obj.episode = ep
				
				obj.mouse_default_cursor_shape = CURSOR_POINTING_HAND
				obj.connect("gui_input",self,"handle_RE_stage_click",[obj, obj.name])
		tmp_PageIdx+=1
	
	var debugRoom = get_node("ActorFrame_PartSelect/0>Debug Room")
	tmp_PageIdx=0
	for ep in Globals.chapterDatabase_RE['Debug Room']:
		var sso_inst = sso.instance()
		sso_inst.name = ep.parts[0]
		sso_inst.label = ep.title
		sso_inst.mouse_default_cursor_shape = CURSOR_POINTING_HAND
		sso_inst.connect("gui_input",self,"handle_RE_stage_click",[sso_inst, sso_inst.name])

		debugRoom.add_child(sso_inst)
		sso_inst.rect_position = Vector2(100,100)+Vector2(100*tmp_PageIdx,0)
		tmp_PageIdx+=1
var time_between_mousewheel = 0
func _input(event):
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	var mousewheel_up = false
	var mousewheel_down = false
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_DOWN:
			if abs(time_between_mousewheel - Time.get_ticks_usec()) > 240000:
				time_between_mousewheel = Time.get_ticks_usec()
				mousewheel_down = true
		elif event.button_index == BUTTON_WHEEL_UP:
			
			if abs(time_between_mousewheel - Time.get_ticks_usec()) > 240000:
				time_between_mousewheel = Time.get_ticks_usec()
				mousewheel_up = true
	
	if Input.is_action_just_pressed("ui_cancel") or (event is InputEventMouseButton and event.button_index == BUTTON_RIGHT and event.pressed):
		input_go_back()
		return
	# Does not work
	elif Input.is_action_just_pressed("DebugButton1"):
		#var p = Globals.get_save_directory('systemData')
		#print("[RE-ScreenSelectChapter] system shell is opening "+p)
		if OS.get_name() == "X11":
			OS.execute("xdg-open",['Screens/RebornRemake/RE-ScreenSelectChapter/re_db.tsv'], false)
	elif Input.is_action_just_pressed("DebugButton5"):
		Globals.chapterDatabase_RE=Globals.load_database("Screens/RebornRemake/RE-ScreenSelectChapter/re_db.tsv")
		get_tree().reload_current_scene()
	
	if current_page==PAGE.AREA:
		if Input.is_action_just_pressed("ui_right") or mousewheel_down:
			set_chapter_selection(chapterSelection+1)
		elif Input.is_action_just_pressed("ui_left") or mousewheel_up:
			set_chapter_selection(chapterSelection-1)
	elif current_page==PAGE.STAGE:
		if Input.is_action_just_pressed("ui_right") or mousewheel_down:
			set_part_selection(partSelection+1)
			#stageFrame.visible=true
		elif Input.is_action_just_pressed("ui_left") or mousewheel_up:
			set_part_selection(partSelection-1)
			#stageFrame.visible=true


func _on_ArrowLeft_gui_input(event):
	if event is InputEventMouseButton and event.button_index == 1 and event.pressed:
		$CursorSound.play()
		if current_page==PAGE.AREA:
			set_chapter_selection(chapterSelection-1)
		else:
			set_part_selection(partSelection-1)

func _on_ArrowRight_gui_input(event):
	if event is InputEventMouseButton and event.button_index == 1 and event.pressed:
		$CursorSound.play()
		if current_page==PAGE.AREA:
			set_chapter_selection(chapterSelection+1)
		else:
			set_part_selection(partSelection+1)
