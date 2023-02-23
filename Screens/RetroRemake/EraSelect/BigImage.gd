extends Node2D

var firstRun:bool=true

func _on_ActorScroller_selection_changed(newSel):
	for i in range(get_child_count()-2):
		var c = get_child(i)
		c.visible=i==newSel
	
	if firstRun:
		firstRun=false
	else:
		$AudioStreamPlayer2.play()
