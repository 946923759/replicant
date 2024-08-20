extends Node2D

var firstRun:bool=true

func _on_ActorScroller_selection_changed(newSel, isLocked:bool=false):
	#print(isLocked)
	for i in range(get_child_count()-3):
		var c:Sprite = get_child(i)
		c.visible=i==newSel
		if isLocked and i==newSel:
			c.self_modulate=Color.dimgray
	$Label.visible=isLocked
	
	if firstRun:
		firstRun=false
	else:
		$AudioStreamPlayer2.play()
