extends Control

var MAINMENU = [
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
		"screen":"ScreenSoundTest"
	},
	{
		"name":'Options'
	},
	{
		"name":"Quit",
		"screen":"Quit"
	}
]

const SPACING = 200

var keyboard_selection:int=0
var next_screen:String = ""

#onready var t:Tween = $Tween
func _ready():
	#$DebugLabel.visible=OS.is_debug_build()
	#var quad = $ColorRect
	#quad.visible=true
	var t = get_tree().create_tween().set_parallel(true)
	var f:Node2D = $ActorFrame
	var count = f.get_child_count()
	var center = floor(count/2)
	for i in range(count):
		var c = f.get_child(i)
		c.connect("clicked",self,"handle_clicked",[i])
		c.position = Vector2(100,-SPACING*center+i*SPACING)
		c.set_by_name(MAINMENU[i]['name'])
		# cmd(sleep,.3+.1*i;decelerate,.3;position:x,-274);
		t.tween_property(c,"position:x",-274,.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(.3+.1*i)
	#t.interpolate_property(quad,"modulate:a",1,0,.5)
	
	$smSound.load_song("Significance");

func _process(_delta):
	var s = get_viewport().get_visible_rect().size
	$ActorFrame.position=Vector2(s.x,s.y/2)
	$CPUParticles2D.position.y=s.y+20
	$CPUParticles2D2.position.y=s.y+20

func update_keyboard_selections():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	$DebugLabel.text=String(keyboard_selection)
	
	var f:Node2D = $ActorFrame
	var count = f.get_child_count()
	for i in range(count):
		if keyboard_selection==i:
			f.get_child(i)._on_TextureRect2_mouse_entered()
		else:
			f.get_child(i)._on_TextureRect2_mouse_exited()

func _input(event):
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_just_pressed("ui_down"):
		if keyboard_selection<$ActorFrame.get_child_count()-1:
			keyboard_selection+=1
		else:
			keyboard_selection=0
		update_keyboard_selections()
	elif Input.is_action_just_pressed("ui_up"):
		if keyboard_selection<=0:
			keyboard_selection=$ActorFrame.get_child_count()-1
		else:
			keyboard_selection-=1
		update_keyboard_selections()
	elif Input.is_action_just_pressed("ui_shift") or Input.is_action_just_pressed("ui_pause"):
		_on_OKButton_pressed()
	elif Input.is_action_just_pressed("ui_select"):
		handle_clicked(keyboard_selection)

#If Android back button pressed
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		$ColorRect.OffCommand("Quit")

func handle_clicked(sender:int):
	var info = MAINMENU[sender]
	#t.interpolate_property($ColorRect,"modulate:a",0,1,.5)
	if 'screen' in info:
		next_screen = info['screen']
		#print("Go to "+next_screen)
		$ColorRect.OffCommand(next_screen)
		#t.start()
		#yield(t,"tween_completed")
		#Globals.change_screen(get_tree(),next_screen)
	elif info['name']=="Options":
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
