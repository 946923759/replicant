extends Control
signal mouse_selected_choice(selection)

#TODO: Add animations at some point

const Def = preload("res://stepmania-compat/StepManiaActors.gd")
const choiceShader = preload("res://Cutscene/ChoiceShaderFadeSides.tres")
var font = load("res://Cutscene/TextFont.tres")

const MAX_NUM_CHOICES:int = 5

var currentChoiceSize:int=MAX_NUM_CHOICES
var selection:int=0

const SCREEN_RESOLUTION:Vector2 = Vector2(1920,1080)
var SCREEN_CENTER:Vector2=SCREEN_RESOLUTION/2
var SCALE = SCREEN_RESOLUTION.x/1280
var spacing:int = 60*SCALE
#var RECT_WIDTH = SCREEN_RESOLUTION.x*SCALE
#var RECT_HEIGHT = 


#Since _init() runs first I don't have to worry about 
#number of existing nodes
func _init():
	for i in range(MAX_NUM_CHOICES):
		var t:Control = Control.new()
		t.name="CActorFrame"+str(i)
		t.mouse_filter=Control.MOUSE_FILTER_IGNORE
		t.rect_min_size=Vector2(SCREEN_RESOLUTION.x,30*SCALE)
		t.anchor_top=.5
		t.anchor_right=1
		t.anchor_bottom=.5
		
		#t.rect_position=Vector2(0,-15*SCALE)
		#t.name="c"+String(i)
		t.add_child(Def.Quad({
			mouse_filter=Control.MOUSE_FILTER_IGNORE,
			color=Color(0,0,0,1),
			size=Vector2(SCREEN_RESOLUTION.x,30*SCALE),
			min_size=Vector2(0,30*SCALE),
			anchor_right=1.0,
			#rect_position=,
			name="Quad"
		}))
		t.get_child(0).material=choiceShader
		t.add_child(Def.LoadFont(font,{
			mouse_filter=Control.MOUSE_FILTER_IGNORE,
			text="Choice "+String(i+1),
			align=1,
			valign=1,
			min_size=Vector2(0,50*SCALE),
			#rect_size=Vector2(0,50*SCALE), #WHY DOES IT WORK IF IT'S ZERO AAODIJOWJIROHR*#JIO3
			#anchor_left=.5,
			anchor_right=1.0,
			#rect_position=Vector2(-SCREEN_CENTER.x,-25*SCALE),
			name="Font"
		}))
		
		t.rect_position=Vector2(0,SCREEN_CENTER.y+i*spacing-(MAX_NUM_CHOICES-1)*spacing/2.0)
		#t.get_child(0).connect("gui_input",self,"_on_Control_gui_input",[i])
		add_child(t)
	#self.visible=false
func _ready():
	setChoices(["Hello","World",'Choice 3'])
	self.connect("resized",self,"update_shader")
	#rect_position=Globals.SCREEN_CENTER
	pass
	
func update_selections():
	for i in range(currentChoiceSize):
		get_child(i).modulate.a=1.0 if i==selection else .7
	pass

func setChoices(choices:PoolStringArray,default_selection:int=0):
	currentChoiceSize=choices.size()
	var maxWidth=400*SCALE
	for i in range(MAX_NUM_CHOICES):
		var c = get_child(i)
		if i < currentChoiceSize:
			c.get_child(1).text=choices[i]
			maxWidth = max(maxWidth,font.get_string_size(choices[i]).x)
			c.visible=true
		else:
			c.visible=false
		c.rect_position=Vector2(0,SCREEN_CENTER.y+i*spacing-(currentChoiceSize-1)*spacing/2.0)
	update_shader(maxWidth)
	selection=default_selection
	update_selections()
	
func update_shader(maxWidth:int=400*SCALE):
	if maxWidth<=0:
		for i in range(currentChoiceSize):
			var c = get_child(i)
			maxWidth = max(maxWidth,font.get_string_size(c.get_child(1).text).x)
	#shaders, being.. well.. shaders, work based on the 'true' resolution of the game
	#So if you have a 720p window and a 1080p game, they don't work
	#What this means is that we have to recalculate everything... Because what the heck
	#can we do about it?
	var windowSize = OS.get_real_window_size()
	var pixel_scale = windowSize.x/1280
	for i in range(MAX_NUM_CHOICES):
		get_child(i).get_child(0).get_material().set_shader_param("fadeLeftAt",windowSize.x/2-maxWidth/2-20*pixel_scale)
		get_child(i).get_child(0).get_material().set_shader_param("fadeRightAt",windowSize.x/2+maxWidth/2+20*pixel_scale)

	

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

#Actually, _clicked is never used because the ColorRect handles it...
func input_cursor(pos:Vector2,_clicked:bool=false)->bool:
	if _clicked:
		print("Got click from CutsceneMain!")
	for i in range(currentChoiceSize):
		#print(c.rect_position.y)
		#print(c.rect_position.y)
		var c = get_child(i)
		#if i==0:
		#	print(String(c.rect_position.y)+"<"+String(pos.y)+"<"+String(c.rect_position.y+c.rect_size.y))
		if pos.y > c.rect_position.y-15 and pos.y < c.rect_position.y+c.rect_size.y+15:
			selection=i
			update_selections()
			return true
	selection=-1
	update_selections()
	return false

#func input_select()->int:
#	return selection

func _input(event):
	if Input.is_action_just_pressed("ui_up"):
		input_up()
	elif Input.is_action_just_pressed("ui_down"):
		input_down()


#There is no point in doing this,
#because we can set it to ignore and let
#CutsceneMain handle it
#func _on_Control_gui_input(event,_selection:int):
#	#print("test "+str(selection))
#	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
#		print("Tapped "+str(_selection))
#		selection=_selection
#		emit_signal("mouse_selected_choice",_selection)
#	elif event is InputEventMouseMotion and selection!=_selection:
#		#return
#		selection=_selection
#		update_selections()
#	else:
#		#print("Got unknown event?!")
#		pass # Replace with function body.
