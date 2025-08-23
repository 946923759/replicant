extends Node2D

func _on_ActorScroller_selection_changed(newSel, isLocked:bool=false, playSound:bool=true):
	#print(isLocked)
	for i in range(get_child_count()-3):
		var c:Sprite = get_child(i)
		c.visible=i==newSel
		if isLocked and i==newSel:
			c.self_modulate=Color.dimgray
	$Label.visible=isLocked
	
	if playSound:
		$AudioStreamPlayer2.play()
