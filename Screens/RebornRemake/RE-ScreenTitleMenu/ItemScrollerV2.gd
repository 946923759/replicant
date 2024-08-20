extends Control

signal switch_submenus(new_menu)
signal selection_changed(newSel,isLocked)
signal input_accepted(selectionNum,destinationName)

enum LAYOUT {
	VERTICAL,
	HORIZONTAL,
	TILED
}
enum POSITION {
	LEFT,
	RIGHT,
	TOP,
	BOTTOM
}

export (int,0,1000) var SPACING=200
#export (Array,Dictionary) var test
export (String) var previous_submenu

export (LAYOUT) var item_placement=LAYOUT.VERTICAL
export (POSITION) var item_position=POSITION.RIGHT
#export (PackedScene) var item_to_spawn

var items:Dictionary
var keyboard_selection:int=0 setget set_selection
onready var t:Tween = $Tween

func spawnItems(items_:Dictionary):
	self.items = items_
	var f = self
	var count = len(items)
	var center = floor(count/2)
	for i in range(count):
		var c = f.get_child(i)
		c.connect("clicked",self,"input_accept",[i])
		c.position = Vector2(100,-SPACING*center+i*SPACING)
		c.set_by_name(items[i]['name'])
		t.interpolate_property(c,"position:x",null,-274,.3,Tween.TRANS_CUBIC,Tween.EASE_OUT,.3+.1*i)
	#t.interpolate_property(quad,"modulate:a",1,0,.5)
	t.start()

#After fighting with this stupid piece of shit for
#15 minutes trying to figure out why the Tween
#is the last child instead of the first, I've
#given up and just added it from the gui
#func _init():
#	t= Tween.new()
#	add_child(t)
#	#print("Children: "+String(get_child_count()))

func _ready():
	var count = get_child_count()-1
	print('[ItemScrollerV2] '+String(count)+" items in frame")
	var center = floor(count/2)
	for i in range(count):
		var c = get_child(i+1)
		#print("Got obj "+String(i)+c.get_class())
		#if c.get_class()=="Node2D":
		c.connect("clicked",self,"input_accept",[i])
		c.rect_position = Vector2(100,-SPACING*center+i*SPACING-c.size.y/2)
		if item_position==POSITION.LEFT:
			c.rect_position.x=-c.size.x-100
		print(c.rect_position)

	set_selection(0,false)
	OnCommand()

func OnCommand():
	t.remove_all()
	var SCREEN_SIZE = get_viewport().get_visible_rect().size
	
	var count = get_child_count()-1
	var center = floor(count/2)
	for i in range(count):
		var c = get_child(i+1)
		
		if item_placement==LAYOUT.VERTICAL:
			if item_position==POSITION.RIGHT:
				t.interpolate_property(c,"rect_position:x",null,-c.size.x,.3,Tween.TRANS_CUBIC,Tween.EASE_OUT,.3+.1*i)
			else:
				t.interpolate_property(c,"rect_position:x",null,0,.3,Tween.TRANS_CUBIC,Tween.EASE_OUT,.3+.1*i)
		else: #TODO: This is incorrect, ItemScroller frame is already center right
			c.position = Vector2(SCREEN_SIZE.x,0)
			var destX = 0
			t.interpolate_property(c,"rect_position:x",null,destX,.3,Tween.TRANS_CUBIC,Tween.EASE_OUT,.3+.1*i)
	t.start()

func OffCommand():
	t.remove_all()
	#var SCREEN_SIZE = get_viewport().get_visible_rect().size
	for i in range(1,get_child_count()):
		var c = get_child(i)
		t.interpolate_property(c,"position:x",null,100,.3,Tween.TRANS_CUBIC,Tween.EASE_IN)
	t.start()

func set_selection(sel:int, play_sound:bool=true):
	#print("wtf")
	keyboard_selection=sel
	
	#print("GainFocus: "+String(sel))
	var f:Control = self
	var count = f.get_child_count()
	for i in range(1,count):
		if keyboard_selection+1==i:
			f.get_child(i).GainFocus()
		else:
			f.get_child(i).LoseFocus()
	
	emit_signal("selection_changed",sel,get_child(sel+1).locked)



func input_accept(sel:int):
	#print("aaa")
	var n = get_child(sel+1)
	if n.locked:
		return
	elif n.submenu:
		emit_signal("switch_submenus",n.destinationScreenOrSubmenu)
	else:
		emit_signal("input_accepted",sel,n.destinationScreenOrSubmenu)
	pass
	
func input_cancel():
	if previous_submenu !="":
		emit_signal("switch_submenus",previous_submenu)

#input() is called by base screen
func input(event):
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	if Input.is_action_just_pressed("ui_down"):
		if keyboard_selection<get_child_count()-2:
			set_selection(keyboard_selection+1)
		else:
			set_selection(0)
		#print(keyboard_selection)
		#update_keyboard_selections()
	elif Input.is_action_just_pressed("ui_up"):
		if keyboard_selection<=0:
			set_selection(get_child_count()-2)
		else:
			set_selection(keyboard_selection-1)
		#update_keyboard_selections()
	elif Input.is_action_just_pressed("ui_select"):
		#update_keyboard_selections()
		input_accept(keyboard_selection)
	elif Input.is_action_just_pressed("ui_cancel"):
		input_cancel()
