extends "res://Screens/ScreenWithMenuElements.gd"

var curPage=0
onready var t:Tween = $Tween

func _ready():
	$smSound.load_song("Negai")
	$Page2.rect_position.x=get_viewport().get_visible_rect().size.x


func _on_OKButton_gui_input(event):
	if (event is InputEventMouseButton and event.pressed and event.button_index == 1):
		$Click.play()
		OffCommandPrevScreen()

func _input(_event):
#	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel"):
#		OffCommandPrevScreen()
	if Input.is_action_just_pressed("ui_right") and curPage==0:
		set_page(1)
	elif Input.is_action_just_pressed("ui_left") and curPage==1:
		set_page(0)
	elif Input.is_action_just_pressed("ui_pause") and curPage==1:
		_on_HoyostansButton_pressed()
		

func set_page(i:int):
	if i==0:
		curPage=0
		var s = get_viewport().get_visible_rect().size.x
		t.interpolate_property($Page1,"rect_position:x",null,0,.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
		t.interpolate_property($Page2,"rect_position:x",null,s,.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
		t.interpolate_property($Arrow,"rect_scale:x",null,1,.3)
		t.start()
	else:
		curPage=1
		var s = get_viewport().get_visible_rect().size.x
		t.interpolate_property($Page1,"rect_position:x",null,s*-1,.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
		t.interpolate_property($Page2,"rect_position:x",null,0,.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
		t.interpolate_property($Arrow,"rect_scale:x",null,-1,.3)
		t.start()
		

func _on_Arrow_gui_input(event):
	if (event is InputEventMouseButton and event.button_index==1 and event.pressed) or (event is InputEventScreenTouch and event.index==1):
		if curPage==0:
			set_page(1)
		else:
			set_page(0)


func _on_HoyostansButton_pressed():
	OS.shell_open("https://hoyostans.be")
