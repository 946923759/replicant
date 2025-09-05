extends ScrollContainer

export(int) var selected:int = 1
export(bool) var show_scrollbar = false

var tw:Tween

onready var chapter_actor_frame = $MarginContainer/HBoxContainer

func _ready():
	#get_h_scrollbar().visible = show_scrollbar
	get_h_scrollbar().rect_scale.y = 0.0
	
	tw = Tween.new()
	add_child(tw)
	
	#chapter_actor_frame.get_child(selected).GainFocusNoTween()
	#for c in chapter_actor_frame.get_children():
	for i in range(chapter_actor_frame.get_child_count()):
		var c:Control = chapter_actor_frame.get_child(i)
		c.connect("gui_input",self,"set_selection_from_mouse",[i])
		c.connect("button_pressed",self,"handle_btn_press")
	#print(get_h_scrollbar().max_value)
	#call_deferred("reposition_actors")
	#reposition_actors()
	#print(get_h_scrollbar().max_value)
	

#//Stolen from RageUtil
#/**
# * @brief Scales x so that l1 corresponds to l2 and h1 corresponds to h2.
# *
# * This does not modify x, so it MUST assign the result to something!
# * Do the multiply before the divide to that integer scales have more precision.
# *
# * One such example: SCALE(x, 0, 1, L, H); interpolate between L and H.
# */
static func SCALE(x:float, l1:float, h1:float, l2:float, h2:float)->float:
	return (((x) - (l1)) * ((h2) - (l2)) / ((h1) - (l1)) + (l2))

#func reposition_actors():
#
#	var current_actor = get_child(selected)
#	tw.stop_all()
#
#	if current_actor.is_expanded:
#		# Who fucking designs this shit seriously
#		# the Control has a size so top left is 0x0 which means center is actually size/2
#		# But child actors aren't centered either because fuck you I guess
#		# This engine is so stupid at positioning I swear to god. Just make every object centered like StepMania. PLEASE.
#		tw.interpolate_property(
#			current_actor, 
#			"rect_position:x",
#			null,
#			rect_size.x/2.0-current_actor.rect_dest_size.x/2.0,
#			.3,
#			Tween.TRANS_QUAD,
#			Tween.EASE_OUT
#		)
#	else:
#		for actor in get_children():
#			if !(actor is Control):
#				continue
#
#	tw.start()

#func get_x_position_on_screen():
#	var x_position_on_screen:float = 0.0

func get_scroller_viewport_rect() -> Rect2:
	var actor_frame_width = $MarginContainer.rect_size.x
	var scrollbar_x_position_in_actor_frame = SCALE(scroll_horizontal, 0, get_h_scrollbar().max_value, 0, actor_frame_width)
	var viewport_rect:Rect2 = Rect2(Vector2(scrollbar_x_position_in_actor_frame,0),rect_size)
	#print(get_h_scrollbar().max_value)
	return viewport_rect
	
func get_actor_rect_in_frame(actor_number:int) -> Rect2:
	#We have a margin so starting x position inside the frame is >0
	var obj_x_position_in_actor_frame:float = $MarginContainer.get("custom_constants/margin_left")
	var actor_frame_width = $MarginContainer.rect_size.x
	for i in range(actor_number):
		#print(i," ",chapter_actor_frame.get_child(i).rect_dest_size.x)
		obj_x_position_in_actor_frame += chapter_actor_frame.get_child(i).rect_dest_size.x + chapter_actor_frame.get("custom_constants/separation")
		#obj_x_position_in_actor_frame += chapter_actor_frame.get("custom_constants/separation")
	var object_rect:Rect2 = Rect2(
		Vector2(obj_x_position_in_actor_frame, 0), 
		chapter_actor_frame.get_child(actor_number).rect_dest_size + Vector2(chapter_actor_frame.get("custom_constants/separation"),0)
	)
	return object_rect

#Call this with call_deferred if you're doing it on _ready because idk godot is stupid
func reposition_actors(center_selected:bool = true, animate:bool = true):
	#print(selected)
	#var current_actor = chapter_actor_frame.get_child(selected)
	#tw.stop_all()
	
	
	# This is the worst designed shit ever
	# Anyways. We want the object to be centered, so
	# map the x position in the actor to the x position on the scroll bar.
	var intended_x_position_on_screen:float = 0.0
	
	var actor_frame_width = $MarginContainer.rect_size.x
	var object_rect:Rect2 = get_actor_rect_in_frame(selected)
	var scroller_rect:Rect2 = get_scroller_viewport_rect()
	
	#if !center_selected:
	if false:
	
		var is_object_within_rect = object_rect.intersects(scroller_rect)
		#print("is object within rect? ",is_object_within_rect)
		#print(viewport_rect)
		#print("frame pos: ",scrollbar_x_position_in_actor_frame,"| obj x pos: ",obj_x_position_in_actor_frame)
	
		if !is_object_within_rect:
			intended_x_position_on_screen = object_rect.position.x
			#if object_rect.position.x > viewport_rect.position.x + viewport_rect.size.x:
			#	intended_x_position_on_screen = viewport_rect.position.x+viewport_rect.size.x - object_rect.size.x - 100
			#else:
			#	intended_x_position_on_screen = viewport_rect.position.x + 100
	
	else:
		#print("scroll rect: ",get_scroller_viewport_rect(), " | actor ",selected," rect: ",get_actor_rect_in_frame(selected))
		# we want the viewport x position to start drawing LEFT of the object.
		# and we want the object to be centered. so first, center this object.
		intended_x_position_on_screen = object_rect.position.x + (object_rect.size.x - chapter_actor_frame.get("custom_constants/separation"))/2.0
		# now make this object centered on screen
		intended_x_position_on_screen -= scroller_rect.size.x/2
		#print(intended_x_position_on_screen)
		
	
	#print(obj_x_position_in_actor_frame)
	#print(obj_x_position_in_actor_frame/actor_frame_width)
	var scroll_pos = SCALE(intended_x_position_on_screen, 0, actor_frame_width, 0, get_h_scrollbar().max_value)
	#print(scroll_pos)
	if animate:
		tw.remove_all()
		tw.interpolate_property(
			self, 
			"scroll_horizontal",
			null,
			scroll_pos,
			.3,
			Tween.TRANS_QUAD,
			Tween.EASE_OUT
		)
		tw.start()
	else:
		scroll_horizontal = scroll_pos

#	if current_actor.is_expanded:
#		# This is the worst designed shit ever
#		# Anyways. We want 
#		var intended_x_position_on_screen:float = 0.0
#		var obj_x_position_in_actor_frame:float = 0.0
#		for i in range(selected):
#
#		#var intended_x_position_on_screen:float = rect_size.x/2.0-current_actor.rect_dest_size.x/2.0
#
#
#		# Who fucking designs this shit seriously
#		# the Control has a size so top left is 0x0 which means center is actually size/2
#		# But child actors aren't centered either because fuck you I guess
#		# This engine is so stupid at positioning I swear to god. Just make every object centered like StepMania. PLEASE.
#		tw.interpolate_property(
#			current_actor, 
#			"rect_position:x",
#			null,
#			rect_size.x/2.0-current_actor.rect_dest_size.x/2.0,
#			.3,
#			Tween.TRANS_QUAD,
#			Tween.EASE_OUT
#		)
#	else:
#		for actor in get_children():
#			if !(actor is Control):
#				continue

	#tw.start()

func set_selection_from_mouse(event:InputEvent, idx:int):
	if (event is InputEventMouseButton and event.button_index==1 and event.pressed) or (event is InputEventScreenTouch and event.index==1):
		selected = idx
		for i in range(chapter_actor_frame.get_child_count()):
			if i != selected:
				chapter_actor_frame.get_child(i).LoseFocus()
			else:
				chapter_actor_frame.get_child(i).GainFocus().set_selection(-1)
		reposition_actors()
		$Confirm.play()

func set_selection(idx:int, animate:bool = true):
	
	if idx > chapter_actor_frame.get_child_count() or idx < 0:
		print("Hey idiot, you can't set scroller selection of ",idx)
		return
	
	selected = idx
	#print("set selection ",selected)
	
	for i in range(chapter_actor_frame.get_child_count()):
		if i != selected:
			chapter_actor_frame.get_child(i).LoseFocus()
		else:
			if animate:
				chapter_actor_frame.get_child(selected).GainFocus().set_selection(0)
			else:
				chapter_actor_frame.get_child(selected).GainFocusNoTween().set_selection(0)
	#print("Reposition")
	#reposition_actors()
	#reposition_actors()
	#reposition_actors()
	reposition_actors(true, animate)
	#var tw = create_tween()
	#tw.tween_callback(self,"reposition_actors").set_delay(.3)

func _input(event):
	var current_actor = chapter_actor_frame.get_child(selected)
	if event.is_action_pressed("ui_select"):
		if current_actor.is_expanded:
			current_actor.input(event)
			return
		
		
		set_selection(selected,true)
		$Confirm.play()
#	elif event.is_action_pressed("ui_cancel"):
#		for c in chapter_actor_frame.get_children():
#			c.LoseFocus()
#		#current_actor.LoseFocus()
#		reposition_actors()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_page_down"):
		if selected < chapter_actor_frame.get_child_count()-1:
			selected += 1
		else:
			selected = 0
		$Cursor.play()
		reposition_actors()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_page_up"):
		if selected > 0:
			selected -= 1
		else:
			selected = chapter_actor_frame.get_child_count() - 1
		$Cursor.play()
		reposition_actors()
	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		if current_actor.is_expanded:
			$Cursor.play()
			current_actor.input(event)
		#print("scroll rect: ",get_scroller_viewport_rect(), " | actor ",selected," rect: ",get_actor_rect_in_frame(selected), " | scroller: ",get_h_scrollbar().max_value)
		#reposition_actors()

func handle_btn_press(vnPlayerDest:String, episodeDest:Globals.Episode):
	print("Handling destination...")
	$Confirm.play()
	Globals.nextCutscene=vnPlayerDest+".txt"
	Globals.currentEpisodeData=episodeDest
	get_parent().OffCommandNextScreen()
