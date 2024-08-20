extends Control
signal selected_choice(selection)

const MAX_NUM_CHOICES:int = 5
onready var choiceFrame = $ChoiceFrame
var currentChoiceSize:int=MAX_NUM_CHOICES
var selection:int=0

const SCREEN_RESOLUTION:Vector2 = Vector2(1920,1080)
var SCREEN_CENTER:Vector2=SCREEN_RESOLUTION/2
#var SCALE = SCREEN_RESOLUTION.x/1280
var spacing:int = 120
#var RECT_WIDTH = SCREEN_RESOLUTION.x*SCALE
#var RECT_HEIGHT = 

var seq:SceneTreeTween
func _ready():
	for i in range(MAX_NUM_CHOICES):
		var f = choiceFrame.get_child(i)
		f.connect("mouse_entered",self,"handle_mouse",[i])
		f.connect("mouse_exited",self,"handle_mouse",[-1])
		f.connect("gui_input",self,"onClickWrapper",[i])
	
	setChoices(["Hello","World",'Choice 3'])
	OnCommand()
	#rect_position=Globals.SCREEN_CENTER
	pass
	
func update_selections():
	for i in range(currentChoiceSize):
		choiceFrame.get_child(i).focused=(i==selection)
	pass

func setChoices(choices:PoolStringArray,default_selection:int=0):
	currentChoiceSize=choices.size()
	#var maxWidth=400*SCALE
	for i in range(MAX_NUM_CHOICES):
		var c = choiceFrame.get_child(i)
		if i < currentChoiceSize:
			c.text=choices[i]
			c.visible=true
		else:
			c.visible=false
		c.rect_position=Vector2(
			SCREEN_CENTER.x-c.rect_size.x/2,
			SCREEN_CENTER.y-100-c.rect_size.y/2+i*spacing-(currentChoiceSize-1)*spacing/2.0
		)
		#print(c.rect_position)
	selection=default_selection
	update_selections()

func OnCommand():
	self.visible=true
	if seq and seq.is_valid():
		seq.kill()
	seq = get_tree().create_tween()
	$Dim.modulate.a=0
	seq.tween_property($Dim,"modulate:a",1,.5)
	
	for i in range(currentChoiceSize):
		var f = choiceFrame.get_child(i)
		f.modulate.a=0
		var origPos = SCREEN_CENTER.x-f.rect_size.x/2
		if i&1: #If odd
			f.rect_position.x=origPos+200
		else:
			f.rect_position.x=origPos-200
		seq.parallel().tween_property(f,'rect_position:x',origPos,.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		seq.parallel().tween_property(f,'modulate:a',1,.5)

func OffCommand():
	if seq.is_valid():
		seq.kill()
	seq = get_tree().create_tween()
	seq.tween_property($Dim,"modulate:a",0,.3)
	
	for i in range(currentChoiceSize):
		var f = choiceFrame.get_child(i)
		var newPos = f.rect_position.x
		if i&1: #If odd
			newPos+=200
		else:
			newPos-=200
		seq.parallel().tween_property(f,'rect_position:x',newPos,.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		seq.parallel().tween_property(f,'modulate:a',0,.3)
	seq.tween_property(self,"visible",false,0)

#func getYpos()->int:
#	return 720/2-(currentChoiceSize-1)*spacing/2

func input_up():
	if selection > 0:
		selection-=1
		update_selections()
func input_down():
	if selection < currentChoiceSize-1:
		selection+=1
		update_selections()

func input_accept():
	if selection!=-1:
		print("Player picked choice "+String(selection))
		emit_signal("selected_choice",selection)
		OffCommand()

func _input(_event):
	if !visible:
		return
	if Input.is_action_just_pressed("ui_up"):
		input_up()
	elif Input.is_action_just_pressed("ui_down"):
		input_down()
	elif Input.is_action_just_pressed("ui_select"):
		print("[ChoiceHandler] ui_select!")
		input_accept()
		get_tree().set_input_as_handled()
	elif Input.is_action_just_pressed("DebugButton2"):
		OnCommand()

func handle_mouse(selection_:int):
	selection=selection_
	update_selections()

func onClickWrapper(event:InputEvent,selection_:int=-1):
	if event is InputEventMouseButton and event.button_index == 1 and event.pressed:
		print("choice clicked, setting selection to "+String(selection))
		selection=selection_
		input_accept()
