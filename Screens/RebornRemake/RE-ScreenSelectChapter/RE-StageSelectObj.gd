tool
extends Control

export(Texture) var icon setget set_icon
export(String) var label setget set_label

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
