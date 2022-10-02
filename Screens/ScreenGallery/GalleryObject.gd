extends Control

onready var icon:TextureRect = $GalleryIcon
onready var text:Label=$UnlockedCount
onready var lockedIcon:TextureRect = $Locked

var unlockedCount:int=0
var unlockedEntries:Array

func _on_GalleryIcon_mouse_entered():
	icon.use_parent_material=true
	pass # Replace with function body.


func _on_GalleryIcon_mouse_exited():
	icon.use_parent_material=false
	pass # Replace with function body.

func setUnlockedCount(count:int,length:int,entries):
	if length>1:
		text.text=String(String(count)+"/"+String(length))
	else:
		text.visible=false
		
	unlockedEntries=entries
		
	unlockedCount=count
	if count<1:
		lockedIcon.visible=true
		icon.modulate=Color.black
