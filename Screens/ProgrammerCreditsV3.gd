extends "res://Screens/ScreenWithMenuElements.gd"

var curPage=0
const NUM_PAGES = 3
onready var t:Tween = $Tween

func _ready():
	$smSound.load_song("Negai")
	
	var s = get_viewport().get_visible_rect().size.x
	$Pages/Page2.rect_position.x=s
	$Pages/Page3.rect_position.x=s*2


func _on_OKButton_gui_input(event):
	if (event is InputEventMouseButton and event.pressed and event.button_index == 1):
		$Click.play()
		OffCommandPrevScreen()
		
var time_between_mousewheel = 0
func _input(_event):
#	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel"):
#		OffCommandPrevScreen()
	if Input.is_action_just_pressed("ui_right"):
		set_page(curPage+1)
	elif Input.is_action_just_pressed("ui_left"):
		set_page(curPage-1)
#	elif Input.is_action_just_released("mousewheel_down") and curPage < NUM_PAGES-1:
#		set_page(curPage+1)
	elif Input.is_action_just_pressed("ui_pause"):
		if curPage==1:
			_on_FoxgirlButton_pressed()
		elif curPage==2:
			_on_FoxgirlButton_pressed()
	
	if _event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif _event is InputEventMouseButton and _event.button_index == BUTTON_RIGHT:
		OffCommandPrevScreen()
		
	elif _event is InputEventMouseButton:
		if _event.button_index == BUTTON_WHEEL_DOWN:
			if abs(time_between_mousewheel - Time.get_ticks_usec()) > 250000:
				time_between_mousewheel = Time.get_ticks_usec()
				set_page(curPage+1)
		elif _event.button_index == BUTTON_WHEEL_UP:
			
			if abs(time_between_mousewheel - Time.get_ticks_usec()) > 250000:
				time_between_mousewheel = Time.get_ticks_usec()
				set_page(curPage-1)
#	elif _event is InputEventMouseButton:
#		match _event.button_index:
#			BUTTON_WHEEL_UP:
#

func set_page(i:int):
	if i < 0 or i >= NUM_PAGES:
		return
	var s = get_viewport().get_visible_rect().size.x
	$Pages/Page2.rect_position.x=s
	$Pages/Page3.rect_position.x=s*2
	
	#print(i*s)
	if i==0:
		t.interpolate_property($LeftArrow,"rect_position:x",null,$LeftArrow.rect_size.x*-1,.2,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	else:
		t.interpolate_property($LeftArrow,"rect_position:x",null,0,.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	
	if i==NUM_PAGES-1:
		t.interpolate_property($RightArrow,"rect_position:x",null,s,.2,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	else:
		t.interpolate_property($RightArrow,"rect_position:x",null,s-$RightArrow.rect_size.x,.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	
	
	t.interpolate_property($Pages,"rect_position:x",null,i*s*-1,.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	
	var bg = $TextureRect
	var rect_lim = float(i)/float(NUM_PAGES)*(s-bg.rect_size.x)
	#print(rect_lim)
	t.interpolate_property($TextureRect,"rect_position:x",null,rect_lim,.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	t.start()
	curPage=i
		

func _on_LeftArrow_gui_input(event):
	if (event is InputEventMouseButton and event.button_index==1 and event.pressed) or (event is InputEventScreenTouch and event.index==1):
		if curPage > 0:
			set_page(curPage-1)
func _on_Arrow_gui_input(event):
	if (event is InputEventMouseButton and event.button_index==1 and event.pressed) or (event is InputEventScreenTouch and event.index==1):
		if curPage < NUM_PAGES-1:
			set_page(curPage+1)

func _on_HoyostansButton_pressed():
	OS.shell_open("https://hoyostans.be")

func _on_FoxgirlButton_pressed():
	OS.shell_open("https://discord.gg/6thCMjFHFR")


