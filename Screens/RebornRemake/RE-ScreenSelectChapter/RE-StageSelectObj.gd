tool
extends Control

export(Texture) var icon setget set_icon
export(String) var label setget set_label
export(bool) var completed=false setget set_complete

#onready var 

func set_icon(t:Texture):
	var a = get_node_or_null("Icon")
	if a and t:
		a.texture=t
	icon=t
		
func set_label(s:String):
	var a = get_node_or_null("Label")
	if a:
		a.text=s
	label=s

func set_complete(b:bool):
	var obj_a = get_node_or_null("Border_Incomplete")
	var obj_b = get_node_or_null("Border_Complete")
	if obj_a and obj_b:
		obj_a.visible = !b
		obj_b.visible = b
	completed=b
