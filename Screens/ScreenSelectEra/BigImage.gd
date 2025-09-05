extends Node2D

func _on_ActorScroller_selection_changed(newSel, unlocked:bool=true, playSound:bool=true):
	#print(isLocked)
	for i in range(get_child_count()-3):
		var c:Sprite = get_child(i)
		c.visible=i==newSel
		if unlocked==false and i==newSel:
			c.self_modulate=Color.dimgray
		else:
			c.self_modulate=Color.white
	$Label.visible=!unlocked
	
	if playSound:
		$AudioStreamPlayer2.play()
