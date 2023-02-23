extends "res://Screens/ScreenWithMenuElements.gd"

onready var scroller = $ActorScroller
func _input(event):
	scroller.input(event)

func _process(delta):
	var s = get_viewport().get_visible_rect().size
	$"Not an ActorScroller".position.x=s.x-670

func _on_ActorScroller_input_accepted(selection,destName):
	if destName!="":
		OffCommandNextScreen(destName)
