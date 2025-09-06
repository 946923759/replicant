extends Node2D

func _on_ActorScroller_selection_changed(newSel, unlocked:bool=true, downloadable:bool=false, playSound:bool=true):
	#print(isLocked)
	for i in range(get_child_count()-3):
		var c:Sprite = get_child(i)
		c.visible=i==newSel
		if unlocked==false and i==newSel:
			c.self_modulate=Color.dimgray
		else:
			c.self_modulate=Color.white
	
	$Label.visible= (unlocked == false)
	if unlocked == false:
		
		if downloadable:
			$Label.text = "Confirm selection to download the .pck for this section"
		else:
			$Label.text = "This section is not available yet."
	
	if playSound:
		$AudioStreamPlayer2.play()
