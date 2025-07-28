extends Control

onready var scrollContainer:ScrollContainer=$ScrollContainer
onready var container:Container = $ScrollContainer/VBoxContainer
var font = preload("res://Fonts/TextFont.tres")
export(PackedScene) var history_scroll_object
#const fadeTop = preload("res://Shaders/FadeTopShader.tres")

func _ready():
	if true: #!OS.is_debug_build()
		for i in range(3):
			container.get_child(i).visible=false
#		for c in container.get_children():
#			c.queue_free()
		#var d = ColorRect.new()
		#d.color.a = 0
		#d.rect_min_size.y = 100
		#d.use_parent_material = true
		#container.add_child(d)
	#if !(get_parent() is Control):
		
	#test_history()

# Notice the lack of _, This is sent by CutsceneMain.
func process(delta):
	var d = delta*50
	#print("Input!")
	if Input.is_action_pressed("ui_down"):
		scrollContainer.scroll_vertical= (scrollContainer.scroll_vertical + 40*d)
#	elif 
#		scrollContainer.scroll_vertical= (scrollContainer.scroll_vertical + 60)*Input.get_action_strength("analog_down")
	elif Input.is_action_pressed("ui_up"):
		scrollContainer.scroll_vertical= (scrollContainer.scroll_vertical - 40*d)
	elif Input.is_action_pressed("analog_down") or Input.is_action_pressed("analog_up"):
		#print(Input.get_action_strength("analog_down")-Input.get_action_strength("analog_up"))
		var sc = Input.get_action_strength("analog_up")*-1+Input.get_action_strength("analog_down")
		scrollContainer.scroll_vertical=scrollContainer.scroll_vertical + 60*sc*d
	# Don't combine this with the _input() below, the one below is not run within
	# the same frame so if you combine it it will close the history and then open
	# the options menu
	elif Input.is_action_just_pressed("ui_cancel"):
		get_parent().tween_out_history()

func _input(event):
	var parent = get_parent()
	if parent is Control and parent.otherScreenIsHandlingInput == parent.Overlay.HISTORY:
		if (
			(event is InputEventMouseButton and event.is_pressed() and event.button_index==2) or 
			(event is InputEventScreenTouch and event.index==1)
		):
			parent.tween_out_history()
			get_tree().set_input_as_handled()

func test_history():
	for i in range(100):
		container.add_child(SpeakerAndTextActor(
			"Speaker"+String(i), 
			"Text "+String(i)
		))
		#container.add_child(SpeakerActor("Speaker"+String(i)))
		#container.add_child(TextActor("Text "+String(i)))

func SpeakerAndTextActor(s1, s2) -> HBoxContainer:
	var inst = history_scroll_object.instance()
	inst.init(
		s1, 
		s2
	)
	return inst

#func SpeakerActor(s:String)->Label:
#	var l = Label.new()
#	#l.material=fadeTop
#	l.set("custom_fonts/font",font)
#	l.text=s
#	#How the fuck is anyone supposed to figure this out?
#	l.size_flags_vertical=1 
#	var width = font.get_string_size(l.text).x
#	if width > 300:
#		l.rect_scale.x=300/width
#	#else:
#	#	tn.rect_scale.x=1.0
#	#for property in d:
#	#	l.set(property,d[property])
#	#l.set("custom_fonts/font",font)
#	#l.add_to_group("Translatable")
#	return l
#
#func TextActor(s:String) -> RichTextLabel:
#	var l:RichTextLabel = RichTextLabel.new()
#	#l.material=fadeTop
#	l.set("custom_fonts/normal_font",font)
#	l.set("custom_constants/line_separation",9)
#	l.rect_min_size=Vector2(1300,0)
#	l.fit_content_height = true
#	l.bbcode_enabled = true
#	l.bbcode_text = s
#	return l
	
#func TextActor(s:String)->Label:
#	var l:Label = Label.new()
#	#l.material=fadeTop
#	l.set("custom_fonts/font",font)
#	l.rect_min_size=Vector2(1300,0)
#	l.autowrap=true
#	l.text = s
#	return l
	
func DividerActor() -> ColorRect:
	var d = ColorRect.new()
	#d.color.a = .5
	d.color = Color.transparent
	#d.modulate = Color.transparent
	d.rect_min_size.y = 35
	#d.use_parent_material = true
	return d

var last_history_number:int=0
func set_history(arr):
	var prev_speaker:String = ""
	
	# There's no guarentee that the last object will be a text object
	# since we mix in TextureRects... I think
	for i in range(container.get_child_count()-1, 0, -1):
		var o = container.get_child(i)
		if o is HBoxContainer:
			prev_speaker = o.speaker_text
			break
	
	for i in range(last_history_number, arr.size()):
		if prev_speaker != arr[i][0]:
			container.add_child(DividerActor())
			prev_speaker = arr[i][0]

		container.add_child(SpeakerAndTextActor(
			arr[i][0], arr[i][1]
		))
		
	last_history_number=arr.size()

	#WHY IS GODOT LIKE THIS
	yield(get_tree(), "idle_frame")
	# warning-ignore:narrowing_conversion
	scrollContainer.scroll_vertical = scrollContainer.get_v_scrollbar().max_value
