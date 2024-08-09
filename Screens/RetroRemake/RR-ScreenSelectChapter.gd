extends "res://Screens/ScreenWithMenuElements.gd"

const SCREEN_WIDTH = 1920
const start = 1
var selection:int = start
var numChapters:int=0

#class Episode:
#	#There is no easy way to get the parent without iterating through the
#	#whole dict so put it here too
#	var parentChapter:String
#	var title:String
#	var desc:String
#	var parts:Array
#	var isSub:bool=false

var retroRemake_database = {}

#func build_rr_database():

onready var chapterFrame = $ActorFrame
onready var t = $Tween
func _ready():
	$Label.visible=OS.is_debug_build()
	numChapters = chapterFrame.get_child_count()
	for i in range(numChapters):
		var chapterActor = chapterFrame.get_child(i)
		retroRemake_database[chapterActor.name] = []
		for obj in chapterActor.get_children():
			if obj.is_class("TextureRect"):
				var ep = Globals.Episode.new()
				ep.parentChapter=chapterActor.name
				ep.title=obj.name
				ep.desc=obj.name #Doesn't matter since translation engine will put the real name
				ep.parts=find_episode_parts(obj.name)
				ep.isSub=("S" in obj.name)
				
				retroRemake_database[chapterActor.name].append(ep)
				obj.episode = ep
				
				obj.mouse_default_cursor_shape = CURSOR_POINTING_HAND
				obj.connect("gui_input",self,"handle_RR_icon_click",[obj])
		
		chapterActor.position.x=i*SCREEN_WIDTH
	repositionFrame(start)

func repositionFrame(sel:int, tweenTime:float=.5):
	$Label.text= "Position: "+String(sel)
	t.remove_all()
	t.interpolate_property(chapterFrame,"position:x",null,-SCREEN_WIDTH*sel,tweenTime,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	t.start()
	#chapterFrame.position.x=
	
func set_selection(new_sel:int):
	if new_sel>=numChapters:
		selection=0
	elif new_sel < 0:
		selection=numChapters-1
	else:
		selection=new_sel
	repositionFrame(selection)

func find_episode_parts(startingName:String)->Array:
	var a = [startingName]
	var path = Globals.get_cutscene_path()
	var f = File.new()
	for i in range(2,99):
		var fName = startingName+"_"+String(i)
		if f.file_exists(path+fName+".txt"):
			a.append(fName)
		else:
			break
	f.close()
	print("Got episode parts "+String(a))
	return a

func _input(event):
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	if Input.is_action_just_pressed("ui_right"):
		set_selection(selection+1)
	elif Input.is_action_just_pressed("ui_left"):
		set_selection(selection-1)

func handle_RR_icon_click(event,sender):
	if event is InputEventMouseButton and event.button_index == 1:
		if event.pressed:
			print("Clicked")
			print(sender.episode)
			#emit_signal("clicked")
			
			print("Handling destination...")
			Globals.nextCutscene=sender.episode.parts[0]+".txt"
			Globals.currentEpisodeData=sender.episode
			#$FadeOut.visible=true
			#print("Tweening....")
			#$AnimationPlayer.play("New Anim")
			#print("lol")
			OffCommandNextScreen("RR-CutsceneFromFile")
			
			pass
