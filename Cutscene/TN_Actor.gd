extends Control

onready var translationNote = $ColorRect

func _ready():
	translationNote.visible=false
	
func set_text(txt):
	$ColorRect/TranslationNote.text=txt

func _input(event):
	if !visible:
		return
	if event is InputEventJoypadButton or event is InputEventKey:
		translationNote.visible=Input.is_action_pressed("ui_shift")
		

func _on_Button_mouse_entered():
	if !visible:
		return
	else:
		translationNote.visible=true


func _on_Button_mouse_exited():
	if !visible:
		return
	else:
		translationNote.visible=false
