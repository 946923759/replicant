extends "res://Screens/ScreenWithMenuElements.gd"

const SCREEN_WIDTH = 1920
const start = 0

const NUM_CHAPTERS:int=5
const NUM_PARTS:int = 2

var chapterSelection:int = start
var partSelection:int = 0

enum PAGE {
	AREA,
	STAGE
}
var current_page = PAGE.AREA

onready var chapterFrame = $ActorFrame_AreaSelect
onready var stageFrame = $ActorFrame_PartSelect
onready var t = $Tween

func repositionFrame(sel:int, tweenTime:float=.5):
	$Label.text= "Position: "+String(sel)
	t.remove_all()
	t.interpolate_property(chapterFrame,"rect_position:x",null,-SCREEN_WIDTH*sel,tweenTime,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	t.start()
	#chapterFrame.position.x=
	
func set_chapter_selection(new_sel:int):
	if new_sel>=NUM_CHAPTERS:
		chapterSelection=0
	elif new_sel < 0:
		chapterSelection=NUM_CHAPTERS-1
	else:
		chapterSelection=new_sel
	repositionFrame(chapterSelection)
	
func set_part_selection(new_sel:int, tweenTime:float=.5):
	if new_sel>=NUM_PARTS:
		partSelection=0
	elif new_sel<0:
		partSelection=NUM_PARTS-1
	else:
		partSelection=new_sel
		
	
	$Label.text= "Part Position: "+String(partSelection)
	t.remove_all()
	t.interpolate_property(stageFrame,"rect_position:x",null,-SCREEN_WIDTH*partSelection,tweenTime,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	t.start()

func handle_RR_icon_click(event,sender):
	if event is InputEventMouseButton and event.button_index == 1:
		if event.pressed:
			print("Clicked")
			print(sender.name)
			#emit_signal("clicked")
			
			print("Handling destination...")
			current_page=PAGE.STAGE
			var cur_page = chapterFrame.get_node("Page"+String(chapterSelection+1))
			var dest_page = stageFrame.get_node("Chapter1-1")
			var senderCenterPos:Vector2 = sender.rect_position+sender.rect_size/2/sender.rect_scale #-sender.rect_scale
			cur_page.rect_pivot_offset=senderCenterPos
			dest_page.rect_pivot_offset=senderCenterPos
			
			var newTween = get_tree().create_tween()
			newTween.set_parallel()
			newTween.tween_property(cur_page,"rect_scale",Vector2(5,5),.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			#newTween.tween_property(stageFrame)
			#newTween.tween_property(dest_page,"")
			newTween.tween_property(stageFrame,"visible",true,0.0) #.set_delay(.25)
			newTween.tween_property(dest_page,"rect_scale",Vector2(1,1),.52).from(Vector2(0,0)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			newTween.tween_property(stageFrame,"modulate:a",1.0,.75).from(0.0)
			#Globals.nextCutscene=sender.episode.parts[0]+".txt"
			#Globals.currentEpisodeData=sender.episode
			#$FadeOut.visible=true
			#print("Tweening....")
			#$AnimationPlayer.play("New Anim")
			#print("lol")
			#OffCommandNextScreen("RR-CutsceneFromFile")
			
			pass
			
func handle_RE_stage_click(event, sender, partNum):
	if event is InputEventMouseButton and event.button_index == 1:
		if event.pressed:
			print("Clicked "+partNum+", handling destination...")
			Globals.nextCutscene=partNum+".txt"
			Globals.currentEpisodeData=null

			OffCommandNextScreen("RE-CutsceneFromFile")

func input_go_back():
	if current_page==PAGE.STAGE:
		var cur_page = chapterFrame.get_node("Page"+String(chapterSelection+1))
		var dest_page = stageFrame.get_node("Chapter1-1")
		#var senderCenterPos:Vector2 = sender.rect_position+sender.rect_size/2/sender.rect_scale #-sender.rect_scale
		#cur_page.rect_pivot_offset=senderCenterPos
		#dest_page.rect_pivot_offset=senderCenterPos
		
		var newTween = get_tree().create_tween()
		newTween.set_parallel()
		newTween.tween_property(cur_page,"rect_scale",Vector2(1,1),.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		#newTween.tween_property(stageFrame)
		#newTween.tween_property(dest_page,"")
		newTween.tween_property(dest_page,"rect_scale",Vector2(0,0),.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		newTween.tween_property(stageFrame,"modulate:a",0.0,1)
		newTween.tween_property(stageFrame,"visible",false,0.0).set_delay(.65) #.set_delay(.25)
		current_page=PAGE.AREA
	else:
		OffCommandPrevScreen()
		
func _ready():
	stageFrame.visible=false
	stageFrame.rect_position=Vector2(0,0)
	
	var test = get_node("ActorFrame_AreaSelect/Page1/RE-1")
	test.connect("gui_input",self,"handle_RR_icon_click",[test])
	
	for page_ActorFrame in stageFrame.get_children():
		for obj in page_ActorFrame.get_children():
			#print(obj.get_class())
			if obj.get_class()=="Control":
				
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
		

func _input(event):
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	if Input.is_action_just_pressed("ui_cancel") or (event is InputEventMouseButton and event.button_index == BUTTON_RIGHT and event.pressed):
		input_go_back()
		return
	if current_page==PAGE.AREA:
		if Input.is_action_just_pressed("ui_right"):
			set_chapter_selection(chapterSelection+1)
		elif Input.is_action_just_pressed("ui_left"):
			set_chapter_selection(chapterSelection-1)
	elif current_page==PAGE.STAGE:
		if Input.is_action_just_pressed("ui_right"):
			set_part_selection(partSelection+1)
		elif Input.is_action_just_pressed("ui_left"):
			set_part_selection(partSelection-1)


func _on_ArrowLeft_gui_input(event):
	if event is InputEventMouseButton and event.button_index == 1 and event.pressed:
		if current_page==PAGE.AREA:
			set_chapter_selection(chapterSelection-1)
		else:
			set_part_selection(partSelection-1)

func _on_ArrowRight_gui_input(event):
	if event is InputEventMouseButton and event.button_index == 1 and event.pressed:
		if current_page==PAGE.AREA:
			set_chapter_selection(chapterSelection+1)
		else:
			set_part_selection(partSelection+1)
