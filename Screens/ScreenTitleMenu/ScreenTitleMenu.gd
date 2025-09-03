extends Control

var MAINMENU_BASE = [
	{
		'name':"Read",
		#'submenu':false,
		'screen':"ScreenSelectChapter"
	},
	{
		'name':"Gallery",
		'screen':"ScreenGallery"
	},
	{
		'name':"Music",
		"screen":"ScreenSoundTest",
		'demo':false,
	},
	{
		"name":'Options'
	},
	{
		"name":"Quit",
		"screen":"Quit",
		'demo':false
	}
]
var mainMenu_runtime = []

export (bool) var enable_alternate_bg_in_debug = false
const SPACING = 200

var keyboard_selection:int=0
var next_screen:String = ""

#onready var t:Tween = $Tween
func _ready():
	var isMultiStory = Globals.installedPacks & Globals.DLC_PACK.RE_RR or Globals.previous_screen == "ScreenSelectEra"
	
	for i in range(len(MAINMENU_BASE)):
		if 'demo' in MAINMENU_BASE[i] and OS.has_feature('demo'):
				if MAINMENU_BASE[i]['demo']==true:
					mainMenu_runtime.append(MAINMENU_BASE[i])
		elif isMultiStory and 'screen' in MAINMENU_BASE[i] and MAINMENU_BASE[i]['screen']=="Quit":
			mainMenu_runtime.append({
				"name":"Back",
				"screen":"ScreenSelectEra"
			})
		else:
			mainMenu_runtime.append(MAINMENU_BASE[i])
				
				
	#$DebugLabel.visible=OS.is_debug_build()
	#var quad = $ColorRect
	#quad.visible=true
	var t = get_tree().create_tween().set_parallel(true)
	var f:Node2D = $ActorFrame
	var count = len(mainMenu_runtime)
	var center = floor(count/2)
	for i in range(f.get_child_count()):
		var c = f.get_child(i)
		if i < count:
			c.connect("clicked",self,"handle_clicked",[i])
			c.position = Vector2(100,-SPACING*center+i*SPACING)
			c.set_by_name(mainMenu_runtime[i]['name'])
			# cmd(sleep,.3+.1*i;decelerate,.3;position:x,-274);
			t.tween_property(c,"position:x",-274,.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(.3+.1*i)
		else:
			c.visible=false
			c.position=Vector2(-999,-999)
	#t.interpolate_property(quad,"modulate:a",1,0,.5)
	
	
	var USE_ALT_BG = OS.is_debug_build() and enable_alternate_bg_in_debug
	#Check if "The Savior" and "Ending" in Chapter 7.5 are read
	USE_ALT_BG = USE_ALT_BG or Globals.playerData['completedChapters'][9] & 24
	if USE_ALT_BG:
		$smSound.load_song("Negai");
		$smSprite.loadVNBG("011/023_1280x720")
		$Kyuushou.visible = false
	else:
		$smSound.load_song("Significance");
	update_background_parallax(get_viewport().get_mouse_position())


var fakeMousePos:Vector2 = Globals.gameResolution/2

var logo_timeout:float = 3.0
var noinputs:float = 0.0

func _process(delta):
	var s = get_viewport().get_visible_rect().size
	$ActorFrame.position=Vector2(s.x,s.y/2)
	$CPUParticles2D.position.y=s.y+20
	$CPUParticles2D2.position.y=s.y+20
	
	if OS.has_feature("mobile"):
		var gyro = Input.get_gyroscope()
		
		#gyro axis is flipped since device is held landscape
		var newGyro = Vector2(fakeMousePos.x+gyro.y*22,fakeMousePos.y+gyro.x*17)
		var LIMIT:Vector2 = Globals.gameResolution
		if newGyro.x > 0 and newGyro.x < LIMIT.x:
			fakeMousePos.x = newGyro.x
		if newGyro.y > 0 and newGyro.y < LIMIT.y:
			fakeMousePos.y = newGyro.y
		$DebugLabel2.text="Gyro: "+String(gyro)
		$DebugLabel2.text+="\nFakeMouse: "+String(fakeMousePos)
		update_background_parallax(fakeMousePos)
		#$DebugLabel2.text+="\nAccel: "+String(Input.get_accelerometer())
	elif Input.is_action_pressed("right_analog_down") or \
	Input.is_action_pressed("right_analog_up") or \
	Input.is_action_pressed("right_analog_left") or \
	Input.is_action_pressed("right_analog_right"):
	
		var yVel = Input.get_action_strength("right_analog_up")*-1+Input.get_action_strength("right_analog_down")
		var xVel = Input.get_action_strength("right_analog_left")*-1+Input.get_action_strength("right_analog_right")
#		var newGyro = Vector2(fakeMousePos.x+xVel*42,fakeMousePos.y+yVel*30)
#		var LIMIT:Vector2 = Globals.gameResolution
#		if newGyro.x > 0 and newGyro.x < LIMIT.x:
#			fakeMousePos.x = newGyro.x
#		if newGyro.y > 0 and newGyro.y < LIMIT.y:
#			fakeMousePos.y = newGyro.y
#		update_background_parallax(fakeMousePos)
		var center = Globals.gameResolution/2
		center*=Vector2(xVel,yVel)
		update_background_parallax(Globals.gameResolution/2+center)
		
	#if OS.is_debug_build():
	#	$DebugFPSLabel.text=String(Engine.get_frames_per_second())
#	if logo_timeout > 0:
#		var rand_x_v = logo_timeout/3.0 + randf()/4.0
#		logo_timeout-=_delta
#		if logo_timeout<=0:
#			rand_x_v = 0.0
#		$Logo.get_material().set_shader_param("dir",Vector2(rand_x_v,0))
			
	noinputs+=delta
	if noinputs > 30.0:
		noinputs = -INF
		set_process_input(false)
		$ColorRect.OffCommand("ScreenOpening")
		#get_tree().change_scene("res://Screens/ScreenOpening/ScreenOpening2.tscn")
		#set_process(false)

func update_keyboard_selections():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	noinputs = 0.0
	#$DebugLabel.text=String(keyboard_selection)
	
	var f:Node2D = $ActorFrame
	var count = f.get_child_count()
	for i in range(count):
		if keyboard_selection==i:
			f.get_child(i)._on_TextureRect2_mouse_entered()
		else:
			f.get_child(i)._on_TextureRect2_mouse_exited()
	$Navigation.play()

func update_background_parallax(mousePos:Vector2):
		var mousePosOffsetFromCenter = mousePos-Globals.gameResolution/2

		#$DebugLabel2.text = "Mouse: "+String(mousePosOffsetFromCenter)
		$smSprite.rect_position=-mousePosOffsetFromCenter*.05
		$Kyuushou.rect_position=-mousePosOffsetFromCenter*.03
		#When mousePos is Globals.gameResolution/2, offset should be 0
		#The size of the image is gameResolution*1.2
		#So when the mouse is all the way on the left it would be
		#gameResolution.x*1.1 -gameResolution.x/2+mousePosOffsetFromCenter
		#$smSprite.rect_position = SCREEN_SIZE*1.1 - SCREEN_SIZE/2+mousePosOffsetFromCenter
		


func _input(event:InputEvent):
	if event is InputEventMouseMotion:
		noinputs = 0.0
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		#var SCREEN_SIZE = Globals.gameResolution
		#var mouseZoom = Globals.gameResolution*1.2
		if !OS.has_feature("mobile"):
			update_background_parallax(event.position)
	#elif event is InputEventJoypadMotion:
	#if !event.is_pressed():
	#	return
	
	if event.is_action_pressed("ui_down", true):
		if keyboard_selection<$ActorFrame.get_child_count()-1:
			keyboard_selection+=1
		else:
			keyboard_selection=0
		update_keyboard_selections()
	elif event.is_action_pressed("ui_up",true):
		if keyboard_selection<=0:
			keyboard_selection=$ActorFrame.get_child_count()-1
		else:
			keyboard_selection-=1
		update_keyboard_selections()
	elif event.is_action_pressed("ui_shift") or event.is_action_pressed("ui_pause"):
		_on_OKButton_pressed()
	elif event.is_action_pressed("ui_select"):
		handle_clicked(keyboard_selection)
	elif event.is_action_pressed("ui_cancel"):
		handle_clicked(4)

#If Android back button pressed
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		$ColorRect.OffCommand("Quit")

func handle_clicked(sender:int):
	noinputs = 0.0
	var info = mainMenu_runtime[sender]
	#t.interpolate_property($ColorRect,"modulate:a",0,1,.5)
	if 'screen' in info:
		next_screen = info['screen']
		#print("Go to "+next_screen)
		$ConfirmScreen.play()
		$ColorRect.OffCommand(next_screen,"ScreenTitleMenu")
		#t.start()
		#yield(t,"tween_completed")
		#Globals.change_screen(get_tree(),next_screen)
	elif info['name']=="Options":
		$ConfirmOverlay.play()
		$OptionsScreen.visible=true
		$OptionsScreen.OnCommand()
	else:
		print("No screen in dict!")
		print(info)


func _on_OKButton_pressed():
	$Click.play()
	$ColorRect.OffCommand("ScreenProgrammerCredits")


func _on_OptionsScreen_options_closed():
	#print("User closed options")
#	isOptionsScreenOpen=false
	$OptionsScreen.visible=false


var timesClicked = 0
func _on_Logo_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		timesClicked+=1
		if timesClicked>7:
			#$ColorRect.OffCommand("RR-ScreenTitleMenu")
			$DebugPanel.visible = true
