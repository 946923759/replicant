extends Control
signal clicked()

onready var icon:TextureRect = $GalleryIcon
onready var text:Label=$UnlockedCount
onready var lockedIcon:TextureRect = $Locked

var unlockedCount:int=0
var unlockedEntries:Array

func _on_GalleryIcon_mouse_entered():
	icon.use_parent_material=true
	pass # Replace with function body.


func _on_GalleryIcon_mouse_exited():
	#If device has a touchscreen, always keep it colored
	icon.use_parent_material=OS.has_touchscreen_ui_hint()

func _ready():
	icon.use_parent_material=OS.has_touchscreen_ui_hint()

#It helps to read the documentation, doesn't it?
#This returns the event position relative to the control that was clicked
#So you just have to check if it's still within the control
func _is_within_button(event_position : Vector2) -> bool:
	return event_position.x >= 0 and event_position.y >= 0 and \
		event_position.x < rect_size.x and event_position.y < rect_size.y
#	print(event_position.x)
#	print(rect_position.x+get_parent().rect_position.x)
#	print(rect_position.x)
#	return event_position.x >= rect_global_position.x and event_position.x <= rect_global_position.x + rect_size.x and \
#			event_position.y >= rect_global_position.y and event_position.y <= rect_global_position.y + rect_size.y


#func is_desktop():
#	match OS.get_name():
#		"Windows","X11","macOS":
#			return true
#	return false

func onClickWrapper(event:InputEvent):
	if unlockedCount > 0:
		if event is InputEventMouseButton and event.button_index == 1:
			if OS.has_touchscreen_ui_hint():
				#If button released and still within the box
				if !event.pressed and _is_within_button(event.position):
					emit_signal("clicked")
			else:
				if event.pressed:
					emit_signal("clicked")

func setUnlockedCount(count:int,length:int,entries):
	if length>1:
		text.text=String(String(count)+"/"+String(length))
	else:
		text.visible=false
		
	unlockedEntries=entries
		
	unlockedCount=count
	if count<1:
		lockedIcon.visible=true
		icon.modulate=Color.black

func debugUnlock():
	unlockedCount=len(unlockedEntries)
	lockedIcon.visible=false
	icon.modulate=Color.white
