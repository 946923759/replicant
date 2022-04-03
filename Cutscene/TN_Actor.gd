extends Control

func _ready():
	$TranslationNote.visible=false

func _on_Button_mouse_entered():
	if !visible:
		return
	else:
		$TranslationNote.visible=true


func _on_Button_mouse_exited():
	if !visible:
		return
	else:
		$TranslationNote.visible=false
