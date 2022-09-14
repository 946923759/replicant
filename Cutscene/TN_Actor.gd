extends Control

func _ready():
	$TranslationNote.visible=false

func _input(event):
	if !visible:
		return
	if event is InputEventJoypadButton or event is InputEventKey:
		$TranslationNote.visible=Input.is_action_pressed("ui_shift")
		

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
