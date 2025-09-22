extends "res://Screens/ScreenWithMenuElements.gd"

export(bool) var allow_user_input = true
export(float,0.5,3.0,.1) var time_before_press:float = 2.0

var timer:float = 0.0
var current_cmd = 1
onready var animPlayer = $AnimationPlayer

func _ready():
	# Disable viewport resizing for this screen...
	# AnimationPlayer can't handle multiple resolutions
	# And it's time consuming to convert everything to a tween
	get_tree().set_screen_stretch(
		SceneTree.STRETCH_MODE_2D,
		SceneTree.STRETCH_ASPECT_KEEP,
		Vector2(1920,1080)
	)
	$Music.load_song("re/1-01 - FINAL FANTASY XIII-2 Overture")
	for i in range(1, $Sequence.get_child_count()):
		$Sequence.get_child(i).visible = false
	animPlayer.play("1")
	
	set_process_input(allow_user_input)
	set_process(true)
	

func next_sequence():
	current_cmd+=1
	if current_cmd > 32:
		set_process_input(false)
		#Enable viewport resize
		get_tree().set_screen_stretch(
			SceneTree.STRETCH_MODE_2D,
			SceneTree.STRETCH_ASPECT_EXPAND,
			Vector2(1920,1080)
		)
		OffCommandOverlay()
		return
	if animPlayer.is_playing():
		animPlayer.advance(3.0)
	animPlayer.play(String(current_cmd))
	$Label.text = String(current_cmd)
	#if allow_user_input:
	#	$PageTurn.play()

func _input(event):
	if (
		event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT
	) or (
		event is InputEventScreenTouch and event.is_pressed()
	) or event.is_action_pressed("ui_select"):
		$PageTurn.play()
		next_sequence()

	elif event.is_action("DebugSpeedupTween"):
		if event.is_pressed():
			Engine.time_scale = 2.0
		else:
			Engine.time_scale = 1.0
	elif event.is_action("DebugSlowdownTween"):
		if event.is_pressed():
			Engine.time_scale = 0.25
		else:
			Engine.time_scale = 1.0


func _process(delta):
	
	if allow_user_input:
		if Input.is_action_pressed("vn_skip"):
			current_cmd = 999
			next_sequence()
	else:
		timer += delta
		if timer > time_before_press:
			timer -= time_before_press
			next_sequence()
