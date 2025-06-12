tool
extends Control
signal clicked()

export (String) var text = "Part Name Here" setget set_text,get_text

onready var t:Tween = $Tween

func _ready():
	$TextureRect.self_modulate.a = 0.0

func set_text(s):
	text=s
	var n = get_node_or_null("Label")
	if n:
		n.text=text
func get_text():
	return text

func GainFocus():
	#print("GainFocus!")
	t.stop_all()
	t.interpolate_property($TextureRect,"self_modulate:a",null,1,.2)
	t.start()

func LoseFocus():
	t.stop_all()
	t.interpolate_property($TextureRect,"self_modulate:a",null,0,.2)
	t.start()

func _on_gui_input(event):
	if (event is InputEventMouseButton and event.button_index==1 and event.pressed) or (event is InputEventScreenTouch and event.index==1):
		#print("Clicked "+text)
		emit_signal("clicked")


func _on_TextureRect2_mouse_entered():
	emit_signal("mouse_entered")
