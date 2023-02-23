extends Node2D
signal clicked()
tool
"""
A ScrollItem is guarenteed to have three properties:
	String  text
	Vector2 size
	func    GainFocus()
	func    LoseFocus()
	
	signal  clicked()
	
	Anything else is left to be implemented by the programmer.
"""

export (String) var text = "OptionItem" setget set_text,get_text
export (bool) var locked = false
export (bool) var submenu = false
export (String) var destinationScreenOrSubmenu
export (Vector2) var size = Vector2(425,112)
#var textActor:Label
onready var t:Tween = $Tween


func _ready():
#	textActor.text=text
	$Sprite2.modulate.a=0
	
func set_text(s):
	text=s
	var n = get_node_or_null("Label")
	if n:
		n.text=text
func get_text():
	return text

func GainFocus():
	t.stop_all()
	t.interpolate_property($Sprite2,"modulate:a",null,1,.2)
	t.start()

func LoseFocus():
	t.stop_all()
	t.interpolate_property($Sprite2,"modulate:a",null,0,.2)
	t.start()


func _on_Label_gui_input(event):
	if (event is InputEventMouseButton and event.button_index==1 and event.pressed) or (event is InputEventScreenTouch and event.index==1):
		#print("A")
		emit_signal("clicked")
