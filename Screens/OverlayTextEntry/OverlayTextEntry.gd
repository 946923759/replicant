extends "res://Screens/ScreenWithMenuElements.gd"

export var allow_empty_text:bool = false

var randNames = [
	"Kiana","Mei","Bronya","Seele","Sin","Kyuushou","Himeko","Theresa"
]

onready var labelPrompt:Label = $VBoxContainer/LabelPromptText
onready var textInput:LineEdit = $VBoxContainer/TextEdit
onready var buttonRandom:Button = $VBoxContainer/HBoxContainer/Button
onready var buttonOK:Button = $VBoxContainer/HBoxContainer/ButtonOK

func _ready():
	
	if INITrans.HasString(self.name,"PromptText"):
		var nameEntry = INITrans.GetString(self.name, "PromptText")
		labelPrompt.text = nameEntry
		
	OnCommand()
	
	if allow_empty_text == false:
		buttonOK.disabled = len(textInput.text) == 0
	textInput.grab_focus()
	textInput.caret_position=99

func _input(event):
	if Input.is_action_just_pressed("ui_select") or \
	Input.is_action_just_pressed("ui_pause"):
		if buttonRandom.has_focus():
			buttonRandom.pressed = true
			buttonRandom.emit_signal("pressed")

#Overwrite this command if you want to inherit this screen
func OnCommand():
	var username:String = ""
	if OS.has_environment("USERNAME"):
		username = OS.get_environment("USERNAME")
	elif OS.has_environment("USER"):
		username = OS.get_environment("USER")
	#Uppercase the first letter
	username = username.capitalize()
	
	textInput.text = username

func _on_TextEdit_text_changed(new_text):
	
	if allow_empty_text == false:
		buttonOK.disabled = len(new_text.strip_edges()) == 0


func _on_Button_pressed():
	textInput.text = randNames[randi()%len(randNames)]
	pass # Replace with function body.

func _on_ButtonOK_pressed():
	Globals.playerData['vars']['name'] = textInput.text.strip_edges()
	OffCommandOverlay()
